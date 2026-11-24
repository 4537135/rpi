// Cyberdeck: rugged clamshell. The lid carries the 7" screen with the Pi 5 + X1001 beside it,
// the base is a tray for your own USB keyboard under a deck plate. Pin hinge, magnet closure,
// bolt-on carry handle.
//
//   openscad -D 'part="lid"' -o deck-lid.stl deck.scad
//
// Print orientation (all exported that way, no supports):
//   base, lid        outside face down          bezel   visible face down
//   plate, handle    flat                       hinge_pin   lying, flat underside
// Bed: 256 x 256 (Bambu X1 / P1 class). Shrink W / D for smaller printers.
//
// Base frame: X right, Y from the front edge (0) to the hinge, Z up.
// Lid frame:  x right, v from the hinge edge (0) to the top edge, w from the outside (0) to the rim.
include <pi5.scad>

/* [Build] */
part = "assembly";   // [assembly, base, plate, lid, bezel, handle, hinge_pin]
open_angle = 105;    // 0 = closed

/* [Size] */
W = 246;             // footprint, both halves
D = 165;
Hb = 38;             // base depth: keyboards up to Hb - 5 tall fit
Hl = 37;             // lid depth
wall = 3;
R = 10;
e = 6;               // hinge axis sits this far behind the back walls
kb = [230, 96];      // keyboard opening in the deck plate

/* [Pi 5 + X1001] */
hs_bottom = 6;
hat_standoff = 16;
hat_stack = 6;

$fn = 48;
FONT = "Liberation Sans:style=Bold";

// ELECROW 7" 1024x600, mounted upside down so its HDMI/USB face the Pi (set display rotation 180 in the OS)
gw = 164.9; gh = 100; gt = 6.5; pw = 164.7; ph = 107.1; pb = 10;
aw = 154.21; ah = 85.92; ax = 5.34; ay = 4.4;     // active area offsets after the 180° turn

bz0 = Hl - 3.5;                                  // bezel underside
glass = [W - wall - 4 - gw, (D - gh) / 2];       // glass bottom-left (x, v)
X0 = wall + 57;  V0 = D - wall - 87;  W0 = wall + hs_bottom;   // Pi: HDMI edge faces the screen, USB/LAN the top edge
LC = [[9, 9], [W - 9, 9], [W - 9, D - 9], [X0 + 6, D - 9]];    // lid bezel screws
BC = [[9, 9], [W - 9, 9], [9, D - 9], [W - 9, D - 9]];         // deck plate screws
MAG = [W * 0.36, W * 0.64];                                    // 6 x 3 mm magnets, x positions
HANDLE = [W / 2 - 48, W / 2 + 48];
BK = [[12, 50], [104, 142], [196, 234]];                       // base knuckles (x ranges)
LK = [[52, 102], [144, 194]];                                  // lid knuckles

assert(W0 + PI5_PCB + hat_standoff + hat_stack < bz0 - 0.5, "Pi stack hits the bezel, raise Hl");
assert(bz0 - gt - pb > wall, "screen does not fit, raise Hl");
assert(glass[0] - X0 > 12, "no room for the HDMI link between Pi and screen");

module rr(x, y, w, h, r) translate([x, y]) pi5_rr(w, h, r);
module outline(i = 0) rr(i, i, W - 2 * i, D - 2 * i, R - i);
module pi_place() translate([X0, V0, W0]) rotate([0, 0, 90]) children();
module hexgrid(p = 7, d = 6)
  for (i = [-1 : W / p + 1], j = [0 : D / (p * 0.866) + 1])
    translate([i * p + (j % 2) * p / 2, j * p * 0.866]) rotate(30) circle(d = d, $fn = 6);

// Rugged half-shell: chamfered outside face, a raised band near the rim, hollow.
module half(h) difference() {
  union() {
    hull() { linear_extrude(0.01) outline(1.5); translate([0, 0, 1.5]) linear_extrude(h - 1.5) outline(); }
    hull() { translate([0, 0, h - 10.2]) linear_extrude(0.01) outline(); translate([0, 0, h - 9]) linear_extrude(7) outline(-1.2); }
  }
  translate([0, 0, wall]) linear_extrude(h) outline(wall);
}

// Knuckles along x at (axis_y, axis_z); `dir` = +1 when the wall face is at y = face and the axis behind it.
module knuckles(segs, face, dir, axis_z) {
  for (s = segs) translate([s[0], 0, 0]) rotate([90, 0, 90]) linear_extrude(s[1] - s[0])
    hull() {
      translate([face + dir * e, axis_z]) circle(d = 10);
      translate([dir > 0 ? face - 0.5 : face, axis_z - 12]) square([0.5, 6]);
    }
}

module base() difference() {
  union() {
    half(Hb);
    intersection() {
      linear_extrude(Hb) outline(0.5);
      union() {
        for (c = BC) translate([c[0], c[1], 0]) cylinder(d = 10, h = Hb - 4);
        for (x = MAG) translate([x, 5, 0]) cylinder(d = 10, h = Hb);
      }
    }
    knuckles(BK, D, 1, Hb);
  }
  translate([0, D + e, Hb]) rotate([0, 90, 0]) cylinder(d = 4.2, h = W + 2, center = false);   // hinge pin
  for (c = BC) translate([c[0], c[1], Hb - 11]) cylinder(d = 4, h = 8);        // M3 inserts for the deck plate
  for (x = MAG) translate([x, 5, Hb - 3.2]) cylinder(d = 6.2, h = 4);          // magnets
  translate([W / 2, -1, Hb]) rotate([-90, 0, 0]) scale([1, 0.35, 1]) cylinder(d = 50, h = wall + 2);   // finger scoop
  for (x = [16, W - 16], y = [16, D - 16]) translate([x, y, -1]) cylinder(d = 10.5, h = 2);           // bumpon feet
  for (y = [D * 0.3, D * 0.7]) translate([20, y - 3, -1]) cube([W - 40, 6, 1.6]);                  // skid grooves
}

module plate2d() difference() {
  rr(wall + 0.3, wall + 0.3, W - 2 * wall - 0.6, D - 2 * wall - 0.6, R - wall);
  for (x = MAG) translate([x, 5]) circle(d = 10.8);
  rr((W - kb[0]) / 2, wall + 8, kb[0], kb[1], 4);
  for (c = BC) translate(c) circle(d = 3.4);
  rr(W / 2 - 30, D - wall - 14, 60, 8, 4);   // cable slot to the lid
}
module plate() difference() {
  translate([0, 0, Hb - 4]) linear_extrude(3) plate2d();
  for (c = BC) translate([c[0], c[1], Hb - 2.5]) cylinder(d = 6.5, h = 3);
  translate([W - 14, D - wall - 20, Hb - 1.6]) linear_extrude(1) text("DUMB PC", size = 6, font = FONT, halign = "right", valign = "center");
}

module lid() difference() {
  union() {
    half(Hl);
    intersection() {
      linear_extrude(Hl) outline(0.5);
      union() {
        for (c = LC) translate([c[0], c[1], 0]) cylinder(d = 9, h = bz0);
        for (x = MAG) translate([x, D - 5, 0]) cylinder(d = 10, h = Hl);
        for (x = HANDLE) translate([x - 5, D - wall - 9, 0]) cube([10, 9.5, Hl / 2 + 7]);
        pi_place() for (h = PI5_HOLES) translate([h[0], h[1], -hs_bottom]) cylinder(d = 6.5, h = hs_bottom + 0.1);
      }
    }
    mirror([0, 1, 0]) knuckles(LK, 0, 1, Hl);
  }
  translate([0, -e, Hl]) rotate([0, 90, 0]) cylinder(d = 4.2, h = W + 2);     // hinge pin
  for (c = LC) translate([c[0], c[1], bz0 - 7]) cylinder(d = 4, h = 8);       // M3 inserts for the bezel
  for (x = MAG) translate([x, D - 5, Hl - 3.2]) cylinder(d = 6.2, h = 4);
  for (x = HANDLE) translate([x, D + 1, Hl / 2]) rotate([90, 0, 0]) cylinder(d = 4, h = 10);   // M3 inserts for the handle
  pi_place() {
    pi5_cut_right(10);
    for (h = PI5_HOLES) {   // M2.5 from outside into the X1001 brass standoffs
      translate([h[0], h[1], -20]) cylinder(d = 2.7, h = 30);
      translate([h[0], h[1], -W0 - 1]) cylinder(d = 5.2, h = 2.5);
    }
  }
  translate([-1, 0, 0]) rotate([90, 0, 90]) linear_extrude(wall + 2) {     // panel-mount USB-C power, 28 mm screw ears
    rr(34, Hl / 2 - 5.25, 12, 6.5, 2);
    for (s = [-14, 14]) translate([40 + s, Hl / 2 - 2]) circle(d = 3.2);
  }
  translate([98, D - wall - 1, 10]) cube([14, wall + 2, 6]);                // pass-through for the touch USB cable
  translate([0, 0, -1]) linear_extrude(wall + 2) intersection() {          // vents under the Pi
    rr(X0 - 52, V0 + 8, 46, 72, 4);
    difference() { hexgrid(); for (h = PI5_HOLES) translate([X0 - h[1], V0 + h[0]]) circle(d = 11); }
  }
  for (v = [D * 0.22, D * 0.78]) translate([20, v - 3, -1]) cube([W - 40, 6, 1.6]);    // skid grooves
  translate([W / 2 + 30, D / 2, -1]) mirror([0, 1, 0]) linear_extrude(1.6)
    text("DUMB PC", size = 9, font = FONT, halign = "center", valign = "center");
  for (p = [[PI5_LAN, "LAN"], [PI5_USB[0], "USB"], [PI5_USB[1], "USB"]])
    translate([X0 - p[0], D + 0.4, 5]) multmatrix([[-1, 0, 0, 0], [0, 0, -1, 0], [0, 1, 0, 0]])
      linear_extrude(1) text(p[1], size = 3, font = FONT, halign = "center", valign = "center");
  translate([-0.4, 40, Hl / 2 + 6]) multmatrix([[0, 0, 1, 0], [-1, 0, 0, 0], [0, 1, 0, 0]])
    linear_extrude(1) text("5V", size = 3, font = FONT, halign = "center", valign = "center");
}

module window() rr(glass[0] + ax - 0.8, glass[1] + ay - 0.8, aw + 1.6, ah + 1.6, 1);
module bezel() difference() {
  translate([0, 0, bz0]) linear_extrude(3) difference() {
    rr(wall + 0.3, wall + 0.3, W - 2 * wall - 0.6, D - 2 * wall - 0.6, R - wall);
    for (x = MAG) translate([x, D - 5]) circle(d = 10.8);
    for (c = LC) translate(c) circle(d = 3.4);
    intersection() { rr(8, V0 + 6, X0 - 14, 80, 4); hexgrid(); }   // Pi grille
  }
  hull() { translate([0, 0, bz0 - 1]) linear_extrude(1 + 1.8) window(); translate([0, 0, Hl - 0.5]) linear_extrude(1) offset(delta = 1.2) window(); }
  for (c = LC) translate([c[0], c[1], Hl - 2]) cylinder(d = 6.5, h = 3);
  translate([14, 14, Hl - 1.1]) linear_extrude(1) text("pi 5 · nvme", size = 5, font = FONT, valign = "center");
}

module handle() difference() {   // x along the lid, y outwards from the top wall, z along w
  linear_extrude(14) offset(r = 3) offset(delta = -3) union() {
    for (s = [-1, 1]) translate([s * 48 - 5, 0]) square([10, 26]);
    translate([-60, 18]) square([120, 14]);
  }
  for (s = [-1, 1]) translate([s * 48, -1, 7]) rotate([-90, 0, 0]) {
    cylinder(d = 3.4, h = 40);
    translate([0, 0, 13]) cylinder(d = 6.5, h = 40);   // M3 x 16 into the lid inserts
  }
}

module hinge_pin() intersection() {   // or use a 4 mm steel rod, 226 mm
  union() {
    rotate([0, 90, 0]) cylinder(d = 3.9, h = BK[2][1] - BK[0][0] + 2);
    rotate([0, 90, 0]) translate([0, 0, -2]) cylinder(d = 8, h = 2);
  }
  translate([-5, -5, -1.6]) cube([300, 10, 10]);
}

module screen_dummy() {
  color("#0b0c0e") translate([glass[0], glass[1], bz0 - gt]) cube([gw, gh, gt]);
  color("#1b4f8a") translate([glass[0] + (gw - pw) / 2, glass[1] - (ph - gh) / 2, bz0 - gt - 1.6]) cube([pw, ph, 1.6]);
  n = 24;
  for (i = [0 : n - 1]) color(LED[floor(i / n * 6)])   // Win11-style bloom, roughly
    translate([glass[0] + ax + i * aw / n, glass[1] + ay, bz0 - 0.05]) cube([aw / n + 0.01, ah, 0.1]);
}

module keyboard_dummy() {
  color("#3a3c40") translate([(W - kb[0]) / 2 + 3, wall + 11, wall]) cube([kb[0] - 6, kb[1] - 6, 18]);
  for (r = [0 : 3], c = [0 : 11]) color(r == 3 && (c < 2 || c > 9) ? "#c9a227" : (r + c) % 7 == 0 ? "#e06c75" : "#e8e2d4")
    translate([(W - kb[0]) / 2 + 9 + c * 18.3, wall + 16 + (3 - r) * 21, wall + 18]) cube([16, 18, 8]);
}

module lid_all() {
  color("#c8b48f") lid();
  color("#35c46a") bezel();
  screen_dummy();
  pi_place() pi5_dummy(hat_standoff);
  color("#1f2023") translate([W / 2, D, Hl / 2 - 7]) handle();
}

if (part == "base") base();
else if (part == "plate") translate([0, 0, 4 - Hb]) plate();
else if (part == "lid") lid();
else if (part == "bezel") translate([0, 0, Hl - 0.5]) rotate([180, 0, 0]) bezel();
else if (part == "handle") handle();
else if (part == "hinge_pin") translate([0, 0, 1.6]) hinge_pin();
else {
  color("#c8b48f") base();
  color("#35c46a") plate();
  keyboard_dummy();
  color("#8a8f96") translate([BK[0][0], D + e, Hb]) rotate([0, 90, 0]) cylinder(d = 3.9, h = BK[2][1] - BK[0][0]);
  translate([0, D + e, Hb]) rotate([-open_angle, 0, 0]) rotate([180, 0, 0]) translate([0, e, -Hl]) lid_all();
}
