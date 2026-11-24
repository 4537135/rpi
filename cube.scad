// Cube case: a rounded tube with a see-through front, a 40 mm fan in the back and the
// Pi 5 + X1001 on a sled that slides in from the back. Modelled on the ElectroCookie cube.
//
//   openscad -D 'part="shell"' -o cube-shell.stl cube.scad
//
// Print orientation (all exported that way, no supports):
//   shell   front end down         front / back   outer face down
//   sled    flat                   window_2d      SVG for a 3 mm laser-cut acrylic front
//
// Frame: X = width seen from the front, Y = depth (tube front at 0), Z = up.
include <pi5.scad>

/* [Build] */
part = "assembly";   // [assembly, shell, front, back, sled, window_2d]
explode = 0;

/* [Size] */
W = 106;             // tube width
H = 106;             // tube height
L = 82;              // tube depth; the front and back panels add pt each
wall = 3;
R = 12;
pt = 3;              // panel thickness: print the front in clear PETG, or laser-cut acrylic
fan = 40;            // back fan, 0 for none

/* [Pi 5 + X1001] */
hs_bottom = 6;       // heatsink room under the Pi
hat_standoff = 16;

$fn = 48;
FONT = "Liberation Sans:style=Bold";

sled_t = 3;
CI = 7.5;                                                   // corner column inset
COLS = [[CI, CI], [W - CI, CI], [CI, H - CI], [W - CI, H - CI]];
SLED = [CI + 4.3, W - CI - 4.3];                            // the sled runs between the bottom columns
X0 = wall + 0.5 + PI5_W + PI5_OVERHANG;                     // Pi x=0; USB/LAN stop 0.5 mm short of the wall so the sled slides
Y0 = L - 0.5;                                               // micro-HDMI edge against the back panel
Z0 = wall + sled_t + hs_bottom;                             // Pi PCB underside
FAN_C = [W / 2, H - wall - 6 - fan / 2];

assert(Z0 > CI + 4, "Pi would hit the bottom corner columns");
assert(X0 + 2.5 < W - CI - 4, "microSD would hit the right corner column");
assert(X0 - PI5_HOLES[0][0] < SLED[1] - 3, "sled too narrow for the Pi standoffs");

module ext(y0, y1) translate([0, y1, 0]) rotate([90, 0, 0]) linear_extrude(y1 - y0) children();
module rr(x, z, w, h, r) translate([x, z]) pi5_rr(w, h, r);
module outline(i = 0) rr(i, i, W - 2 * i, H - 2 * i, R - i);
module pi_place() translate([X0, Y0, Z0]) rotate([0, 0, 180]) children();   // USB/LAN left, power/HDMI back, GPIO to the window

module shell() difference() {
  hull() { ext(0, 0.01) outline(1); ext(1, L - 1) outline(); ext(L - 0.01, L) outline(1); }
  ext(-1, L + 1) difference() { outline(wall); for (c = COLS) translate(c) circle(d = 9); }
  for (c = COLS, y = [-1, L - 7]) ext(y, y + 8) translate(c) circle(d = 4);     // M3 heat-set inserts, both ends
  pi_place() pi5_cut_right(10);
  translate([0, 0, H - wall - 1]) linear_extrude(wall + 2)                       // top vents
    for (x = [W * 0.3 : 5 : W * 0.7]) rr(x, 14, 2.4, L - 28, 1.2);
  for (x = [16, W - 16], y = [12, L - 12]) translate([x, y, -1]) cylinder(d = 10.5, h = 2);   // bumpon feet
  for (p = [[PI5_LAN, "LAN"], [PI5_USB[0], "USB"], [PI5_USB[1], "USB"]])
    translate([-0.4, Y0 - p[0], Z0 + 23]) multmatrix([[0, 0, 1, 0], [-1, 0, 0, 0], [0, 1, 0, 0]])
      linear_extrude(1) text(p[1], size = 3, font = FONT, halign = "center", valign = "center");
}

module front2d() difference() {
  outline();
  for (c = COLS) translate(c) circle(d = 3.4);
  rr(W * 0.3, H - 15, W * 0.4, 4.5, 2.25);    // vent slot
}

module front() difference() {
  hull() { ext(-pt, -pt + 0.01) outline(0.8); ext(-pt + 0.8, 0) outline(); }
  ext(-pt - 1, 1) difference() { outline(-1); front2d(); }
}

module back() difference() {
  hull() { ext(L, L + pt - 0.8) outline(); ext(L + pt - 0.01, L + pt) outline(0.8); }
  ext(L - 1, L + pt + 1) for (c = COLS) translate(c) circle(d = 3.4);
  pi_place() pi5_cut_bottom(10);
  if (fan > 0) ext(L - 1, L + pt + 1) translate(FAN_C) {
    difference() {
      circle(d = fan - 2);
      circle(d = fan * 0.32);
      for (a = [0 : 60 : 359]) rotate(a) translate([fan * 0.1, -1.2]) square([fan, 2.4]);   // swept spokes
    }
    for (i = [-1, 1], j = [-1, 1]) translate([i, j] * fan * 0.4) circle(d = 3.4);
  }
  ext(L + pt - 0.6, L + pt + 1) for (p = [[PI5_USBC, "5V"], [PI5_HDMI[0], "HDMI0"], [PI5_HDMI[1], "HDMI1"]])
    translate([X0 - p[0], Z0 + 12]) mirror([1, 0, 0]) text(p[1], size = 2.6, font = FONT, halign = "center", valign = "center");
}

module sled() difference() {
  union() {
    translate([SLED[0], 0.3, wall]) cube([SLED[1] - SLED[0], L - 0.6, sled_t]);
    pi_place() for (h = PI5_HOLES) translate([h[0], h[1], -hs_bottom]) cylinder(d = 6.5, h = hs_bottom);
  }
  // M2.5 from below through the Pi into the X1001 brass standoffs
  pi_place() for (h = PI5_HOLES) {
    translate([h[0], h[1], -20]) cylinder(d = 2.7, h = 30);
    translate([h[0], h[1], -hs_bottom - sled_t - 1]) cylinder(d = 5.2, h = 2.5);
  }
}

module assembly() {
  color("#d5d8dc") shell();
  color("#c4c7cb") translate([0, explode, 0]) back();
  color("#2a2c30") translate([0, explode * 0.5, 0]) sled();
  translate([0, explode * 0.5, 0]) pi_place() pi5_dummy(hat_standoff);
  if (fan > 0) translate([FAN_C[0], L + explode, FAN_C[1]]) rotate([90, 0, 0]) fan_dummy(fan);
  color([0.1, 0.1, 0.13, 0.4]) translate([0, -explode, 0]) front();   // last: the preview only shows what is drawn before a transparent part
}

if (part == "shell") rotate([90, 0, 0]) shell();
else if (part == "front") translate([0, 0, pt]) rotate([90, 0, 0]) front();
else if (part == "back") translate([0, 0, L + pt]) rotate([-90, 0, 0]) back();
else if (part == "sled") translate([0, 0, -wall]) sled();
else if (part == "window_2d") front2d();
else assembly();
