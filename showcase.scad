// Showcase case: printed frame, clear front and right panels, the Pi 5 on display.
// Modelled on the "glass box" desk builds: solid left and back walls carry the ports.
//
//   openscad -D 'part="base"' -o showcase-base.stl showcase.scad
//
// Print orientation (all exported that way, no supports):
//   base   floor down             top   top face down
//   panel_front / panel_side      SVG outlines for 2 mm acrylic (or print in clear PETG)
//
// Frame: X = width seen from the front, Y = depth (front at 0), Z = up.
include <pi5.scad>

/* [Build] */
part = "assembly";   // [assembly, base, top, panel_front, panel_side]
explode = 0;

/* [Size] */
W = 108;             // outside width
D = 86;              // outside depth
H = 100;             // outside height
wall = 4;            // printed left / back walls
post = 10;           // corner posts
fl = 5;              // floor
lid = 6;
pt = 2;              // panel thickness
gd = 2.5;            // panel groove depth in the posts
fan = 40;            // lid fan, 0 for none

/* [Pi 5 + X1001] */
hs_bottom = 6;
hat_standoff = 16;

$fn = 48;
FONT = "Liberation Sans:style=Bold";

g = pt + 0.4;                              // groove width
PI = 4;                                    // panel centre plane, from the outer face
Hw = H - lid;                              // wall / post height
X0 = wall - 1 + PI5_W + PI5_OVERHANG;      // Pi x=0; USB/LAN fronts 1 mm into the left wall
Y0 = D - wall + 0.5;                       // micro-HDMI edge into the back wall
Z0 = fl + hs_bottom;
POSTS = [[0, 0], [W - post, 0], [W - post, D - post], [0, D - post]];
SCREWS = [for (p = POSTS) p + [post / 2, post / 2]];
CPU = [X0 - 35, Y0 - 30];                  // fan sits over the SoC
// panel sizes: [width, height]
PANEL_F = [W - 2 * post + 2 * gd - 0.6, Hw - fl + 3 - 0.6];
PANEL_S = [D - 2 * post + 2 * gd - 0.6, PANEL_F[1]];

assert(X0 + 2.5 < W - PI - g / 2 - 1, "microSD would hit the side panel");
assert(Y0 - PI5_D > PI + g / 2 + 5, "Pi too close to the front panel");

module rr(x, y, w, h, r) translate([x, y]) pi5_rr(w, h, r);
module pi_place() translate([X0, Y0, Z0]) rotate([0, 0, 180]) children();   // USB/LAN left, power/HDMI back, GPIO to the front glass
module grooves() {   // 1.5 mm into the floor and the lid, gd into the posts
  translate([post - gd, PI - g / 2, fl - 1.5]) cube([W - 2 * post + 2 * gd, g, Hw - fl + 3]);
  translate([W - PI - g / 2, post - gd, fl - 1.5]) cube([g, D - 2 * post + 2 * gd, Hw - fl + 3]);
}

module base() difference() {
  union() {
    hull() { translate([1, 1, 0]) linear_extrude(1) rr(0, 0, W - 2, D - 2, 3); translate([0, 0, 1]) linear_extrude(fl - 1) rr(0, 0, W, D, 4); }
    cube([wall, D, Hw]);
    translate([0, D - wall, 0]) cube([W, wall, Hw]);
    for (p = POSTS) translate(p) linear_extrude(Hw) rr(0, 0, post, post, 1.5);
    pi_place() for (h = PI5_HOLES) translate([h[0], h[1], -hs_bottom]) cylinder(d = 6.5, h = hs_bottom + 0.1);
  }
  grooves();
  for (s = SCREWS) translate([s[0], s[1], Hw - 7]) cylinder(d = 4, h = 8);     // M3 heat-set inserts for the lid
  pi_place() {
    pi5_cut_right(10);
    pi5_cut_bottom(10);
    for (h = PI5_HOLES) {                                                    // M2.5 from below into the X1001 brass standoffs
      translate([h[0], h[1], -20]) cylinder(d = 2.7, h = 30);
      translate([h[0], h[1], -Z0 - 1]) cylinder(d = 5.2, h = 2.5);
    }
  }
  for (z = [Hw * 0.45 : 6 : Hw - 10]) translate([W * 0.25, D - wall - 1, z]) rotate([-90, 0, 0])   // back wall vents
    linear_extrude(wall + 2) rr(0, 0, W * 0.5, 2.6, 1.3);
  for (x = [12, W - 12], y = [12, D - 12]) translate([x, y, -1]) cylinder(d = 10.5, h = 2);         // bumpon feet
  for (p = [[PI5_LAN, "LAN"], [PI5_USB[0], "USB"], [PI5_USB[1], "USB"]])
    translate([-0.4, Y0 - p[0], Z0 + 23]) multmatrix([[0, 0, 1, 0], [-1, 0, 0, 0], [0, 1, 0, 0]])
      linear_extrude(1) text(p[1], size = 3, font = FONT, halign = "center", valign = "center");
  for (p = [[PI5_USBC, "5V"], [PI5_HDMI[0], "HDMI0"], [PI5_HDMI[1], "HDMI1"]])
    translate([X0 - p[0], D + 0.4, Z0 + 12]) rotate([90, 0, 0]) mirror([1, 0, 0])
      linear_extrude(1) text(p[1], size = 2.6, font = FONT, halign = "center", valign = "center");
}

module top() difference() {
  hull() { translate([0, 0, Hw]) linear_extrude(lid - 1) rr(0, 0, W, D, 4); translate([0, 0, H - 1]) linear_extrude(1) rr(1, 1, W - 2, D - 2, 3); }
  grooves();
  for (s = SCREWS) translate([s[0], s[1], Hw - 1]) { cylinder(d = 3.4, h = lid + 2); translate([0, 0, lid - 2.5]) cylinder(d = 6.5, h = 5); }
  if (fan > 0) translate([CPU[0], CPU[1], Hw - 1]) {
    linear_extrude(lid + 2) difference() {
      circle(d = fan - 2);
      circle(d = fan * 0.32);
      for (a = [0 : 60 : 359]) rotate(a) translate([fan * 0.1, -1.2]) square([fan, 2.4]);
    }
    for (i = [-1, 1], j = [-1, 1]) translate([i * fan * 0.4, j * fan * 0.4, 0]) cylinder(d = 3.4, h = lid + 2);
  }
  translate([W / 2, 12, H - 0.6]) linear_extrude(1) text("pi 5", size = 6, font = FONT, halign = "center", valign = "center");
}

module panel(s) pi5_rr(s[0], s[1], 1);

module assembly() {
  color("#26282c") base();
  translate([0, 0, explode]) color("#26282c") top();
  color("#2b2d31") pi_place() pi5_dummy(hat_standoff);
  if (fan > 0) translate([CPU[0], CPU[1], Hw - 10 + explode]) fan_dummy(fan);
  color([0.75, 0.9, 0.95, 0.25]) {   // glass last: the preview only shows what is drawn before a transparent part
    translate([post - gd + 0.3, PI + pt / 2 - explode, fl - 1.2]) rotate([90, 0, 0]) linear_extrude(pt) panel(PANEL_F);
    translate([W - PI + pt / 2 + explode, post - gd + 0.3 + PANEL_S[0], fl - 1.2]) rotate([90, 0, -90]) linear_extrude(pt) panel(PANEL_S);
  }
}

if (part == "base") base();
else if (part == "top") translate([0, 0, H]) rotate([180, 0, 0]) top();
else if (part == "panel_front") panel(PANEL_F);
else if (part == "panel_side") panel(PANEL_S);
else assembly();
