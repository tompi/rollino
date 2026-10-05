// Rollino - low-profile finger trackball
//
// Ball floats `ball_gap` above the table on three ceramic support balls.
// Two PMW3610 sensors sit in pods at the back-left/back-right, looking up at
// the ball from as low as they fit; their azimuths are chosen so the lines of sight are
// ~90 deg apart, so X, Y and twist are all observable.
// A nice!nano + LiPo stand in a pod at the front, USB-C pointing up,
// pushed down to the table and in against the ball.
//
// Coordinates: table is z=0, front (towards the user) is -y.
// Azimuths are measured from the front, positive towards +x.

/* [View] */
// assembly | section | hardware | body | elec_lid
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
// the PCB is screwed straight onto the pod through two ears beyond the lens'
// long sides; pilot hole for an M2 self-tapping (plastite) screw
pcb_screw_d = 1.8;
// hole centres, either side of the optical axis (tangential)
pcb_screw_y = lens_h / 2 + 2.2;
// hole depth below the PCB's underside
pcb_screw_depth = 5;
pcb_ear_d = 5;

/* [Electronics pod] */
// lean of the pod from vertical, top away from the ball; it is then pushed
// down to floor_z and in against the ball
elec_tilt = 45;
// LiPo cell, e.g. 402030 (~200 mAh): [length, width, thickness]
batt = [30, 20, 4];
// nice!nano (33.3 x 18) on top of the battery; x runs from the USB end down
elec_size = [34.5, max(18, batt.y) + 0.6, batt.z + 5.8];
// nice!nano PCB underside, and USB-C receptacle centre, above the pod floor
nano_z = batt.z + 0.8;
usb_z = nano_z + 1.2 + 1.6;
// pod thickness away from the USB end: battery + nano + low components
elec_thin = nano_z + 1.2 + 1.2;
// length of the full-height USB-C zone at the top end
usb_zone = 9.5;
// lowest point of any pod above the table
floor_z = 0;

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

// Electronics pod frame: x runs from the top (USB) end down the board,
// y is horizontal, z points away from the ball (battery at z=0, nano outside).
// It lives in the vertical plane at azimuth 0; u is the distance in front of
// the ball's axis.
et = elec_tilt;
elec_L = elec_size.x + wall;
// the bottom end only needs the thin part of the pod
elec_T = elec_thin + wall;
// height of the frame origin so the lowest bottom corner sits on floor_z
elec_zo = floor_z + elec_L * cos(et) + max(-wall * sin(et), elec_T * sin(et));
function elec_uz(o, p) = [o - p.x * sin(et) + p.z * cos(et), elec_zo - p.x * cos(et) - p.z * sin(et)];
// slide in until the inner face touches the ball clearance
elec_uo = min([for (o = [0 : 0.1 : 120])
  if (seg_dist([0, zc], elec_uz(o, [-wall, 0, -wall]), elec_uz(o, [elec_L, 0, -wall])) >= R + ball_clear) o]);
elec_m = [[0, 1, 0, -elec_size.y / 2],
          [sin(et), 0, -cos(et), -elec_uo],
          [-cos(et), 0, -sin(et), elec_zo]];

module at_elec() { multmatrix(elec_m) children(); }

function at_elec_pt(p) = elec_m * [p.x, p.y, p.z, 1];

// ---------- sensor pod ----------

// In the at_ball frame the optical axis is x=y=0; the package, lens and PCB
// are centred at x=sc, i.e. shifted up-slope so the low edge is short.
sc = -sensor_optical_offset;
sp_in = [pcb_w + 0.6, pcb_h + 0.6];

// PCB outline: rounded rectangle with a screw ear on each long side,
// grown by m all round
module pcb_outline(m = 0) {
  hull() {
    rrect([pcb_w + 2 * m, pcb_h + 2 * m], pcb_r + m);
    for (s = [-1, 1]) translate([0, s * pcb_screw_y]) circle(d = pcb_ear_d + 2 * m);
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

// PCB goes in from outside, through an opening the size of the PCB, and
// is screwed down onto the ledge around the lens; its back stays exposed
module sensor_opening() {
  translate([sc, 0, pcb_top_z - pcb_t]) linear_extrude(30) pcb_outline(0.3);
}

module sensor_cavity() {
  translate([sc - lens_w / 2, -lens_h / 2, -2]) cube([lens_w, lens_h, pcb_top_z - pcb_t + 2 + eps]);
  sensor_opening();
  for (s = [-1, 1]) translate([sc, s * pcb_screw_y, pcb_top_z - pcb_t - pcb_screw_depth])
    cylinder(d = pcb_screw_d, h = pcb_screw_depth + eps, $fn = 16);
}

// blends the pods into the rim; entirely inside the rim's footprint, so its
// rounding only softens the hull with the pod
module rim_patch(az, w) {
  rotate([0, 0, az - 90]) translate([R - 4 + (rim_wall + 4) / 2, 0, (rim_h - 2) / 2])
    rbox([rim_wall + 4, w, rim_h + 2], shell_r);
}

// ---------- electronics pod ----------

// [x0, x1, y half-width, z0, z1] in the elec frame (y centred on elec_size.y / 2):
// battery + nano over the full length, full height only around the USB-C
elec_zones = [
  [0, elec_size.x, elec_size.y / 2, 0, elec_thin],
  [0, usb_zone, elec_size.y / 2, 0, elec_size.z]];

module elec_pod_shell() {
  at_elec() translate([0, elec_size.y / 2, 0]) zone_ellipsoid(bbox_zone(elec_zones), wall);
}

// the ellipsoid itself is inflated enough in z (bump_k.z) that it dips
// well below the table over a real area, not just a single tangent point;
// body()'s existing flat-bottom cut then slices that into a flush base —
// simple plane/solid clipping, none of the sliver artifacts a hull() or
// union() with a near-degenerate helper shape can trigger in CGAL
module elec_pod_outer() { elec_pod_shell(); }

// battery and nano go in from outside, through an opening the size of the pod
module elec_opening() { cube([elec_size.x, elec_size.y, 30]); }

module elec_cavity() {
  at_elec() {
    elec_opening();
    // USB-C on the top (x=0) end, nano sits outside the battery
    translate([1, elec_size.y / 2, usb_z]) rotate([0, -90, 0])
      hull() for (d = [-3, 3]) translate([0, d, 0]) cylinder(d = 3.8, h = wall + 2);
  }
}

// lid fills the opening down to the top of the nano's components, clearing the USB-C zone
module elec_lid() {
  difference() {
    intersection() { elec_pod_outer(); at_elec() elec_opening(); }
    at_elec() {
      translate([-50, -50, -50]) cube([200, 200, 50 + elec_thin]);
      translate([0, elec_size.y / 2, 0]) zone(elec_zones[1], 0.15);
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

ch_d = 4;
ch_r = R + rim_wall - 2.5;
ch_z = rim_h - 3;

module wire_channel(az) {
  sgn = az > 0 ? 1 : -1;
  arc = [for (a = [az : -sgn * 10 : sgn * 25]) polar_pt(a, ch_r, ch_z)];
  pts = concat(
    [at_ball_pt(az, sensor_el_, [sc + pcb_w / 2 - 2, 0, pcb_top_z])],
    arc,
    [at_elec_pt([elec_size.x - 4, elec_size.y / 2 + sgn * 6, 2])]);
  tube(pts, ch_d);
}

module support_hole(az) {
  at_ball(az, support_polar - 90) translate([0, 0, -1]) cylinder(d = support_d, h = support_d + 1);
}

module body() {
  difference() {
    union() {
      rim();
      for (az = sensor_az_) hull() { at_ball(az, sensor_el_) sensor_pod_outer(); rim_patch(az, pcb_h); }
      hull() { elec_pod_outer(); rim_patch(0, elec_size.y + 2 * wall); }
    }
    translate([0, 0, zc]) sphere(r = R + ball_clear, $fn = 128);
    translate([0, 0, -1]) cylinder(r = bottom_hole_r, h = zc);
    translate([-100, -100, -50]) cube([200, 200, 50]);     // flat bottom
    for (az = sensor_az_) at_ball(az, sensor_el_) sensor_cavity();
    elec_cavity();
    for (az = sensor_az_) wire_channel(az);
    for (az = support_az) support_hole(az);
  }
}

// ---------- visual-only parts ----------

module supports() {
  for (az = support_az) color("white")
    at_ball(az, support_polar - 90) translate([0, 0, support_d / 2]) sphere(d = support_d, $fn = 24);
}

module sensor_board() {
  color("darkgreen") translate([sc, 0, pcb_top_z - pcb_t])
    linear_extrude(pcb_t) difference() {
      pcb_outline();
      for (s = [-1, 1]) translate([0, s * pcb_screw_y]) circle(d = 2.2, $fn = 16);
    }
  color("#222") translate([sc - 16.2 / 2, -10.9 / 2, pcb_top_z]) cube([16.2, 10.9, 2.5]);
  color("lightblue", 0.8) translate([sc - lens_w / 2 + 0.5, -lens_h / 2 + 0.5, lens_ref_z])
    cube([lens_w - 1, lens_h - 1, pcb_top_z - pcb_t - lens_ref_z]);
  color("lightblue", 0.8) translate([0, 0, lens_ref_z - 1]) cylinder(d = 5, h = 1);
}

module electronics() {
  at_elec() {
    color("silver") translate([elec_size.x - batt.x - 0.3, (elec_size.y - batt.y) / 2, 0.2]) cube(batt);
    color("royalblue") translate([(elec_size.x - 33.3) / 2, (elec_size.y - 18) / 2, nano_z]) cube([33.3, 18, 1.2]);
    color("gray") translate([0.4, elec_size.y / 2 - 4.5, nano_z + 1.2]) cube([7.5, 9, 3.2]);
  }
}

// cut = true removes everything on one side of the vertical plane at section_az;
// each part is rendered separately so it keeps its colour
module cut(c) {
  if (c) render() difference() {
    children();
    rotate([0, 0, section_az - 90]) translate([-100, eps, -50]) cube([200, 100, 200]);
  }
  else children();
}

module assembly(c = false) {
  color("#d8d4cc") cut(c) body();
  color("#b8b4ac") cut(c) elec_lid();
  color("firebrick") cut(c) translate([0, 0, zc]) sphere(r = R, $fn = 128);
  cut(c) supports();
  cut(c) for (az = sensor_az_) at_ball(az, sensor_el_) sensor_board();
  cut(c) electronics();
}

// ball, sensor boards and electronics only, over a translucent table
module hardware() {
  color("firebrick") translate([0, 0, zc]) sphere(r = R, $fn = 128);
  for (az = sensor_az_) at_ball(az, sensor_el_) sensor_board();
  electronics();
  color("#8a9", 0.25) translate([-60, -60, -1]) cube([120, 120, 1]);
}

if (part == "assembly") assembly();
else if (part == "hardware") hardware();
else if (part == "section") assembly(true);
else if (part == "body") body();
else if (part == "elec_lid") elec_lid();

echo(str("ball top z = ", zc + R, "  sensor el = ", sensor_el_, "  sensor az = ", sensor_az_,
          "  elec pod top z = ", at_elec_pt([-wall, 0, elec_T]).z, " front u = ", elec_uo));
