/*
 * Combines the Rollino's two ball sensors into pointer motion and twist
 * scrolling.
 *
 * A sensor at unit direction n (from the ball's centre) sees the surface move
 * at v = w x Rn, and reports it along its axes e1, e2: e.v = (n x e).(Rw).
 * Two sensors give four such readings for the three components of the ball's
 * rotation w, solved by least squares: Rw = (A^T A)^-1 A^T m, with A's rows
 * n x e. Under the finger, on top of the ball, the surface moves at
 * w x Rz = (Rw_y, -Rw_x, 0): that is the pointer motion; Rw_z is the twist.
 *
 * SPDX-License-Identifier: MIT
 */

#define DT_DRV_COMPAT rollino_ball_fusion

#include <math.h>
#include <string.h>

#include <zephyr/device.h>
#include <zephyr/input/input.h>
#include <zephyr/kernel.h>
#include <zephyr/logging/log.h>
#include <zephyr/spinlock.h>
#include <zephyr/sys/util.h>

LOG_MODULE_REGISTER(ball_fusion, CONFIG_INPUT_LOG_LEVEL);

#define NUM_SENSORS 2
#define PI_F 3.14159265f

struct ball_fusion_sensor_config {
	int32_t azimuth;   /* millidegrees */
	int32_t elevation; /* millidegrees */
	int32_t rotation;  /* degrees */
};

struct ball_fusion_config {
	const struct ball_fusion_sensor_config *sensors;
	int32_t pointer_scale;
	int32_t scroll_divisor;
	int32_t twist_ratio;
	int32_t period_ms;
	bool invert_scroll;
};

struct ball_fusion_data {
	const struct device *dev;
	struct k_spinlock lock;
	/* sensor deltas not combined yet: [sensor][x, y] */
	int32_t pending[NUM_SENSORS][2];
	/* sensor readings -> [pointer x, pointer y (down), twist] */
	float m[3][2 * NUM_SENSORS];
	/* fractions of a count not reported yet */
	float rem[3];
	struct k_work_delayable work;
};

/* what a sensor's input callback needs: the fusion device and which sensor */
struct ball_fusion_ref {
	const struct device *dev;
	uint8_t idx;
};

static void cross(const float a[3], const float b[3], float out[3])
{
	out[0] = a[1] * b[2] - a[2] * b[1];
	out[1] = a[2] * b[0] - a[0] * b[2];
	out[2] = a[0] * b[1] - a[1] * b[0];
}

static void ball_fusion_input_cb(struct input_event *evt, void *user_data)
{
	const struct ball_fusion_ref *ref = user_data;
	struct ball_fusion_data *data = ref->dev->data;
	const struct ball_fusion_config *cfg = ref->dev->config;

	if (evt->type != INPUT_EV_REL) {
		return;
	}

	K_SPINLOCK(&data->lock) {
		if (evt->code == INPUT_REL_X) {
			data->pending[ref->idx][0] += evt->value;
		} else if (evt->code == INPUT_REL_Y) {
			data->pending[ref->idx][1] += evt->value;
		}
	}

	/* no-op if already scheduled: both sensors' motion within a period is
	 * combined together */
	if (evt->sync) {
		k_work_schedule(&data->work, K_MSEC(cfg->period_ms));
	}
}

static void ball_fusion_work_handler(struct k_work *work)
{
	struct k_work_delayable *dwork = k_work_delayable_from_work(work);
	struct ball_fusion_data *data = CONTAINER_OF(dwork, struct ball_fusion_data, work);
	const struct device *dev = data->dev;
	const struct ball_fusion_config *cfg = dev->config;
	int32_t reading[2 * NUM_SENSORS];
	float out[3];

	K_SPINLOCK(&data->lock) {
		memcpy(reading, data->pending, sizeof(reading));
		memset(data->pending, 0, sizeof(data->pending));
	}

	for (int k = 0; k < 3; k++) {
		out[k] = 0.0f;
		for (int j = 0; j < 2 * NUM_SENSORS; j++) {
			out[k] += data->m[k][j] * (float)reading[j];
		}
	}

	float rolling = sqrtf(out[0] * out[0] + out[1] * out[1]);
	float twist = fabsf(out[2]);

	if (twist * 100.0f > (float)cfg->twist_ratio * rolling) {
		data->rem[2] += out[2] / (float)cfg->scroll_divisor * (cfg->invert_scroll ? -1.0f : 1.0f);
	} else {
		data->rem[0] += out[0] * (float)cfg->pointer_scale / 100.0f;
		data->rem[1] += out[1] * (float)cfg->pointer_scale / 100.0f;
	}

	int32_t dx = (int32_t)data->rem[0];
	int32_t dy = (int32_t)data->rem[1];
	int32_t wheel = (int32_t)data->rem[2];

	data->rem[0] -= (float)dx;
	data->rem[1] -= (float)dy;
	data->rem[2] -= (float)wheel;

	if (dx != 0) {
		input_report_rel(dev, INPUT_REL_X, dx, dy == 0 && wheel == 0, K_FOREVER);
	}
	if (dy != 0) {
		input_report_rel(dev, INPUT_REL_Y, dy, wheel == 0, K_FOREVER);
	}
	if (wheel != 0) {
		input_report_rel(dev, INPUT_REL_WHEEL, wheel, true, K_FOREVER);
	}
}

static int ball_fusion_init(const struct device *dev)
{
	const struct ball_fusion_config *cfg = dev->config;
	struct ball_fusion_data *data = dev->data;
	float a_rows[2 * NUM_SENSORS][3];

	data->dev = dev;
	k_work_init_delayable(&data->work, ball_fusion_work_handler);

	for (int i = 0; i < NUM_SENSORS; i++) {
		const struct ball_fusion_sensor_config *s = &cfg->sensors[i];
		float az = (float)s->azimuth * PI_F / 180000.0f;
		float el = (float)s->elevation * PI_F / 180000.0f;
		float rot = (float)s->rotation * PI_F / 180.0f;
		/* outward normal, down-slope and sideways tangents (as the case's
		 * at_ball() frame: z, x, y) */
		float n[3] = {cosf(el) * sinf(az), -cosf(el) * cosf(az), sinf(el)};
		float down[3] = {sinf(el) * sinf(az), -sinf(el) * cosf(az), -cosf(el)};
		float side[3] = {cosf(az), sinf(az), 0.0f};
		float e1[3], e2[3];

		for (int k = 0; k < 3; k++) {
			e1[k] = cosf(rot) * down[k] + sinf(rot) * side[k];
			e2[k] = -sinf(rot) * down[k] + cosf(rot) * side[k];
		}
		cross(n, e1, a_rows[2 * i]);
		cross(n, e2, a_rows[2 * i + 1]);
	}

	/* N = A^T A, and its inverse */
	float nm[3][3];

	for (int r = 0; r < 3; r++) {
		for (int c = 0; c < 3; c++) {
			nm[r][c] = 0.0f;
			for (int j = 0; j < 2 * NUM_SENSORS; j++) {
				nm[r][c] += a_rows[j][r] * a_rows[j][c];
			}
		}
	}

	float det = nm[0][0] * (nm[1][1] * nm[2][2] - nm[1][2] * nm[2][1]) -
		    nm[0][1] * (nm[1][0] * nm[2][2] - nm[1][2] * nm[2][0]) +
		    nm[0][2] * (nm[1][0] * nm[2][1] - nm[1][1] * nm[2][0]);

	if (fabsf(det) < 1e-4f) {
		LOG_ERR("sensor directions can't see the ball's whole rotation (det %d e-6)",
			(int)(det * 1e6f));
		return -EINVAL;
	}

	float inv[3][3];

	for (int r = 0; r < 3; r++) {
		for (int c = 0; c < 3; c++) {
			/* cofactor of (c, r), divided by det */
			int r1 = (c + 1) % 3, r2 = (c + 2) % 3;
			int c1 = (r + 1) % 3, c2 = (r + 2) % 3;

			inv[r][c] = (nm[r1][c1] * nm[r2][c2] - nm[r1][c2] * nm[r2][c1]) / det;
		}
	}

	/* P = N^-1 A^T: readings -> R w; then pointer x = Rw_y, pointer y (down)
	 * = Rw_x, twist = Rw_z */
	static const int out_row[3] = {1, 0, 2};

	for (int k = 0; k < 3; k++) {
		for (int j = 0; j < 2 * NUM_SENSORS; j++) {
			float p = 0.0f;

			for (int l = 0; l < 3; l++) {
				p += inv[out_row[k]][l] * a_rows[j][l];
			}
			data->m[k][j] = p;
		}
		LOG_INF("%s: %d %d %d %d (x1000)", k == 0 ? "x" : (k == 1 ? "y" : "twist"),
			(int)(data->m[k][0] * 1000), (int)(data->m[k][1] * 1000),
			(int)(data->m[k][2] * 1000), (int)(data->m[k][3] * 1000));
	}

	return 0;
}

#define BALL_FUSION_SENSOR_CONFIG(node)                                                     \
	{                                                                                  \
		.azimuth = DT_PROP(node, azimuth),                                         \
		.elevation = DT_PROP(node, elevation),                                     \
		.rotation = DT_PROP(node, rotation),                                       \
	},

#define BALL_FUSION_REF(node, n) {.dev = DEVICE_DT_INST_GET(n), .idx = DT_NODE_CHILD_IDX(node)},

/* the extra level lets the name argument expand before it's pasted */
#define BALL_FUSION_CALLBACK_NAMED(dev, user_data, name)                                    \
	INPUT_CALLBACK_DEFINE_NAMED(dev, ball_fusion_input_cb, user_data, name);

#define BALL_FUSION_CALLBACK(node, n)                                                       \
	BALL_FUSION_CALLBACK_NAMED(DEVICE_DT_GET(DT_PHANDLE(node, device)),                \
				   (void *)&ball_fusion_refs_##n[DT_NODE_CHILD_IDX(node)],  \
				   UTIL_CAT(ball_fusion_cb_, DT_DEP_ORD(node)))

#define BALL_FUSION_INIT(n)                                                                 \
	BUILD_ASSERT(DT_CHILD_NUM(DT_DRV_INST(n)) == NUM_SENSORS,                          \
		     "rollino,ball-fusion needs exactly two sensors");                     \
                                                                                            \
	static const struct ball_fusion_sensor_config ball_fusion_sensors_##n[] = {        \
		DT_INST_FOREACH_CHILD(n, BALL_FUSION_SENSOR_CONFIG)};                      \
                                                                                            \
	static const struct ball_fusion_config ball_fusion_config_##n = {                  \
		.sensors = ball_fusion_sensors_##n,                                        \
		.pointer_scale = DT_INST_PROP(n, pointer_scale),                           \
		.scroll_divisor = DT_INST_PROP(n, scroll_divisor),                         \
		.twist_ratio = DT_INST_PROP(n, twist_ratio),                               \
		.period_ms = DT_INST_PROP(n, period_ms),                                   \
		.invert_scroll = DT_INST_PROP(n, invert_scroll),                           \
	};                                                                                 \
                                                                                            \
	static struct ball_fusion_data ball_fusion_data_##n;                               \
                                                                                            \
	DEVICE_DT_INST_DEFINE(n, ball_fusion_init, NULL, &ball_fusion_data_##n,            \
			      &ball_fusion_config_##n, POST_KERNEL,                         \
			      CONFIG_INPUT_INIT_PRIORITY, NULL);                            \
                                                                                            \
	static const struct ball_fusion_ref ball_fusion_refs_##n[] = {                     \
		DT_INST_FOREACH_CHILD_VARGS(n, BALL_FUSION_REF, n)};                       \
                                                                                            \
	DT_INST_FOREACH_CHILD_VARGS(n, BALL_FUSION_CALLBACK, n)

DT_INST_FOREACH_STATUS_OKAY(BALL_FUSION_INIT)
