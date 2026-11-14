/*
 * Counts quick back-and-forth twists of the ball (a wiggle), for the Bluetooth
 * profile gestures in ball_fusion.c. Plain C, no Zephyr, so it can be tested
 * on a host.
 *
 * A stroke is a run of twist in one direction that adds up to at least
 * `stroke` counts; each run counts once, however long it goes on (scrolling
 * one way is one stroke). A stroke that comes more than `gap_ms` after the
 * last one starts the count again.
 *
 * SPDX-License-Identifier: MIT
 */

#pragma once

#include <math.h>
#include <stdbool.h>
#include <stdint.h>

struct twist_gesture {
	float acc;       /* twist in the current run so far */
	int8_t dir;      /* the current run's direction: 1, -1, or 0 for none */
	bool counted;    /* the current run has been counted as a stroke */
	uint8_t strokes; /* strokes in this wiggle */
	int64_t last_ms; /* when the last stroke was counted */
};

/* one report's twist, at now_ms; true if it completed a stroke */
static inline bool twist_gesture_feed(struct twist_gesture *g, float twist, float stroke,
				      int64_t gap_ms, int64_t now_ms)
{
	int8_t s = twist > 0.0f ? 1 : (twist < 0.0f ? -1 : 0);

	if (s == 0) {
		return false;
	}
	if (s != g->dir) {
		/* a new run: too long after the last stroke, it starts the count
		 * again (a run that just goes on doesn't) */
		if (g->strokes > 0 && now_ms - g->last_ms > gap_ms) {
			g->strokes = 0;
		}
		g->dir = s;
		g->acc = 0.0f;
		g->counted = false;
	}
	g->acc += fabsf(twist);
	if (!g->counted && g->acc >= stroke) {
		g->counted = true;
		if (g->strokes < UINT8_MAX) {
			g->strokes++;
		}
		g->last_ms = now_ms;
		return true;
	}
	return false;
}

/* the wiggle's strokes, if it's over (no stroke for gap_ms), and start again;
 * 0 while it's still going */
static inline uint8_t twist_gesture_take(struct twist_gesture *g, int64_t gap_ms, int64_t now_ms)
{
	if (g->strokes == 0 || now_ms - g->last_ms < gap_ms) {
		return 0;
	}

	uint8_t n = g->strokes;

	g->strokes = 0;
	g->dir = 0;
	g->acc = 0.0f;
	g->counted = false;
	return n;
}
