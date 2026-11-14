// Rollino - low-profile finger trackball
//
// Ball floats `ball_gap` above the table on three ceramic support balls.
// Two PMW3610 sensors sit in pods at the back-left/back-right, looking up at
// the ball from as low as they fit; their azimuths are chosen so the lines of sight are
// ~90 deg apart, so X, Y and twist are all observable. The sensor boards lie
// on their sides (the chip's long axis horizontal, its connector end towards
// the front), which keeps the pods low.
// A XIAO nRF52840 lies flat in a low, flat pod that swells out of the rim at the front,
// USB-C pointing forward. It is soldered to a base PCB that sits in a groove
// in the case's underside and reaches a little way round each side, where an
// FPC ribbon comes in from the sensor board. The LiPo is at the back, well
// away from the XIAO's
// antenna; its leads run round in a groove in the underside. The sensor
// pods and the battery share one ring round the back half of the ball: the
// LiPo stands in it between the two sensors, leaning against the ball at
// the sensor boards' tilt. A cover (a separate part) closes the whole
// underside, the battery's pocket included, and each sensor board has a
// cover of its own on the ball's side, with a window for the lens.
//
// Coordinates: table is z=0, front (towards the user) is -y.
// Azimuths are measured from the front, positive towards +x.

/* [View] */
// assembly | exploded | section | hardware | body | base_cover |
// sensor_cover (print two) |
// base_pcb / sensor_pcb (2D board outlines, for ../pcb/gen/generate.py) |
// fpc_check / wall_check / usb_check (all should come out empty)
part = "assembly";
// azimuth of the vertical cut plane for part="section"
section_az = 135;
// part="exploded" draws only this piece of it, if set (body, ball,
// supports, sensor_boards, sensor_covers, sensor_screws, electronics,
// base_pcb, cover, screws, or the battery's pouch, pcm and leads): ../case/render_exploded.sh renders it in
// Blender a piece at a time, with KiCad's models of the boards
explode_only = "";
// how far apart part="exploded" pulls the pieces (0: assembled)
explode_d = 25;

/* [Ball] */
ball_d = 55;
// ball bottom above table
ball_gap = 1;
// radial gap between ball and case
ball_clear = 1;

/* [Ball supports] */
// ZrO2 / Si3N4 bearing balls
support_d = 3;
// angle from the ball's bottom pole
support_polar = 45;
// kept clear of the front pod, which covers azimuth 0 low down
support_az = [180, 60, -60];

/* [Rim] */
rim_h = 11;
// rim outer radius = ball radius + rim_wall
rim_wall = 7;
bottom_hole_r = 10;
wall = 1.6;

/* [Organic shaping] */
// corner radius of the sensor PCBs
pcb_r = 4.5;
// rounding of the rim patches that blend a pod into the rim
shell_r = 4;
// rounding of the ring round the back of the ball, which holds the sensor
// boards and the battery
pod_r = 6;
// how far round (degrees) each end of that ring takes to melt into the rim
ring_taper = 42;

/* [Sensors: PMW3610 + LM18-LSI] */
// true: put the sensors as low as floor_z allows
sensor_el_auto = true;
// elevation above the ball's equator (if not auto)
sensor_el = -23;
// true: choose azimuths that make the two lines of sight orthogonal
sensor_az_auto = true;
sensor_az = [130, -130];
// The board lies on its side: its x (the chip's long axis) is horizontal,
// pointing towards the back, and its y runs up/down the slope. The same
// board serves both sensors, one turned half a turn from the other, so
// nothing may stick out of one long side only.
// package centre sits this far (towards the front) from the optical axis (datasheet fig. 5: 7.09 - 3.18)
sensor_optical_offset = 3.9;
// datasheet: lens reference plane to surface, 2.4 +-0.2
lens_ref_z = 2.4;
// ASSUMED (same stack as PixArt LM19 designs) - verify against LM18 drawing
pcb_top_z = 7.4;
pcb_t = 1.6;
// along the chip (horizontal)
pcb_w = 22;
// across it (up/down the slope)
pcb_h = 20;
lens_w = 20;
lens_h = 17;
// chip + components above the sensor PCB
parts_h = 3;
// the PCB goes in from the ball side and two M2 self-tapping (plastite)
// screws, one either side of the lens, hold it against the back of its
// pocket; pilot hole diameter
pcb_screw_d = 1.8;
// pilot hole depth behind the PCB's back face
pcb_screw_depth = 5.5;
// A printed cover fills the board's pocket on the ball's side, flush with
// the ball's cup, and keeps dust off the board; the same two screws (pan
// head, M2 x 10) go through it. Gap to the pocket's wall all round
cover_gap = 0.15;
// what the screw heads sit on (the rest of the cover's thickness is
// counterbored); also where the cover's skin over the lens ends, so the
// counterbores stay closed
cover_seat = pcb_top_z - pcb_t - lens_ref_z + 0.1;
// counterbore for the screw heads (pan head, up to 3.8)
cover_head_d = 4.2;
// the lens's window in the cover, a slot along the chip: [from, to (centres,
// from the optical axis), radius]. ASSUMED: wide enough for the laser's
// spot and the lens's view; check against the LM18-LSI drawing
cover_window = [-6, 3, 3];
// one screw is in an ear on the board's back end, on its centre line, this
// far beyond the edge
pcb_ear_d = 5;
pcb_ear_x = 2.5;
// the other is beside the FPC connector: [from the chip's centre, from the
// board's centre line]
pcb_hole2 = [-12.1, -7.3];
// FPC connector, 6-pin 0.5 mm (Hirose FH12-6S-0.5SH, or a clone such as
// JUSHUO AFC01-S06FCA): [length, depth with its solder tails, height]. It
// sits on the sensor board's back beyond the chip's front end, mouth
// facing off the board's front edge, where the ribbon (6 x 0.5 mm FFC,
// fpc_w wide) is easy to push in and latch before the board goes in; it
// then bends back over the connector and the chip, is folded there (a 45
// degree crease, flat) to run down the slope over the chip's back, past the
// board's low edge and in under it to the base PCB
fpc_conn = [8.1, 7.1, 2.1];
fpc_w = 3.5;
// room past the board's front edge for the ribbon's U-turn
fpc_bend = 2.6;
// where along the chip (from its centre) the ribbon is folded to run down
fpc_fold = -5;
// the ribbon's channel down to the base PCB, roomy enough to feed its end
// through from either end before the boards go in: [width, depth over the
// chip]; the case checks the room with a ribbon this much thicker (and
// 1 mm wider) than it is: part="fpc_check" must come out empty
fpc_chan = [fpc_w + 2, 1.6];
fpc_clear = 1.5;
// the sensor board reaches this much further towards the front than the
// symmetric pcb_w, for that connector
pcb_ext = max(0, (16.2 + 0.6) / 2 + 1 + fpc_conn.y - pcb_w / 2);

/* [Battery] */
// LiPo cell 602020 (~200 mAh): [length, width, thickness]
// sizes vary between makers; this is the larger end (22 x 19.5 x 6.5 is
// listed), length including the protection board folded over one end. It
// stands in the ring at the back, between the sensors, leaning against the
// ball at their tilt, protection board down; it slides up into its pocket
// from below before the cover goes on, and stands on the cover
batt = [22, 20, 6.5];
// length of that protection-board end (kapton-taped), on the side the leads leave
batt_pcm = 2.5;
// the pocket's inner face, from the ball's surface (clear of the rear
// support ball and of the sensor boards' ears)
batt_z0 = 5;
// which side (1: right, -1: left) the leads run round to the XIAO, in a
// groove in the case's underside inside the base PCB's band: [radius,
// width, height]; they come up behind that corner of the XIAO's cavity.
// Pick the side away from the XIAO's chip antenna
batt_wire_side = 1;
batt_wire = [21, 2.6, 1.5];

/* [Electronics pod] */
// Seeed XIAO nRF52840 (not Sense): [length, width, PCB thickness]; sizes
// below are from Seeed's 3D model (../pcb/3d/xiao-nrf52840.stl, converted
// from the Sense STEP at https://files.seeedstudio.com/wiki/XIAO-BLE/seeed-studio-xiao-nrf52840-3d-model.zip;
// same board, plus an IMU and a mic)
xiao = [21, 17.8, 1];
// height of the USB-C receptacle (the tallest part, 3.2) on the XIAO's
// component side, and how far it overhangs the board edge
xiao_parts_h = 3.3;
usb_overhang = 1.55;
// the XIAO's reset button, on its component side (so facing down, into the
// cover): [from the board edge at the USB end, from the centre line] in
// Seeed's model; the cover has a hole under it this wide, for a paper clip
// (two taps for the bootloader)
xiao_reset = [1.87, -5.72];
reset_hole_d = 2.2;
// pads on the XIAO's underside (which faces up), and the room over them
// for the battery's leads, soldered to the battery pads
xiao_pads = 0.25;
xiao_wire_room = 1.5;
// cavity: the XIAO is soldered upside down onto the base PCB by its
// castellated edges, its parts (USB-C included) hanging down through a
// cutout in the PCB into a pocket in the cover; x runs from the USB end
// towards the ball
elec_size = [xiao.x + usb_overhang + 0.6, xiao.y + 0.6, xiao.z + xiao_pads + xiao_wire_room];
// the base PCB keeps a strip this wide between the XIAO's far end and the
// ball's hole, for the tracks that cross from one side to the other
xiao_strip = 3.2;
// the PCB cutout under the XIAO leaves its castellated pads this much to sit on
xiao_pad_w = 1.5;
// the pod's outline is a circle this wide (seen from above), swelling out
// of the rim; it is this high, flat on top, its edge rounded this much
elec_dome_d = 46;
elec_pod_h = 12;
elec_pod_r = 4;
// radius of the fillets (seen from above) where the pod's outline meets the rim's
front_fillet = 30;
// how far the dome's centre sits behind the cavity's, towards the ball, so
// less of it sticks out in front (the cavity itself stays put)
elec_dome_back = 3.5;
// base PCB screws either side of the cavity, from its centre line
elec_screw_y = xiao.y / 2 + 4.8;
// plug overmold recess in front of the receptacle: [width, height]
usb_plug = [13.5, 7.5];
// the biggest plug the USB-C spec allows: overmold [width, height, length
// (typical)]; part="usb_check" tries it against the case, and the echo says
// how far it stays above the table
usb_overmold = [12.35, 6.5, 30];
// the receptacle's axis below the base PCB's top (it hangs under the XIAO)
usb_axis = 1.6;
// lowest point of any pod above the table
floor_z = 0;

/* [Base PCB + cover] */
// the cover is the bottom slab of the case, screwed on; the PCB lies on it,
// in a groove in the case above, and countersunk M2 screws go up through
// both into the case. The upside-down XIAO's USB-C is centred on the cover's
// top, so this is what lifts a plug (overmold up to ~6.5 tall) off the table
base_cover_t = 3.6;
base_pcb_t = 1.6;
// band round the ball's bottom hole, from under the front pod a little way
// round each side: [inner, outer] radius; inside it the ball's cup and the
// support balls' holes come down close, outside it the rim's foot is rounded
base_band_r = [24, 32.5];
// the ribbons are stock fpc_len FFCs (40 mm ones are hard to get): each
// comes down past its sensor board's low edge, turns in under it, lying on
// the cover, and with a crease turns to run straight along a channel in the
// case's underside (the cover holds it) into an FPC connector that faces
// it at the end of the band; the band ends there, its length set by what
// the ribbon needs, less fpc_slack for leeway. Pocket over the connector
// (the ribbon goes in before the board goes up into the case, so it only
// needs room for the closed connector): [beyond the mouth, height]
fpc_len = 50;
fpc_slack = 1.5;
fpc_pocket = [0.5, fpc_conn.z + 0.8];
// extra screws on the band: [azimuth, radius] (plus two under the front
// pod), and the pilot holes' depth above the PCB (the rim is only rim_h tall)
base_screws_polar = [[47, 27.5], [-47, 27.5]];
base_screw_depth = 4.5;
// and two through the cover only, either side of the battery
cover_screws_polar = [[150, 30], [-150, 30]];

$fn = 256;

R = ball_d / 2;
zc = ball_gap + R;
eps = 0.01;

// ---------- frames ----------

// Local frame on the ball surface: z = outward normal (0 at ball surface),
// y = horizontal tangent, x = tangent pointing down the slope.
module at_ball(az, el) {
  translate([0, 0, zc]) rotate([0, 0, az - 90]) rotate([0, 90 - el, 0])
    translate([0, 0, R]) children();
}

function at_ball_pt(az, el, p) =
  let(a = 90 - el, phi = az - 90, q = p + [0, 0, R],
      r1 = [q.x * cos(a) + q.z * sin(a), q.y, -q.x * sin(a) + q.z * cos(a)])
  [r1.x * cos(phi) - r1.y * sin(phi), r1.x * sin(phi) + r1.y * cos(phi), r1.z + zc];

function polar_pt(az, r, z) = [r * sin(az), -r * cos(az), z];

// Lowest elevation at which a set of [x, z] / [x, z, r] / [x, z, ax, az]
// points in the at_ball frame stays above height floor: a plain point, the
// centre of a ball of radius r, or the centre of an ellipse with semi-axes ax
// (in the x / cos(e) direction) and az (in the z / sin(e) direction).
function lowest_el(pts, floor = floor_z) =
  min([for (e = [-80 : 0.5 : 60])
         if (min([for (p = pts)
           let(ax = len(p) > 3 ? p[2] : (len(p) > 2 ? p[2] : 0),
               az = len(p) > 3 ? p[3] : (len(p) > 2 ? p[2] : 0))
           zc + (R + p[1]) * sin(e) - p[0] * cos(e)
             - sqrt(pow(ax * cos(e), 2) + pow(az * sin(e), 2))]) >= floor) e]);

function seg_dist(p, a, b) =
  let(d = b - a, t = max(0, min(1, (p - a) * d / (d * d)))) norm(a + t * d - p);

// ---------- rounded primitives ----------

// 2D rounded rectangle, centred on the origin
module rrect(size, r) {
  offset(r = r) offset(delta = -r) square(size, center = true);
}

// box centred on the origin with every edge rounded, as the hull of 8 balls
module rbox(size, r) {
  rr = min(r, size.x / 2 - eps, size.y / 2 - eps, size.z / 2 - eps);
  hull() for (sx = [-1, 1], sy = [-1, 1], sz = [-1, 1])
    translate([sx * (size.x / 2 - rr), sy * (size.y / 2 - rr), sz * (size.z / 2 - rr)])
      sphere(r = rr, $fn = 32);
}

// ellipsoid centred on the origin with semi-axes r = [rx, ry, rz]
module ellipsoid(r) { scale(r) sphere(r = 1, $fn = 48); }

// Electronics pod frame: z=0 is the cavity floor (the base PCB's top), x
// runs from the USB end towards the ball, y across; the cavity is slid in
// until its top back edge is a wall away from the ball clearance, or the
// XIAO's far end is xiao_strip from the base PCB's inner edge
elec_floor = base_cover_t + base_pcb_t;
base_top = floor_z + elec_floor;
elec_top = base_top + elec_size.z;
elec_back = -max(sqrt(pow(R + ball_clear + wall, 2) - pow(max(0, zc - elec_top), 2)),
                 base_band_r[0] + xiao_strip - (elec_size.x - 0.3 - usb_overhang - xiao.x));
elec_m = [[0, -1, 0, elec_size.y / 2],
          [1, 0, 0, elec_back - elec_size.x],
          [0, 0, 1, base_top]];

module at_elec() { multmatrix(elec_m) children(); }

function at_elec_pt(p) = elec_m * [p.x, p.y, p.z, 1];

// ---------- sensor pod ----------

// The optical axis is x=y=0 of the board; the package, lens and PCB are
// centred at x=sc, towards the front.
sc = -sensor_optical_offset;
sp_in = [pcb_w + 0.6, pcb_h + 0.6];
// the board's front edge, from the chip's centre; its ends, and its screws
pcb_end = pcb_w / 2 + pcb_ext;
pcb_x0 = sc - pcb_end;
pcb_x1 = sc + pcb_w / 2;
pcb_holes = [[pcb_x1 + pcb_ear_x, 0], [sc + pcb_hole2.x, pcb_hole2.y]];
// how far in towards the ball's centre the board's pocket is cut: the
// ball curves well away from the board's front end
pocket_reach = 14;
// the ribbon passes under the board's low edge, lying on the cover: the
// pocket's low corner stays this far above the cover
fpc_under = 2.4;

// PCB outline (from the chip's centre): rounded rectangle (stretched
// towards the front by pcb_ext) with a screw ear on its back end, grown by m
// all round
module pcb_outline(m = 0) {
  hull() {
    translate([-pcb_ext / 2, 0]) rrect([pcb_w + pcb_ext + 2 * m, pcb_h + 2 * m], pcb_r + m);
    translate([pcb_w / 2 + pcb_ear_x, 0]) circle(d = pcb_ear_d + 2 * m);
  }
}
// chip + components occupy the package's length only, and stop short of
// the board's long edges
chip_in = [16.2 + 0.6, pcb_h - 1];
// the ribbon's height over the chip's back
fpc_h = pcb_top_z + parts_h + 0.25;

// [x0, x1, y half-width, z0, z1] for the lens, PCB slot, chip zone, the FPC
// connector at the board's front end with the ribbon's U-turn past the
// edge and back over it, and the ribbon's channel over the chip's back as
// far as its fold
sensor_zones = [
  [sc - lens_w / 2, sc + lens_w / 2, lens_h / 2, 0.8, pcb_top_z - pcb_t],
  [pcb_x0 - 0.3, sc + sp_in.x / 2, sp_in.y / 2, pcb_top_z - pcb_t, pcb_top_z + 0.3],
  [sc - chip_in.x / 2, sc + chip_in.x / 2, chip_in.y / 2, pcb_top_z, pcb_top_z + parts_h],
  [pcb_x0 - fpc_bend, pcb_x0 + fpc_conn.y + 0.3, fpc_conn.x / 2 + 0.3, pcb_top_z, pcb_top_z + fpc_conn.z + 1.2],
  [pcb_x0 + 2, sc + fpc_fold + fpc_chan.x / 2, fpc_chan.x / 2, pcb_top_z + 1, pcb_top_z + parts_h + fpc_chan.y]];

module zone(z, m = 0) {
  translate([z[0] - m, -z[2] - m, z[3] - m]) cube([z[1] - z[0] + 2 * m, 2 * z[2] + 2 * m, z[4] - z[3] + 2 * m]);
}

// The pod is a pillow round the board: the hull of balls (radius pod_r) at
// the corners of its outer face and, under those, on the ball's cup, so its
// walls follow the pocket's all the way in to the ball. Its box, in the
// board frame: x range, y half-width and the outer face's height
pod_x = [pcb_x0 - fpc_bend - 0.3 - wall - 0.8, pcb_x1 + pcb_ear_x + pcb_ear_d / 2 + 0.3 + wall + 1.5];
pod_y = sp_in.y / 2 + wall + 0.5;
pod_z = pcb_top_z + parts_h + fpc_chan.y + wall;
function cup_z(x, y) = sqrt(pow(R + ball_clear, 2) - x * x - y * y) - R;
pod_balls = [for (x = [pod_x[0] + pod_r, pod_x[1] - pod_r], y = [-1, 1] * (pod_y - pod_r), o = [0, 1])
  [x, y, o ? pod_z - pod_r : cup_z(x, y)]];

// as low as the pod stays above floor_z and the pocket's low corner stays
// above the ribbon passing under it
sensor_el_ = sensor_el_auto
  ? max(lowest_el([for (b = pod_balls) [abs(b.y), b.z, pod_r]]),
        lowest_el([[sp_in.y / 2, pcb_top_z + 0.3]], floor_z + base_cover_t + fpc_under))
  : sensor_el;
// azimuth separation for orthogonal lines of sight: cos(sep) = -tan^2(el)
sensor_az_ = sensor_az_auto
  ? let(a = 180 - acos(max(-1, -pow(tan(sensor_el_), 2))) / 2) [a, -a]
  : sensor_az;

// Board frame: on the ball's surface at the sensor (z = outward normal, 0
// at the surface), x along the chip towards the back, y across it: up the
// slope on the right sensor, down it on the left (the same board, turned
// half a turn).
function side(az) = az > 0 ? 1 : -1;
module at_board(az) { at_ball(az, sensor_el_) rotate([0, 0, side(az) * 90]) children(); }
function board_pt(az, p) = at_ball_pt(az, sensor_el_, side(az) > 0 ? [-p.y, p.x, p.z] : [p.y, -p.x, p.z]);

module sensor_pod_outer() { hull() for (b = pod_balls) translate(b) sphere(r = pod_r, $fn = 48); }

// The ring: what a sensor board's pillow sweeps out when it is turned round
// the ball's axis, from one sensor's front end round the back to the
// other's; its section ([radius, z] of the pillow's balls) is hulled with
// the rim's. From each end the same section is swept on round the front,
// one station every couple of degrees: over ring_taper degrees it shrinks,
// eased at both ends, to the rim's own section, and towards the front that
// swells out again, as smoothly, into the low front pod. So the outside is
// one surface, with no crease where the ring, the rim and the front pod meet.
ring_xs = concat([0], [for (i = [0 : 6]) pod_x[0] + pod_r + (pod_x[1] - pod_x[0] - 2 * pod_r) * i / 6]);
function ring_rz(p) = let(q = board_pt(sensor_az_[0], p)) [norm([q.x, q.y]), q.z];
// each ball's [radius, z, on the outside (not the cup), upper]
ring_rim_r = 1.5;
ring_pts = [for (x = ring_xs, y = [-1, 1] * (pod_y - pod_r), o = [0, 1])
  concat(ring_rz([x, y, o ? pod_z - pod_r : cup_z(x, y)]), [o, y > 0 ? 1 : 0])];
ring_top = max([for (p = ring_pts) p[1]]) + pod_r;
// the full ring reaches a little past the pillow's foremost corner
ring_a0 = min([for (b = pod_balls) if (b.x < 0) let(q = board_pt(sensor_az_[0], b)) atan2(q.x, -q.y)]) - 3;

module ring_profile() {
  hull() {
    for (p = ring_pts) translate([p[0], p[1]]) circle(r = pod_r, $fn = 48);
    translate([R - 4, 0]) square([rim_wall + 4, rim_h]);
  }
}

// The front pod's outline is a circle (elec_dome_d across, seen from
// above), joined to the rim's by a fillet (an arc of radius front_fillet,
// tangent to both) at the waist either side: how far that outline reaches
// beyond the rim at an azimuth (az >= 0)
dome_c = -at_elec_pt([elec_size.x / 2 + elec_dome_back, elec_size.y / 2, 0]).y;
front_m = R + rim_wall + front_fillet;
// azimuths of the fillet's centre (where it leaves the rim) and of where it
// meets the pod's circle
front_az0 = acos((pow(front_m, 2) + pow(dome_c, 2) - pow(elec_dome_d / 2 + front_fillet, 2)) / (2 * front_m * dome_c));
front_az1 = let(cf = front_m * [sin(front_az0), -cos(front_az0)], cd = [0, -dome_c],
                t = cd + (cf - cd) * (elec_dome_d / 2) / (elec_dome_d / 2 + front_fillet)) atan2(t.x, -t.y);
front_az = [front_az0, front_az1];
function front_bump(az) =
  az >= front_az[0] ? 0
  : az >= front_az[1] ? front_m * cos(front_az[0] - az) - sqrt(pow(front_fillet, 2) - pow(front_m * sin(front_az[0] - az), 2)) - (R + rim_wall)
  : dome_c * cos(az) + sqrt(pow(elec_dome_d / 2, 2) - pow(dome_c * sin(az), 2)) - (R + rim_wall);
// 0 where the section is the rim's, 1 where it is the front pod's
function front_g(az) = let(x = min(1, front_bump(az) / 8)) x * x * (3 - 2 * x);
// how much of the ring's section is left at an azimuth
function ring_w(az) = az >= ring_a0 ? 1 : az <= ring_a0 - ring_taper ? 0
  : (1 - cos(180 * (az - ring_a0 + ring_taper) / ring_taper)) / 2;

// the section at azimuth s * az (az >= 0), as balls
module ring_station(s, az) {
  w = ring_w(az);
  g = front_g(az);
  rf = ring_rim_r + (elec_pod_r - ring_rim_r) * g;
  for (p = ring_pts) {
    f = [p[2] ? R + rim_wall + front_bump(az) - rf : R + ball_clear,
         p[3] ? rim_h + (elec_pod_h - rim_h) * g - rf : rf];
    translate(polar_pt(s * az, f[0] + (p[0] - f[0]) * w, f[1] + (p[1] - f[1]) * w))
      sphere(r = rf + (pod_r - rf) * w, $fn = 32);
  }
}

module back_ring() {
  rotate([0, 0, ring_a0 - 90]) rotate_extrude(angle = 360 - 2 * ring_a0) ring_profile();
  n = ceil(ring_a0 / 2);
  for (s = [1, -1], i = [0 : n - 1]) hull() { ring_station(s, ring_a0 * i / n); ring_station(s, ring_a0 * (i + 1) / n); }
}

// the ribbon's channel from its fold down the slope, over the chip's back
// and past the board's low edge (s: side(az))
module fpc_leg(s) {
  l = sp_in.y / 2 + 2.2 + fpc_chan.x / 2;
  translate([sc + fpc_fold - fpc_chan.x / 2, s > 0 ? fpc_chan.x / 2 - l : -fpc_chan.x / 2, pcb_top_z + 1])
    cube([fpc_chan.x, l, parts_h + fpc_chan.y - 1]);
}

// PCB + lens go in from the ball side, through a pocket the size of the PCB,
// and are screwed against the pocket's back face, where a closed cavity
// clears the chip and the FPC connector; the pod is solid behind the two
// screws, and its back stays closed
module sensor_cavity(s = 1) {
  translate([sc, 0, -pocket_reach]) linear_extrude(pcb_top_z + pocket_reach) pcb_outline(0.3);
  zone(sensor_zones[2], 0.3);
  zone(sensor_zones[3]);
  zone(sensor_zones[4]);
  fpc_leg(s);
  for (h = pcb_holes) translate([h.x, h.y, pcb_top_z - eps])
    cylinder(d = pcb_screw_d, h = pcb_screw_depth + eps, $fn = 16);
}

// blends the pods into the rim; entirely inside the rim's footprint, so its
// rounding only softens the hull with the pod
module rim_patch(az, w) {
  rotate([0, 0, az - 90]) translate([R - 4 + (rim_wall + 4) / 2, 0, (rim_h - 2) / 2])
    rbox([rim_wall + 4, w, rim_h + 2], shell_r);
}

// ---------- sensor cover ----------

// Fills the board's pocket from the PCB's face to the ball's cup (board
// frame), with a cavity for the lens, a window under it and counterbored
// holes for the board's two screws; the ear's counterbore is open at the
// ear's end, where it would leave no wall. The same part serves both
// sensors.
module sensor_cover() {
  zt = pcb_top_z - pcb_t;
  zs = zt - cover_seat;
  difference() {
    translate([sc, 0, -pocket_reach]) linear_extrude(zt + pocket_reach) pcb_outline(0.3 - cover_gap);
    translate([0, 0, -R]) sphere(r = R + ball_clear, $fn = 128);
    translate([sc - lens_w / 2 - 0.2, -lens_h / 2 - 0.2, lens_ref_z - 0.1]) cube([lens_w + 0.4, lens_h + 0.4, zt]);
    hull() for (x = [cover_window[0], cover_window[1]])
      translate([x, 0, -pocket_reach]) cylinder(r = cover_window[2], h = pocket_reach + zt, $fn = 48);
    for (h = pcb_holes) translate([h.x, h.y, -pocket_reach - eps]) {
      cylinder(d = 2.4, h = pocket_reach + zt + 1, $fn = 24);
      hull() for (x = [0, h.y == 0 ? pcb_ear_d : 0]) translate([x, 0, 0]) cylinder(d = cover_head_d, h = pocket_reach + zs, $fn = 32);
    }
  }
}

module sensor_covers() { for (az = sensor_az_) color("#c8c4bc") at_board(az) sensor_cover(); }

// the boards' screws, heads on the covers' seats (board frame)
module sensor_screws() {
  for (h = pcb_holes) translate([h.x, h.y, pcb_top_z - pcb_t - cover_seat]) rotate([180, 0, 0]) screw(10);
}

// ---------- electronics pod ----------

// The base PCB's tongue under the front pod takes its outline from this: a
// squashed sphere around the cavity + wall (sides and roof) + base, its
// height the lowest that still covers the (front) box corners at
// elec_dome_d. (The pod itself is part of the swept outside: see
// back_ring(), which is bigger than this all round.)
elec_box = [elec_size.x + 2 * wall, elec_size.y + 2 * wall, elec_floor + elec_size.z + wall];
elec_dome_r = [elec_dome_d / 2, elec_dome_d / 2,
  elec_box.z / 2 / sqrt(1 - (pow(elec_box.x + 2 * elec_dome_back, 2) + pow(elec_box.y, 2)) / pow(elec_dome_d, 2))];

module elec_pod_outer() {
  at_elec() translate([elec_size.x / 2 + elec_dome_back, elec_size.y / 2, -elec_floor + elec_box.z / 2]) ellipsoid(elec_dome_r);
}

module elec_pod_blob() { hull() { elec_pod_outer(); rim_patch(0, elec_size.y + 2 * wall); } }

module elec_cavity() {
  at_elec() {
    cube(elec_size);
  }
  usb_recess();
  // the receptacle's way through the wall between the recess and the cavity
  // (the base PCB has a notch there)
  at_elec() translate([-eps, elec_size.y / 2 - 4.8, -base_pcb_t - eps]) cube([wall + 0.6, 9.6, base_pcb_t + 2 * eps]);
  wire_bay();
}

// plug overmold recess right in front of the receptacle (which hangs below
// the XIAO, centred 1.6 under the PCB's top), open to the table through the
// cover; the base PCB has a notch there, a wall wider all round
module usb_recess() {
  at_elec() translate([eps, elec_size.y / 2, 0]) rotate([0, -90, 0]) hull()
    for (z = [-usb_axis, -elec_floor - 5], d = [-1, 1])
      translate([z, d * (usb_plug.x - usb_plug.y) / 2, 0]) cylinder(d = usb_plug.y, h = 30);
}

// where the XIAO's parts hang below it: through the base PCB, and d into the cover
module xiao_cutout(h, d = 0) {
  at_elec() translate([0, elec_size.y / 2 - xiao.y / 2 + xiao_pad_w, -base_pcb_t - d])
    cube([0.3 + usb_overhang + xiao.x, xiao.y - 2 * xiao_pad_w, h]);
}

// ---------- battery ----------

// The cell's frame: on the ball's surface at the back, at the sensors'
// elevation: x down the slope, y across, z outwards. The pocket runs on
// down to the cover, which is how the cell goes in; the cell stands on the
// cover on its low outer edge, and its leads leave from the wedge of room
// that leaves under its inner edge.
module at_batt() { at_ball(180, sensor_el_) children(); }
function batt_pt(p) = at_ball_pt(180, sensor_el_, p);
batt_pocket = [batt.x + 0.6, batt.y + 0.6, batt.z + 0.4];
// where a face z out from the ball comes down to height h
function batt_x_at(z, h) = (zc + (R + z) * sin(sensor_el_) - h) / cos(sensor_el_);
batt_x1 = batt_x_at(batt_z0 + batt_pocket.z, floor_z + base_cover_t + 0.2);

module batt_cavity() {
  at_batt() translate([batt_x1 - batt_pocket.x, -batt_pocket.y / 2, batt_z0]) cube([batt_pocket.x + 30, batt_pocket.y, batt_pocket.z]);
}

// The leads' way round to the XIAO (world, at the cover's top): out of the
// pocket's inner corner, in to the groove's radius, round, and up a shaft
// behind the corner of the XIAO's cavity, inside the base PCB's inner edge
wire_bay_w = 5.5;
wire_bay_x = batt_wire_side * (elec_size.y / 2 - wire_bay_w / 2);
wire_bay_y = [elec_back, -batt_wire[0]];
function az_of(p) = atan2(p.x, -p.y);
wire_p0 = [batt_wire_side * (batt_pocket.y / 2 - 2.5),
           batt_pt([batt_x_at(batt_z0, floor_z + base_cover_t), 0, batt_z0 + 1.6]).y];
wire_az = [abs(az_of(wire_p0)), abs(az_of([wire_bay_x, wire_bay_y[1] - 1]))];
wire_path = concat([wire_p0],
  [for (i = [0 : 24]) polar2(batt_wire_side * (wire_az[0] + (wire_az[1] - wire_az[0]) * i / 24), batt_wire[0])]);

module wire_groove() {
  z0 = floor_z + base_cover_t - eps;
  for (i = [0 : len(wire_path) - 2]) hull() for (p = [wire_path[i], wire_path[i + 1]])
    translate([p.x, p.y, z0]) cylinder(d = batt_wire[1], h = batt_wire[2] + eps, $fn = 16);
}

// the shaft (below the PCB's level only where there is no PCB) and, over
// the PCB, a bay that opens into the XIAO's cavity
module wire_bay() {
  l = wire_bay_y[1] - wire_bay_y[0] + eps;
  translate([wire_bay_x - wire_bay_w / 2, wire_bay_y[0] - eps, base_top]) cube([wire_bay_w, l, elec_size.z]);
  intersection() {
    translate([wire_bay_x - wire_bay_w / 2, wire_bay_y[0], floor_z + base_cover_t - eps]) cube([wire_bay_w, l, base_pcb_t + 2 * eps]);
    cylinder(r = base_band_r[0] - 0.4, h = 50);
  }
}

// ---------- base PCB + sensor ribbons ----------

function polar2(az, r) = [r * sin(az), -r * cos(az)];
// plan unit vectors at an azimuth: outwards, and towards increasing azimuth
function rhat(az) = [sin(az), -cos(az)];
function that(az) = [cos(az), sin(az)];

// where a ribbon, folded to run down the slope over the chip's back, passes
// the board's low edge (board frame)
function fpc_top(az) = [sc + fpc_fold, -side(az) * (sp_in.y / 2 + 1), fpc_h];
// the ribbon's path in the sensor pod (board frame): into the mouth at the
// board's front edge, round the U-turn, back over the connector and over
// the chip to the fold
function fpc_path(az) = [
  [pcb_x0 + 1.5, 0, pcb_top_z + 0.9], [pcb_x0 - 0.6, 0, pcb_top_z + 0.9],
  [pcb_x0 - fpc_bend / 2, 0, pcb_top_z + 1.6], [pcb_x0 - 0.6, 0, pcb_top_z + fpc_conn.z + 0.3],
  [pcb_x0 + fpc_conn.y, 0, pcb_top_z + fpc_conn.z + 0.3],
  [pcb_x0 + fpc_conn.y + 1.5, 0, fpc_h], [sc + fpc_fold, 0, fpc_h]];
function path_len(p) = len(p) < 2 ? 0 : [for (i = [0 : len(p) - 2]) norm(p[i + 1] - p[i])] * [for (i = [0 : len(p) - 2]) 1];
// under the case (world): from fpc_top it turns in under the board, lying
// on the cover, to the crease on the band's middle radius; from there it
// runs straight (a chord of that circle, rising to the mouth's height) into
// the connector, 1.5 mm into its mouth; the run is whatever length the
// ribbon has left
fpc_z = base_top + 1;
fpc_low_z = floor_z + base_cover_t + 0.5;
fpc_mid_r = (base_band_r[0] + base_band_r[1]) / 2;
function fpc_crease(az) =
  let(g = board_pt(az, fpc_top(az)), b = [g.x, g.y] * that(az),
      p = sqrt(pow(fpc_mid_r, 2) - b * b) * rhat(az) + b * that(az))
  [p.x, p.y, fpc_low_z];
function fpc_used(az) = path_len(fpc_path(az)) + sp_in.y / 2 + 1
  + norm(fpc_crease(az) - board_pt(az, fpc_top(az)));
function fpc_run(az) = fpc_len - fpc_slack - fpc_used(az) - 1.5;
// the connector, on the band's middle, towards the front from the crease
function fpc_foot_az(az) = az_of(fpc_crease(az))
  - side(az) * 2 * asin((fpc_run(az) + fpc_conn.y / 2) / (2 * fpc_mid_r));
function fpc_foot(az) = concat(polar2(fpc_foot_az(az), fpc_mid_r), [base_top]);
// plan angle (from +x) of a connector's mouth, which faces the crease, and where it is
function fpc_ang(az) = let(c = fpc_crease(az), f = fpc_foot(az)) atan2(c.y - f.y, c.x - f.x);
function fpc_mouth(az) = let(f = fpc_foot(az), a = fpc_ang(az))
  [f.x + fpc_conn.y / 2 * cos(a), f.y + fpc_conn.y / 2 * sin(a), fpc_z];
// which way (plan, world) the ribbon's conductors run at the connector, in
// the order they run along the sensor board's +y. Bends keep the ribbon's
// frame; the fold over the chip and the crease each mirror it (and turn it
// over): after the fold they run towards decreasing azimuth, and the crease
// leaves them a quarter turn clockwise from the way the ribbon goes in (for
// ../pcb/gen/generate.py, which numbers the pins)
function fpc_e(az) = let(a = fpc_ang(az)) [-sin(a), cos(a)];
// how far round the band reaches: a little past the mouths
base_band_end = max([for (az = sensor_az_) abs(az_of(fpc_mouth(az)))]) + 1.5 / fpc_mid_r * 180 / PI;

// screws through the cover and the PCB, and through the cover only
pcb_screws = concat(
  [for (s = [-1, 1]) let(p = at_elec_pt([elec_size.x / 2, elec_size.y / 2 + s * elec_screw_y, 0])) [p.x, p.y]],
  [for (p = base_screws_polar) polar2(p[0], p[1])]);
cover_screws = [for (p = cover_screws_polar) polar2(p[0], p[1])];
base_screws = concat(pcb_screws, cover_screws);

// the case's foot where the cover meets it (the rim and the front pod; the
// ring only adds to it), less a wall: the PCB (and its groove) stays inside
// this, so it never shows
module base_inside() {
  offset(delta = -wall) projection(cut = true) translate([0, 0, -floor_z - base_cover_t - 0.05]) union() { rim(); elec_pod_blob(); }
}

// base PCB outline (world x/y, no holes), grown by m: the band, ending
// straight just past each FPC connector, and a tongue under the front pod,
// with a notch for the USB plug, all kept inside the case's foot
module base_pcb_shape(m = 0) {
  a1 = base_band_end;
  offset(r = m) offset(r = 1.5) offset(delta = -1.5) intersection() {
   offset(delta = -m) base_inside();
   union() {
   difference() {
    union() {
      intersection() {
        circle(r = base_band_r[1], $fn = 128);
        polygon(concat([[0, 0]], [for (a = [-a1 : 5 : a1]) polar2(a, 100)], [polar2(a1, 100)]));
      }
      projection() at_elec() cube([elec_size.x, elec_size.y, 1]);
      projection(cut = true) translate([0, 0, -floor_z - base_cover_t - 0.1]) elec_pod_blob();
    }
    circle(r = base_band_r[0], $fn = 96);     // keeps the tongue clear of the ball's cup too
    nh = usb_plug.x / 2 + wall + 0.3;
    projection() at_elec() translate([-40, elec_size.y / 2 - nh, 0]) cube([40 + wall + 0.3, 2 * nh, 1]);
   }
   // round the connectors, a little wider than the band
   for (az = sensor_az_) translate(fpc_foot(az)) rotate(fpc_ang(az)) square([fpc_conn.y + 1.2, fpc_conn.x + 1.2], center = true);
   }
  }
}

module base_pcb_2d() {
  difference() {
    base_pcb_shape();
    for (p = pcb_screws) translate(p) circle(d = 2.2, $fn = 24);
    projection() xiao_cutout(1);
  }
}

module base_pcb() { color("darkgreen") translate([0, 0, floor_z + base_cover_t]) linear_extrude(base_pcb_t) base_pcb_2d(); }

// the cover: the case's outer cut off at base_cover_t, with the ball's hole,
// the USB plug's recess, a pocket for the XIAO's parts, a hole under its
// reset button and the screws' countersunk holes
module base_cover() {
  difference() {
    intersection() {
      body_outer();
      translate([-100, -100, floor_z]) cube([200, 200, base_cover_t]);
    }
    ball_cuts();
    usb_recess();
    xiao_cutout(xiao_parts_h - base_pcb_t + 0.2 + eps, xiao_parts_h - base_pcb_t + 0.2);
    // (the model lies upside down: see electronics())
    at_elec() translate([0.3 + usb_overhang + xiao_reset.x, elec_size.y / 2 - xiao_reset.y, -elec_floor - 1])
      cylinder(d = reset_hole_d, h = elec_floor + 1, $fn = 24);
    for (p = base_screws) translate([p.x, p.y, floor_z]) {
      translate([0, 0, -1]) cylinder(d = 2.4, h = base_cover_t + 2, $fn = 16);
      translate([0, 0, -eps]) cylinder(d1 = 4.2, d2 = 2.4, h = 0.9, $fn = 24);
    }
  }
}

// what the base PCB takes out of the body: its groove (from the cover up), the pockets over the
// FPC connectors, the ribbons' ways in under the sensor boards and their
// channels along the underside (open to the cover, so the ribbons go in from
// below), and the screws' pilot holes
module base_cuts() {
  translate([0, 0, floor_z - 1]) linear_extrude(1 + elec_floor + 0.2) base_pcb_shape(0.3);
  z0 = floor_z + base_cover_t - eps;
  hc = fpc_low_z + 0.8 - z0;
  h = fpc_z + 1.6 - z0;
  for (az = sensor_az_) {
    translate(fpc_foot(az)) rotate(fpc_ang(az))
      translate([-fpc_conn.y / 2 - 0.3, -fpc_conn.x / 2 - 0.3, -eps]) cube([fpc_conn.y + 0.3 + fpc_pocket[0], fpc_conn.x + 0.6, fpc_pocket[1]]);
    hull() {
      at_board(az) translate(fpc_top(az)) cube([fpc_chan.x, 2, 2], center = true);
      fpc_crease_room(az, z0, hc);
    }
    hull() {
      fpc_crease_room(az, z0, hc);
      translate(fpc_mouth(az)) rotate(fpc_ang(az)) translate([0, -fpc_chan.x / 2, z0 - fpc_z]) cube([1, fpc_chan.x, h]);
    }
  }
  for (p = pcb_screws) translate([p.x, p.y, base_top - eps]) cylinder(d = pcb_screw_d, h = base_screw_depth, $fn = 16);
  for (p = cover_screws) translate([p.x, p.y, floor_z + base_cover_t - eps])
    cylinder(d = pcb_screw_d, h = base_screw_depth + base_pcb_t, $fn = 16);
}

// room for a ribbon's crease, as wide as the ribbon is long there
module fpc_crease_room(az, z0, h) {
  c = fpc_crease(az);
  translate([c.x, c.y, z0]) rotate(az - 90) translate([-(fpc_chan.x + 1) / 2, -(fpc_chan.x + 1) / 2, 0])
    cube([fpc_chan.x + 1, fpc_chan.x + 1, h]);
}

// FPC connectors on the base PCB (mouth facing the ribbon), visual only
module base_fpc_conns() {
  for (az = sensor_az_) color("ivory") translate(fpc_foot(az)) rotate(fpc_ang(az))
    translate([-fpc_conn.y / 2, -fpc_conn.x / 2, 0]) cube([fpc_conn.y, fpc_conn.x, fpc_conn.z]);
}

// the ribbons, out of the sensor board's connector, back over the chip,
// down past the board's low edge and into the base PCB's connector (visual only)
module ribbons() { for (az = sensor_az_) color("goldenrod") ribbon(az); }

// one ribbon's path, as a strip w wide and t thick (thicker, it checks
// there's room to pull the ribbon through: see fpc_clear)
module ribbon(az, t = 0.1, w = fpc_w) {
  path = fpc_path(az);
  for (i = [0 : len(path) - 2])
    hull() at_board(az) for (p = [path[i], path[i + 1]]) translate(p) cube([t, w, t], center = true);
  // folded: down the slope, now as wide along the chip
  hull() at_board(az) for (p = [path[len(path) - 1], fpc_top(az)]) translate(p) cube([w, t, t], center = true);
  // in under the board to the crease; then along to the mouth
  c = fpc_crease(az);
  hull() {
    at_board(az) translate(fpc_top(az)) cube([w, t, t], center = true);
    translate(c) rotate(az - 90) cube([t, w, t], center = true);
  }
  m = fpc_mouth(az);
  hull() for (p = [c, m - 1.5 * [cos(fpc_ang(az)), sin(fpc_ang(az)), 0]])
    translate(p) rotate(fpc_ang(az)) cube([t, w, t], center = true);
}

// ---------- body ----------

module rim() {
  rotate_extrude()
    offset(r = 1.5) offset(delta = -1.5) square([R + rim_wall, rim_h]);
}

module tube(pts, d) {
  for (i = [0 : len(pts) - 2])
    hull() { translate(pts[i]) sphere(d = d, $fn = 16); translate(pts[i + 1]) sphere(d = d, $fn = 16); }
}

module support_hole(az) {
  at_ball(az, support_polar - 90) translate([0, 0, -1]) cylinder(d = support_d, h = support_d + 1);
}

module body_outer() {
  union() {
    rim();
    back_ring();
  }
}

module ball_cuts() {
  translate([0, 0, zc]) sphere(r = R + ball_clear, $fn = 128);
  translate([0, 0, -1]) cylinder(r = bottom_hole_r, h = zc);
}

// everything hollowed out of the body
module body_cuts() {
  for (az = sensor_az_) at_board(az) sensor_cavity(side(az));
  elec_cavity();
  batt_cavity();
  wire_groove();
  base_cuts();
}

module body() {
  difference() {
    body_outer();
    ball_cuts();
    translate([-100, -100, -50]) cube([200, 200, 50 + floor_z + base_cover_t]);     // flat bottom, over the cover
    body_cuts();
    for (az = support_az) support_hole(az);
  }
}

// ---------- visual-only parts ----------

module supports() {
  for (az = support_az) color("white")
    at_ball(az, support_polar - 90) translate([0, 0, support_d / 2]) sphere(d = support_d, $fn = 24);
}

// sensor board (board frame) with its two screw holes, and the FPC
// connector at its front end (mouth at the edge)
module sensor_board() {
  color("darkgreen") translate([0, 0, pcb_top_z - pcb_t])
    linear_extrude(pcb_t) difference() {
      translate([sc, 0]) pcb_outline();
      for (h = pcb_holes) translate(h) circle(d = 2.2, $fn = 16);
    }
  color("ivory") translate([pcb_x0, -fpc_conn.x / 2, pcb_top_z]) cube([fpc_conn.y, fpc_conn.x, fpc_conn.z]);
  color("#222") translate([sc - 16.2 / 2, -10.9 / 2, pcb_top_z]) cube([16.2, 10.9, 2.5]);
  color("lightblue", 0.8) translate([sc - lens_w / 2 + 0.5, -lens_h / 2 + 0.5, lens_ref_z])
    cube([lens_w - 1, lens_h - 1, pcb_top_z - pcb_t - lens_ref_z]);
  color("lightblue", 0.8) translate([0, 0, lens_ref_z - 1]) cylinder(d = 5, h = 1);
}

module sensor_boards() { for (az = sensor_az_) at_board(az) sensor_board(); }

// model = false draws the XIAO as plain boxes, which (unlike the imported
// mesh, which isn't closed) CGAL can cut for the section view
module electronics(model = true) {
  at_elec() {
    // the model has x from the board edge at the USB end, y centred and z up
    // from the board's underside; it lies upside down
    color("royalblue") translate([0.3 + usb_overhang, elec_size.y / 2, xiao.z]) rotate([180, 0, 0])
      if (model) import("../pcb/3d/xiao-nrf52840.stl");
      else {
        translate([0, -xiao.y / 2, 0]) cube(xiao);
        translate([-usb_overhang, -4.5, xiao.z]) cube([7.5, 9, 3.2]);
      }
  }
}

// the cell in its pocket, protection board down, and the leads round to
// the XIAO's back
module battery(only = "", slide = 0) {
  at_batt() translate([batt_x1 - batt.x - 0.3 + slide, -batt.y / 2, batt_z0 + 0.2]) lipo(only);
  if (only == "" || only == "leads") {
    zw = floor_z + base_cover_t + 0.6;
    zx = base_top + xiao.z + xiao_pads + 0.5;
    far = at_elec_pt([0.3 + usb_overhang + xiao.x, 0, 0]).y;
    for (d = [-1, 1]) color(d < 0 ? "black" : "red") {
      o = d * 0.55;
      pts = concat(
        [batt_pt([batt_x1 - 1.5, -batt_wire_side * (batt.y / 2 - 5 + d), batt_z0 + 1.5])],
        [for (i = [0 : len(wire_path) - 1]) let(p = wire_path[i], r = norm(p)) [p.x * (r + o) / r, p.y * (r + o) / r, zw]],
        [[wire_bay_x + o, wire_bay_y[1] - 1.2, zx], [wire_bay_x + o, far - 2, zx],
         [batt_wire_side * 3 + o * 2.5, far - 4, zx], [batt_wire_side * 3 + o * 2.5, far - 4, zx - 0.5]]);
      tube(pts, 0.8);
    }
  }
}

// a USB-C plug in the receptacle (the biggest the spec allows), visual and
// for part="usb_check"
module usb_plug_model() {
  // the receptacle, as far as the XIAO's edge, and the plug in it
  at_elec() color("silver") translate([0.3, elec_size.y / 2 - 4.5, -3.2]) cube([usb_overhang, 9, 3.2]);
  at_elec() translate([-0.1, elec_size.y / 2, -usb_axis]) rotate([0, -90, 0]) {
    color("silver") translate([0, 0, -6.5]) linear_extrude(6.5) rrect([2.56, 8.34], 1.2);
    color("#333") linear_extrude(usb_overmold.z) rrect([usb_overmold.y, usb_overmold.x], 2);
  }
}

// pouch cell in [0, batt]: the pouch, then the taped protection board at the +x end
module lipo(only = "") {
  if (only == "" || only == "pouch")
    color("silver") translate([(batt.x - batt_pcm) / 2, batt.y / 2, batt.z / 2]) rbox([batt.x - batt_pcm, batt.y, batt.z], 1.2);
  if (only == "" || only == "pcm")
    color("gold") translate([batt.x - batt_pcm / 2 - 0.1, batt.y / 2, batt.z / 2])
      rbox([batt_pcm + 0.2, batt.y - 2, batt.z * 0.75], 0.6);
}

// cut = true removes everything on one side of the vertical plane at section_az;
// each part is rendered separately so it keeps its colour
module cut(c) {
  if (c) render() difference() { children(); cut_half(); }
  else children();
}

module cut_half() { rotate([0, 0, section_az - 90]) translate([-100, eps, -50]) cube([200, 100, 200]); }

module assembly(c = false) {
  color("#d8d4cc") cut(c) body();
  color("#b8b4ac") cut(c) base_cover();
  cut(c) base_pcb();
  cut(c) base_fpc_conns();
  cut(c) ribbons();
  color("firebrick") cut(c) translate([0, 0, zc]) sphere(r = R, $fn = 128);
  cut(c) supports();
  cut(c) sensor_boards();
  cut(c) sensor_covers();
  cut(c) electronics(!c);
  if (c) cut(c) usb_plug_model();
  cut(c) battery();
}

// screw shank along -z from z=0, head at z=0
module screw(l, head_d = 3.8) {
  color("dimgray") {
    translate([0, 0, -l]) cylinder(d = 2, h = l, $fn = 16);
    cylinder(d = head_d, h = 1.2, $fn = 24);
  }
}

// every part pulled apart along the way it goes in: the ball and support
// balls up, the sensor boards, their covers and their screws in towards the
// ball (by these shares of d), the base PCB (with the
// XIAO on it) down out of the case, the battery down its pocket, the cover below that,
// and the screws below it; d = 0 leaves it assembled
explode_in = [0.25, 0.5, 0.8];
module exploded(d = explode_d, only = "") {
  function show(p) = only == "" || only == p;
  if (show("body")) color("#d8d4cc") body();
  if (show("ball")) color("firebrick") translate([0, 0, zc + 2.2 * d]) sphere(r = R, $fn = 128);
  if (show("supports")) translate([0, 0, d]) supports();
  if (show("sensor_boards")) for (az = sensor_az_) at_board(az) translate([0, 0, -explode_in[0] * d]) sensor_board();
  if (show("sensor_covers")) for (az = sensor_az_) color("#c8c4bc") at_board(az) translate([0, 0, -explode_in[1] * d]) sensor_cover();
  if (show("sensor_screws")) for (az = sensor_az_) at_board(az) translate([0, 0, -explode_in[2] * d]) sensor_screws();
  translate([0, 0, -d]) {
    if (show("electronics")) electronics();
    if (show("base_pcb")) { base_pcb(); base_fpc_conns(); }
    if (show("leads")) battery("leads");
  }
  // the cell slides out down its pocket
  for (p = ["pouch", "pcm"]) if (show(p)) battery(p, 1.3 * d);
  if (show("cover")) translate([0, 0, -1.8 * d]) color("#b8b4ac") base_cover();
  if (show("screws")) for (p = base_screws) translate([p.x, p.y, floor_z - 1.8 * d - (d > 0 ? 4 : 0)]) rotate([180, 0, 0]) screw(8);
}

// the same placements as 4x4 matrices, for the render: at_board(az)
function m_tr(v) = [[1, 0, 0, v.x], [0, 1, 0, v.y], [0, 0, 1, v.z], [0, 0, 0, 1]];
function m_rz(a) = [[cos(a), -sin(a), 0, 0], [sin(a), cos(a), 0, 0], [0, 0, 1, 0], [0, 0, 0, 1]];
function m_ry(a) = [[cos(a), 0, sin(a), 0], [0, 1, 0, 0], [-sin(a), 0, cos(a), 0], [0, 0, 0, 1]];
function at_board_m(az) = m_tr([0, 0, zc]) * m_rz(az - 90) * m_ry(90 - sensor_el_) * m_tr([0, 0, R]) * m_rz(side(az) * 90);

// ball, sensor boards and electronics only, over a translucent table
module hardware() {
  color("firebrick") translate([0, 0, zc]) sphere(r = R, $fn = 128);
  sensor_boards();
  electronics();
  battery();
  base_pcb();
  base_fpc_conns();
  ribbons();
  color("#8a9", 0.25) translate([-60, -60, -1]) cube([120, 120, 1]);
}

if (part == "assembly") assembly();
else if (part == "exploded") exploded(only = explode_only);
else if (part == "hardware") hardware();
else if (part == "section") assembly(true);
else if (part == "body") body();
else if (part == "base_cover") base_cover();
// as it prints: the face that lies on the board down
else if (part == "sensor_cover") translate([0, 0, pcb_top_z - pcb_t]) rotate([180, 0, 0]) sensor_cover();
// what's in the way of the biggest USB-C plug: should be empty
else if (part == "usb_check") intersection() { union() { body(); base_cover(); base_pcb(); } usb_plug_model(); }
else if (part == "base_pcb") difference() { base_pcb_shape(); projection() xiao_cutout(1); }
else if (part == "sensor_pcb") translate([sc, 0]) pcb_outline();
// what's in the way of a ribbon fpc_clear thicker than it is: should be empty
else if (part == "fpc_check") intersection() { body(); for (az = sensor_az_) ribbon(az, fpc_clear, fpc_w + 1); }
// where a cavity comes within 0.8 mm of the case's outside (or through it): should be empty
else if (part == "wall_check") difference() {
  minkowski() { body_cuts(); sphere(r = 0.8, $fn = 8); }
  body_outer();
  translate([0, 0, zc]) sphere(r = R + ball_clear + 1.5, $fn = 64);
  translate([-100, -100, -50]) cube([200, 200, 50 + floor_z + base_cover_t + 0.01]);
  usb_recess();
}

echo(str("ball top z = ", zc + R, "  sensor el = ", sensor_el_, "  sensor az = ", sensor_az_,
          "  front pod top z = ", elec_pod_h, "  front y = ", -dome_c - elec_dome_d / 2,
          "  ring top z = ", ring_top, "  ring outer r = ", max([for (p = ring_pts) p[0]]) + pod_r, "  ring from az = ", ring_a0, " tapering to ", ring_a0 - ring_taper,
          "  USB plug above table = ", base_top - usb_axis - usb_overmold.y / 2));
// for laying out the base PCB (world x/y, mm; table at z=0)
echo(str("base PCB: XIAO board corner at USB end, left = ", at_elec_pt([0.3 + usb_overhang, (elec_size.y + xiao.y) / 2, 0]),
         "  screws = ", pcb_screws,
         "  FPC connectors (centre, angle its mouth faces) = ", [for (az = sensor_az_) [fpc_foot(az), fpc_ang(az)]],
         "  ribbon run along the band = ", [for (az = sensor_az_) fpc_run(az)]));

// for render_exploded.py: where each board's top face goes in the exploded
// view, as matrices from the board's KiCad frame (x, -y, z up from its top)
echo(str("EXPLODED {\"sensor\": ", [for (az = sensor_az_) at_board_m(az) * m_tr([0, 0, pcb_top_z - explode_in[0] * explode_d])],
         ", \"base\": ", m_tr([0, 0, base_top - explode_d]), "}"));

// machine-readable, for ../pcb/gen/generate.py: base PCB positions in world
// x/y, sensor board positions in its own frame (origin on the optical axis,
// x along the chip towards the back, y across)
echo(str("KICAD {\"xiao_center\": ", at_elec_pt([0.3 + usb_overhang + xiao.x / 2, elec_size.y / 2, 0]),
         ", \"screws\": ", pcb_screws,
         ", \"fpc\": ", [for (az = sensor_az_) [fpc_foot(az), fpc_ang(az), fpc_e(az)]],
         ", \"sensor_az\": ", sensor_az_, ", \"sensor_el\": ", sensor_el_,
         ", \"sensor\": {\"sc\": ", sc, ", \"pcb_end\": ", pcb_end, ", \"pcb_w\": ", pcb_w, ", \"pcb_h\": ", pcb_h,
         ", \"holes\": ", pcb_holes, ", \"chip_x\": ", [sc - chip_in.x / 2, sc + chip_in.x / 2],
         "}}"));
