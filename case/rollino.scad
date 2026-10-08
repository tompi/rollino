// Rollino - low-profile finger trackball
//
// Ball floats `ball_gap` above the table on three ceramic support balls.
// Two PMW3610 sensors sit in pods at the back-left/back-right, looking up at
// the ball from as low as they fit; their azimuths are chosen so the lines of sight are
// ~90 deg apart, so X, Y and twist are all observable.
// A XIAO nRF52840 + LiPo lie flat in a squashed-sphere pod at the front,
// USB-C pointing forward, pushed in against the ball. The XIAO is soldered
// to a base PCB that sits in a groove in the case's underside; it reaches
// round under each sensor, where a short FPC ribbon runs up to the sensor
// board. A cover over the whole underside hides it, and the same screws hold
// both.
//
// Coordinates: table is z=0, front (towards the user) is -y.
// Azimuths are measured from the front, positive towards +x.

/* [View] */
// assembly | exploded | section | hardware | body | base_cover | base_pcb (2D, for DXF)
part = "body";
// azimuth of the vertical cut plane for part="section"
section_az = 135;

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
// corner radius of the round sensor PCBs
pcb_r = 6;
// rounding of the rim patches that blend a pod into the rim
shell_r = 4;
// how far a pod's ellipsoid is inflated past its zones' combined bounding
// box (x, y, z), so it still fully covers their corners
bump_k = [1.45, 1.45, 2.0];
// same, for the two (smaller) sensor pods; z is pushed further so they read
// as thick, ball-like bumps rather than flattened domes
sensor_k = [1.45, 1.45, 2.3];

/* [Sensors: PMW3610 + LM18-LSI] */
// true: put the sensors as low as floor_z allows
sensor_el_auto = true;
// elevation above the ball's equator (if not auto)
sensor_el = -23;
// true: choose azimuths that make the two lines of sight orthogonal
sensor_az_auto = true;
sensor_az = [130, -130];
// package centre sits this far up-slope of the optical axis (datasheet fig. 5: 7.09 - 3.18)
sensor_optical_offset = 3.9;
// datasheet: lens reference plane to surface, 2.4 +-0.2
lens_ref_z = 2.4;
// ASSUMED (same stack as PixArt LM19 designs) - verify against LM18 drawing
pcb_top_z = 7.4;
pcb_t = 1.6;
// along the slope (up/down)
pcb_w = 22;
// tangential (horizontal)
pcb_h = 20;
lens_w = 20;
lens_h = 17;
// chip + components above the sensor PCB
parts_h = 3;
// the PCB has a screw ear on one of the lens' long sides; it goes in from
// the ball side and one M2 self-tapping (plastite) screw through the ear
// holds it against the back of its pocket; pilot hole diameter
pcb_screw_d = 1.8;
// hole centre, beside the optical axis (tangential)
pcb_screw_y = lens_h / 2 + 2.2;
// pilot hole depth behind the PCB's back face
pcb_screw_depth = 5;
pcb_ear_d = 5;
// which side the ear is on: 1 = towards the back (az 180), -1 = towards the front
pcb_screw_side = 1;
// FPC connector (8-pin 0.5 mm, right-angle; e.g. Hirose FH12-8S class -
// check yours) [length, depth, height]: on the sensor board's back beside
// the chip, on the side away from the ear, mouth at the board edge; and on
// the base PCB under it
fpc_conn = [9.5, 4, 2];
// its centre along the slope (in the sensor frame), and the ribbon's width
fpc_x = -sensor_optical_offset + 3;
fpc_w = 5;

/* [Electronics pod] */
// LiPo cell 602020 (~200 mAh): [length, width, thickness]
// sizes vary between makers; this is the larger end (22 x 19.5 x 6.5 is
// listed), length including the protection board folded over one end
batt = [22, 20, 6.5];
// length of that protection-board end (kapton-taped), towards the ball
batt_pcm = 2.5;
// room behind it for the leads, which fold down to the XIAO's pads
batt_leads = 1.2;
// Seeed XIAO nRF52840 (not Sense): [length, width, PCB thickness]; sizes
// below are from Seeed's 3D model (../pcb/3d/xiao-nrf52840.stl, converted
// from the Sense STEP at https://files.seeedstudio.com/wiki/XIAO-BLE/seeed-studio-xiao-nrf52840-3d-model.zip;
// same board, plus an IMU and a mic)
xiao = [21, 17.8, 1];
// height of the USB-C receptacle (the tallest part, 3.2) on the XIAO's
// component side, and how far it overhangs the board edge
xiao_parts_h = 3.3;
usb_overhang = 1.55;
// pads on the XIAO's underside, and the gap between them and the cell
xiao_pads = 0.25;
batt_gap = 0.5;
// cavity: the XIAO is soldered upside down onto the base PCB by its
// castellated edges, its parts (USB-C included) hanging down through a
// cutout in the PCB into a pocket in the cover; the battery lies on its
// back, right on the battery pads; x runs from the USB end towards the ball
elec_size = [max(xiao.x + usb_overhang, batt.x + batt_leads) + 0.6, max(xiao.y, batt.y) + 0.6,
             xiao.z + xiao_pads + batt_gap + batt.z + 0.3];
// the PCB cutout under the XIAO leaves its castellated pads this much to sit on
xiao_pad_w = 1.4;
// the pod's outer is a squashed sphere this wide (seen from above), as low
// as it can be while covering the cavity
elec_dome_d = 46;
// how far the dome's centre sits behind the cavity's, towards the ball, so
// less of it sticks out in front (the cavity itself stays put)
elec_dome_back = 3.5;
// base PCB screws either side of the cavity, from its centre line
elec_screw_y = max(xiao.y, batt.y) / 2 + 4.8;
// plug overmold recess in front of the receptacle: [width, height]
usb_plug = [13.5, 7.5];
// lowest point of any pod above the table
floor_z = 0;

/* [Base PCB + cover] */
// the cover is the bottom slab of the case, screwed on; the PCB lies on it,
// in a groove in the case above, and countersunk M2 screws go up through
// both into the case. The upside-down XIAO's USB-C is centred on the cover's
// top, so this is what lifts a plug (overmold up to ~6.5 tall) off the table
base_cover_t = 3.6;
base_pcb_t = 1.6;
// band round the ball's bottom hole, from under the front pod to under
// each sensor: [inner, outer] radius; inside it the ball's cup and the
// support balls' holes come down close, outside it the rim's foot is rounded
base_band_r = [24, 31];
// radius of the FPC connector (and where its ribbon comes down) under each
// sensor: far enough out that its pocket stays clear of the ball's cup
base_fpc_r = 27;
// pocket over that connector, for it and the ribbon's bend: [radial, tangential, height]
fpc_pocket = [fpc_conn.x + 1.5, 9, fpc_conn.z + 1];
// extra screws on the band: [azimuth, radius] (plus two under the front
// pod), and the pilot holes' depth above the PCB (the rim is only rim_h tall)
base_screws_polar = [[75, 27.5], [-75, 27.5]];
base_screw_depth = 4.5;

$fn = 64;

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
// points in the at_ball frame stays above floor_z: a plain point, the centre
// of a ball of radius r, or the centre of an ellipse with semi-axes ax (in
// the x / cos(e) direction) and az (in the z / sin(e) direction).
function lowest_el(pts) =
  min([for (e = [-80 : 0.5 : 60])
         if (min([for (p = pts)
           let(ax = len(p) > 3 ? p[2] : (len(p) > 2 ? p[2] : 0),
               az = len(p) > 3 ? p[3] : (len(p) > 2 ? p[2] : 0))
           zc + (R + p[1]) * sin(e) - p[0] * cos(e)
             - sqrt(pow(ax * cos(e), 2) + pow(az * sin(e), 2))]) >= floor_z) e]);

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
// until its top back edge is a wall away from the ball clearance
elec_floor = base_cover_t + base_pcb_t;
base_top = floor_z + elec_floor;
elec_top = base_top + elec_size.z;
elec_back = -sqrt(pow(R + ball_clear + wall, 2) - pow(max(0, zc - elec_top), 2));
elec_m = [[0, -1, 0, elec_size.y / 2],
          [1, 0, 0, elec_back - elec_size.x],
          [0, 0, 1, base_top]];

module at_elec() { multmatrix(elec_m) children(); }

function at_elec_pt(p) = elec_m * [p.x, p.y, p.z, 1];

// ---------- sensor pod ----------

// In the at_ball frame the optical axis is x=y=0; the package, lens and PCB
// are centred at x=sc, i.e. shifted up-slope so the low edge is short.
sc = -sensor_optical_offset;
sp_in = [pcb_w + 0.6, pcb_h + 0.6];

// PCB outline: rounded rectangle with a screw ear on long side s, grown by
// m all round
module pcb_outline(s, m = 0) {
  hull() {
    rrect([pcb_w + 2 * m, pcb_h + 2 * m], pcb_r + m);
    translate([0, s * pcb_screw_y]) circle(d = pcb_ear_d + 2 * m);
  }
}
// chip + components occupy the package footprint only
chip_in = [16.2 + 0.6, sp_in.y];

// [x0, x1, y half-width, z0, z1] for the lens, PCB slot and chip zone
sensor_zones = [
  [sc - lens_w / 2, sc + lens_w / 2, lens_h / 2, 0.8, pcb_top_z - pcb_t],
  [sc - sp_in.x / 2, sc + sp_in.x / 2, sp_in.y / 2, pcb_top_z - pcb_t, pcb_top_z + 0.3],
  [sc - chip_in.x / 2, sc + chip_in.x / 2, chip_in.y / 2, pcb_top_z, pcb_top_z + parts_h]];

module zone(z, m = 0) {
  translate([z[0] - m, -z[2] - m, z[3] - m]) cube([z[1] - z[0] + 2 * m, 2 * z[2] + 2 * m, z[4] - z[3] + 2 * m]);
}

function zone_size(z, m) = [z[1] - z[0] + 2 * m, 2 * (z[2] + m), z[4] - z[3] + 2 * m];
// semi-axes of the ellipsoid that stands in for a zone: k inflates it so it
// still reaches the zone's (rounded) corners
function zone_ell_r(z, m, k = bump_k) =
  let(s = zone_size(z, m)) [s.x / 2 * k.x, s.y / 2 * k.y, s.z / 2 * k.z];

// ellipsoid blob version of a zone
module zone_ellipsoid(z, m = 0, k = bump_k) {
  translate([(z[0] + z[1]) / 2, 0, (z[3] + z[4]) / 2]) ellipsoid(zone_ell_r(z, m, k));
}

// the ellipse centre + semi-axes of a zone, as [x, z, ax, az] for lowest_el()
function zone_env(z, m, k = bump_k) =
  let(r = zone_ell_r(z, m, k)) [(z[0] + z[1]) / 2, (z[3] + z[4]) / 2, r.x, r.z];

// merges several zones into the one [x0, x1, y half-width, z0, z1] their
// combined bounding box spans, so a pod's whole shell is a single ellipsoid
// rather than a hull of several (which can read as a flat-sided capsule)
function bbox_zone(zones) = [
  min([for (z = zones) z[0]]), max([for (z = zones) z[1]]), max([for (z = zones) z[2]]),
  min([for (z = zones) z[3]]), max([for (z = zones) z[4]])];

sensor_env = [zone_env(bbox_zone(sensor_zones), wall, sensor_k)];
sensor_el_ = sensor_el_auto ? lowest_el(sensor_env) : sensor_el;
// azimuth separation for orthogonal lines of sight: cos(sep) = -tan^2(el)
sensor_az_ = sensor_az_auto
  ? let(a = 180 - acos(max(-1, -pow(tan(sensor_el_), 2))) / 2) [a, -a]
  : sensor_az;

module sensor_pod_outer() { zone_ellipsoid(bbox_zone(sensor_zones), wall, sensor_k); }

// PCB + lens go in from the ball side, through a pocket the size of the PCB,
// and are screwed (through ear s) against the pocket's back face, where a
// closed cavity clears the chip and the FPC connector and a boss behind the
// ear takes the screw; the pod's back stays solid
module sensor_cavity(s = 1) {
  translate([sc, 0, -5]) linear_extrude(pcb_top_z + 5) pcb_outline(s, 0.3);
  difference() {
    zone(sensor_zones[2], 0.3);
    translate([sc, s * pcb_screw_y, 0]) cylinder(d = pcb_ear_d, h = 20);
  }
  translate([sc, s * pcb_screw_y, pcb_top_z - eps])
    cylinder(d = pcb_screw_d, h = pcb_screw_depth + eps, $fn = 16);
}

// blends the pods into the rim; entirely inside the rim's footprint, so its
// rounding only softens the hull with the pod
module rim_patch(az, w) {
  rotate([0, 0, az - 90]) translate([R - 4 + (rim_wall + 4) / 2, 0, (rim_h - 2) / 2])
    rbox([rim_wall + 4, w, rim_h + 2], shell_r);
}

// ---------- electronics pod ----------

// squashed sphere around the cavity + wall (sides and roof) + base: its
// height is the lowest that still covers the (front) box corners at
// elec_dome_d
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
}

// plug overmold recess right in front of the receptacle (which hangs below
// the XIAO, centred 1.6 under the PCB's top), open to the table through the
// cover; the base PCB has a notch there, a wall wider all round
module usb_recess() {
  at_elec() translate([eps, elec_size.y / 2, 0]) rotate([0, -90, 0]) hull()
    for (z = [-1.6, -elec_floor - 5], d = [-1, 1])
      translate([z, d * (usb_plug.x - usb_plug.y) / 2, 0]) cylinder(d = usb_plug.y, h = 30);
}

// where the XIAO's parts hang below it: through the base PCB, and d into the cover
module xiao_cutout(h, d = 0) {
  at_elec() translate([0, elec_size.y / 2 - xiao.y / 2 + xiao_pad_w, -base_pcb_t - d])
    cube([0.3 + usb_overhang + xiao.x, xiao.y - 2 * xiao_pad_w, h]);
}

// ---------- base PCB + sensor ribbons ----------

function polar2(az, r) = [r * sin(az), -r * cos(az)];

// where sensor az's ribbon leaves the pod's chip cavity, sideways past the
// board's edge on the side away from the ear (sensor frame), and where it
// comes down onto the base PCB (world)
function fpc_side(az) = -pcb_screw_side * sign(az);
function fpc_top(az) = [fpc_x, fpc_side(az) * (sp_in.y / 2 + 1.7), pcb_top_z + 0.5 + parts_h / 2];
function fpc_foot(az) =
  let(q = at_ball_pt(az, sensor_el_, fpc_top(az)), a = atan2(q.x, -q.y)) concat(polar2(a, base_fpc_r), [base_top]);
// plan angle (from +x) of a ribbon's foot: the connector's long axis is radial
function fpc_ang(az) = let(f = fpc_foot(az)) atan2(f.y, f.x);

base_screws = concat(
  [for (s = [-1, 1]) let(p = at_elec_pt([elec_size.x / 2, elec_size.y / 2 + s * elec_screw_y, 0])) [p.x, p.y]],
  [for (p = base_screws_polar) polar2(p[0], p[1])]);

// the case's foot where the cover meets it, less a wall: the PCB (and its
// groove) stays inside this, so it never shows
module base_inside() {
  offset(delta = -wall) projection(cut = true) translate([0, 0, -floor_z - base_cover_t - 0.05]) body_outer();
}

// base PCB outline (world x/y, no holes), grown by m: the band, a lobe
// under each FPC connector, and a tongue under the front pod, with a notch
// for the USB plug, all kept inside the case's foot
module base_pcb_shape(m = 0) {
  a1 = max([for (az = sensor_az_) abs(atan2(fpc_foot(az).x, -fpc_foot(az).y))]);
  offset(r = m) offset(r = 1.5) offset(delta = -1.5) intersection() {
   offset(delta = -m) base_inside();
   difference() {
    union() {
      intersection() {
        circle(r = base_band_r[1], $fn = 128);
        polygon(concat([[0, 0]], [for (a = [-a1 : 5 : a1]) polar2(a, 100)], [polar2(a1, 100)]));
      }
      for (az = sensor_az_) translate([fpc_foot(az).x, fpc_foot(az).y]) rotate(fpc_ang(az))
        square([fpc_pocket.x + 2, fpc_pocket.y], center = true);
      projection() at_elec() cube([elec_size.x, elec_size.y, 1]);
      projection(cut = true) translate([0, 0, -floor_z - base_cover_t - 0.1]) elec_pod_blob();
    }
    circle(r = base_band_r[0], $fn = 96);     // keeps the tongue clear of the ball's cup too
    nh = usb_plug.x / 2 + wall + 0.3;
    projection() at_elec() translate([-40, elec_size.y / 2 - nh, 0]) cube([40 + wall + 0.3, 2 * nh, 1]);
   }
  }
}

module base_pcb_2d() {
  difference() {
    base_pcb_shape();
    for (p = base_screws) translate(p) circle(d = 2.2, $fn = 24);
    projection() xiao_cutout(1);
  }
}

module base_pcb() { color("darkgreen") translate([0, 0, floor_z + base_cover_t]) linear_extrude(base_pcb_t) base_pcb_2d(); }

// the cover: the case's outer cut off at base_cover_t, with the ball's hole,
// the USB plug's recess, a pocket for the XIAO's parts and the screws'
// countersunk holes
module base_cover() {
  difference() {
    intersection() {
      body_outer();
      translate([-100, -100, floor_z]) cube([200, 200, base_cover_t]);
    }
    ball_cuts();
    usb_recess();
    xiao_cutout(xiao_parts_h - base_pcb_t + 0.2 + eps, xiao_parts_h - base_pcb_t + 0.2);
    for (p = base_screws) translate([p.x, p.y, floor_z]) {
      translate([0, 0, -1]) cylinder(d = 2.4, h = base_cover_t + 2, $fn = 16);
      translate([0, 0, -eps]) cylinder(d1 = 4.2, d2 = 2.4, h = 0.9, $fn = 24);
    }
  }
}

// what the base PCB takes out of the body: its groove (from the cover up), the pockets over the
// FPC connectors, the ribbons' slots up into the sensor pods, and the screws'
// pilot holes
module base_cuts() {
  translate([0, 0, floor_z - 1]) linear_extrude(1 + elec_floor + 0.2) base_pcb_shape(0.3);
  for (az = sensor_az_) {
    translate(fpc_foot(az)) rotate(fpc_ang(az)) translate([-fpc_pocket.x / 2, -fpc_pocket.y / 2, -eps]) cube(fpc_pocket);
    hull() {
      at_ball(az, sensor_el_) translate(fpc_top(az)) cube([fpc_w + 1.5, 3, parts_h + 0.6], center = true);
      translate(fpc_foot(az)) rotate(fpc_ang(az)) translate([0, 0, 1]) cube([fpc_w + 1.5, 2.4, 2], center = true);
    }
  }
  for (p = base_screws) translate([p.x, p.y, base_top - eps]) cylinder(d = pcb_screw_d, h = base_screw_depth, $fn = 16);
}

// FPC connectors on the base PCB (mouth facing the ribbon), visual only
module base_fpc_conns() {
  for (az = sensor_az_) color("ivory") translate(fpc_foot(az)) rotate(fpc_ang(az))
    translate([-fpc_conn.x / 2, 1, 0]) cube(fpc_conn);
}

// the ribbons, out of the sensor board's connector, down the slot and into
// the base PCB's connector (visual only)
module ribbons() {
  for (az = sensor_az_) color("goldenrod") {
    s = fpc_side(az);
    hull() at_ball(az, sensor_el_) {
      translate([fpc_x, s * (pcb_h / 2 - 0.5), pcb_top_z + 1]) cube([fpc_w, 1, 0.1], center = true);
      translate(fpc_top(az)) cube([fpc_w, 0.1, 0.1], center = true);
    }
    hull() {
      at_ball(az, sensor_el_) translate(fpc_top(az)) cube([fpc_w, 0.1, 0.1], center = true);
      translate(fpc_foot(az)) rotate(fpc_ang(az)) translate([0, -0.5, 1.5]) cube([fpc_w, 0.1, 0.1], center = true);
    }
    hull() translate(fpc_foot(az)) rotate(fpc_ang(az)) {
      translate([0, -0.5, 1.5]) cube([fpc_w, 0.1, 0.1], center = true);
      translate([0, 1.5, 1]) cube([fpc_w, 0.1, 0.1], center = true);
    }
  }
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
    for (az = sensor_az_) hull() { at_ball(az, sensor_el_) sensor_pod_outer(); rim_patch(az, pcb_h); }
    elec_pod_blob();
  }
}

module ball_cuts() {
  translate([0, 0, zc]) sphere(r = R + ball_clear, $fn = 128);
  translate([0, 0, -1]) cylinder(r = bottom_hole_r, h = zc);
}

module body() {
  difference() {
    body_outer();
    ball_cuts();
    translate([-100, -100, -50]) cube([200, 200, 50 + floor_z + base_cover_t]);     // flat bottom, over the cover
    for (az = sensor_az_) at_ball(az, sensor_el_) sensor_cavity(pcb_screw_side * sign(az));
    elec_cavity();
    base_cuts();
    for (az = support_az) support_hole(az);
  }
}

// ---------- visual-only parts ----------

module supports() {
  for (az = support_az) color("white")
    at_ball(az, support_polar - 90) translate([0, 0, support_d / 2]) sphere(d = support_d, $fn = 24);
}

// sensor board with its ear on side s, and the FPC connector on the other
module sensor_board(s) {
  color("darkgreen") translate([sc, 0, pcb_top_z - pcb_t])
    linear_extrude(pcb_t) difference() {
      pcb_outline(s);
      translate([0, s * pcb_screw_y]) circle(d = 2.2, $fn = 16);
    }
  color("ivory") translate([fpc_x - fpc_conn.x / 2, s > 0 ? -pcb_h / 2 : pcb_h / 2 - fpc_conn.y, pcb_top_z]) cube(fpc_conn);
  color("#222") translate([sc - 16.2 / 2, -10.9 / 2, pcb_top_z]) cube([16.2, 10.9, 2.5]);
  color("lightblue", 0.8) translate([sc - lens_w / 2 + 0.5, -lens_h / 2 + 0.5, lens_ref_z])
    cube([lens_w - 1, lens_h - 1, pcb_top_z - pcb_t - lens_ref_z]);
  color("lightblue", 0.8) translate([0, 0, lens_ref_z - 1]) cylinder(d = 5, h = 1);
}

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
    translate([0.3, (elec_size.y - batt.y) / 2, xiao.z + xiao_pads + batt_gap]) lipo();
  }
}

// pouch cell in [0, batt]: the pouch, then the taped protection board at the
// +x end with its two leads, folded down to the XIAO's back
module lipo() {
  color("silver") translate([(batt.x - batt_pcm) / 2, batt.y / 2, batt.z / 2]) rbox([batt.x - batt_pcm, batt.y, batt.z], 1.2);
  color("gold") translate([batt.x - batt_pcm / 2 - 0.1, batt.y / 2, batt.z / 2])
    rbox([batt_pcm + 0.2, batt.y - 2, batt.z * 0.75], 0.6);
  for (s = [-1, 1]) color(s < 0 ? "black" : "red")
    translate([batt.x + 0.5, batt.y / 2 + s * 2, 0]) tube([[-0.7, 0, batt.z / 2], [0, 0, batt.z / 2 - 0.5], [0, 0, -batt_gap]], 0.8);
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
  cut(c) for (az = sensor_az_) at_ball(az, sensor_el_) sensor_board(pcb_screw_side * sign(az));
  cut(c) electronics(!c);
}

// screw shank along -z from z=0, head at z=0
module screw(l, head_d = 3.8) {
  color("dimgray") {
    translate([0, 0, -l]) cylinder(d = 2, h = l, $fn = 16);
    cylinder(d = head_d, h = 1.2, $fn = 24);
  }
}

// every part pulled apart along the way it goes in: the ball and support
// balls up, the sensor boards in towards the ball, the base PCB (with the
// XIAO and battery on it) down out of the case, the cover below that, and
// the screws below it
module exploded(d = 25) {
  color("#d8d4cc") body();
  color("firebrick") translate([0, 0, zc + 2.2 * d]) sphere(r = R, $fn = 128);
  translate([0, 0, d]) supports();
  for (az = sensor_az_) at_ball(az, sensor_el_) translate([0, 0, -0.8 * d]) sensor_board(pcb_screw_side * sign(az));
  translate([0, 0, -d]) {
    electronics();
    base_pcb();
    base_fpc_conns();
  }
  translate([0, 0, -1.8 * d]) color("#b8b4ac") base_cover();
  for (p = base_screws) translate([p.x, p.y, floor_z - 1.8 * d - 4]) rotate([180, 0, 0]) screw(8);
}

// ball, sensor boards and electronics only, over a translucent table
module hardware() {
  color("firebrick") translate([0, 0, zc]) sphere(r = R, $fn = 128);
  for (az = sensor_az_) at_ball(az, sensor_el_) sensor_board(pcb_screw_side * sign(az));
  electronics();
  base_pcb();
  base_fpc_conns();
  ribbons();
  color("#8a9", 0.25) translate([-60, -60, -1]) cube([120, 120, 1]);
}

if (part == "assembly") assembly();
else if (part == "exploded") exploded();
else if (part == "hardware") hardware();
else if (part == "section") assembly(true);
else if (part == "body") body();
else if (part == "base_cover") base_cover();
else if (part == "base_pcb") base_pcb_2d();

echo(str("ball top z = ", zc + R, "  sensor el = ", sensor_el_, "  sensor az = ", sensor_az_,
          "  elec pod top z = ", at_elec_pt([0, 0, -elec_floor + elec_box.z / 2]).z + elec_dome_r.z,
          "  front y = ", at_elec_pt([elec_size.x / 2 + elec_dome_back, 0, 0]).y - elec_dome_r.x));
// for laying out the base PCB (world x/y, mm; table at z=0)
echo(str("base PCB: XIAO board corner at USB end, left = ", at_elec_pt([0.3 + usb_overhang, (elec_size.y + xiao.y) / 2, 0]),
         "  screws = ", base_screws,
         "  FPC connectors (centre of foot, long axis angle) = ", [for (az = sensor_az_) [fpc_foot(az), fpc_ang(az)]]));
