// Raspberry Pi 5 "dumb PC" all-in-one: screen in front, Pi 5 + X1001 NVMe HAT behind it,
// standing on two fins. Bring your own USB keyboard.
//
//   openscad -D 'screen="7"' -D 'part="shell"' -o shell.stl aio.scad
//
// Each part exports in its print orientation and needs no supports:
//   bezel      face down, so the bed finishes the front
//   shell      back down, so the vents and screw holes sit on the bed
//   fin_left / fin_right   lying flat
//
// Device frame: X = width seen from the front, Y = depth (front face at 0), Z = up.
include <pi5.scad>

/* [Build] */
screen = "7";        // [5, 7]
part = "assembly";   // [assembly, bezel, shell, fin_left, fin_right]
explode = 0;         // assembly only: pulls the parts apart
badge = "rpi";       // engraved in the chin, "" for none

/* [Pi 5 + Geekworm X1001 stack] */
hs_bottom = 6;       // heatsink room under the Pi (PCB underside -> back plate)
hs_top = 12;         // heatsink / Active Cooler room above the Pi, sits under the HAT
hat_standoff = 16;   // Pi PCB top -> X1001 PCB (M2.5 brass standoffs)
hat_stack = 6;       // X1001 PCB + M.2 2280 SSD

/* [Stand] */
tilt = 12;           // lean-back, degrees
lift = 40;           // desk -> case bottom; cables leave the port bay downwards

/* [Print] */
wall = 2.4;
fp = 2;              // bezel front plate
bp = 2.4;            // shell back plate
clr = 0.4;           // screen clearance per side
R = 8;               // outer corner radius
$fn = 48;

// Screens: [glass w, h, t, board w, h, depth behind glass, glass bottom above board bottom,
//           active w, h, x, y from glass bottom-left, connector notch z0, z1 on the right edge from board bottom]
// ELECROW 7" 1024x600 (B076J8ZWFF, wiki RPD10246D): board 164.7 x 107.1; standard 7" panel 164.9 x 100, AA 154.21 x 85.92
S7 = [164.9, 100, 6.5, 164.7, 107.1, 10, 3.55, 154.21, 85.92, 5.35, 9.68, 50, 100];
// ELECROW RC050 5" 800x480, a stand-in until the real 5" screen is known: board 121.11 x 95.24, standard 5" AA 108 x 64.8
S5 = [121.11, 76.6, 6, 121.11, 95.24, 10, 18.64, 108, 64.8, 6.55, 5.9, 2, 18];
S = screen == "5" ? S5 : S7;
gw = S[0]; gh = S[1]; gt = S[2]; pw = S[3]; ph = S[4]; pb = S[5]; gdz = S[6];
aw = S[7]; ah = S[8]; ax = S[9]; ay = S[10]; cz0 = S[11]; cz1 = S[12];

bs = 7;                            // side border
bt = 12;                           // top border
bc = screen == "5" ? 20 : 24;      // chin, also the depth of the port bay
cw = max(gw, pw) + 2 * clr;
ch = ph + 2 * clr;
W = cw + 2 * bs;
H = ch + bt + bc;
pcb_x = bs + (cw - pw) / 2;    pcb_z = bc + clr;
glass_x = bs + (cw - gw) / 2;  glass_z = pcb_z + gdz;

split = fp + gt + pb;                             // bezel | shell joint
pi_top = split + 3 + hat_stack + hat_standoff;    // Pi PCB top face; components face the screen
pi_bot = pi_top + PI5_PCB;
D = pi_bot + hs_bottom + bp;
px = W - wall - PI5_W - PI5_OVERHANG + 1;         // USB/LAN fronts end 1 mm inside the right wall
pz = bc;                                          // micro-HDMI edge sits right above the port bay
bay_y = pi_top - 8;

COLS = [[14, bc / 2], [W - 14, bc / 2], [14, H - 7], [W - 14, H - 7]];   // M3 bezel screws
fin_in = round(W * 0.17);
FIN_Z = [pz + 66, H - 18];
FIN_SCREWS = [for (x = [fin_in - 6, W - fin_in + 6], z = FIN_Z) [x, z]];
PAD = [FIN_Z[0] - 12, FIN_Z[1] + 12];

assert(hs_top < hat_standoff, "heatsink / Active Cooler must fit under the X1001");
assert(FIN_Z[1] - FIN_Z[0] >= 15, "case too short for the stand screws above the Pi");
assert(px - 16 > wall + 2, "screen too narrow for the Pi and the SD hatch");
assert(min([for (f = FIN_SCREWS, c = COLS) norm(f - c)]) >= 10, "stand screw hits a bezel screw column");

FONT = "Liberation Sans:style=Bold";

// 2D in the X-Z plane, extruded over depth y0..y1.
module ext(y0, y1) translate([0, y1, 0]) rotate([90, 0, 0]) linear_extrude(y1 - y0) children();
module rr(x, z, w, h, r) translate([x, z]) pi5_rr(w, h, r);
module outline(i = 0) rr(i, i, W - 2 * i, H - 2 * i, R - i);
module cavity() translate([bs, bc]) square([cw, ch]);
module window() rr(glass_x + ax - 0.8, glass_z + ay - 0.8, aw + 1.6, ah + 1.6, 1);
module pi_place() translate([px, pi_bot, pz]) rotate([90, 0, 0]) children();
module hexgrid(p = 7, d = 6)
  for (i = [-1 : W / p + 1], j = [0 : H / (p * 0.866) + 1])
    translate([i * p + (j % 2) * p / 2, j * p * 0.866]) rotate(30) circle(d = d, $fn = 6);

module bezel() {
  difference() {
    hull() { ext(0, 0.01) outline(1.2); ext(1.2, split - 0.8) outline(); ext(split - 0.01, split) outline(0.8); }
    ext(fp, split + 1) cavity();
    ext(fp, split + 1) difference() { outline(wall); offset(delta = wall) cavity(); }   // hollow rim
    hull() { ext(-1, 0) offset(delta = 1.2) window(); ext(1.2, fp + 1) window(); }      // chamfered window
    ext(fp + gt - 0.5, split + 1) translate([W - bs - 1, pcb_z + cz0]) square([bs + 2, cz1 - cz0]);  // screen HDMI / USB
    if (badge != "") ext(-1, 0.6) translate([W / 2, bc / 2])
      text(badge, size = bc * 0.32, font = FONT, halign = "center", valign = "center");
  }
  for (c = COLS) difference() {
    ext(fp, split) translate(c) circle(d = 8);
    ext(split - 7, split + 1) translate(c) circle(d = 4);    // M3 heat-set insert
  }
}

module shell_body() hull() { ext(split, split + 0.01) outline(0.8); ext(split + 0.8, D - 3) outline(); ext(D - 0.01, D) outline(3); }

module shell() difference() {
  union() {
    difference() { shell_body(); ext(split - 1, D - bp) outline(wall); }
    intersection() {
      shell_body();
      union() {
        for (c = COLS) ext(split, D - 1) translate(c) circle(d = 9);
        for (h = PI5_HOLES) ext(pi_bot, D - 1) translate([px + h[0], pz + h[1]]) circle(d = 6.5);
        for (f = FIN_SCREWS) ext(D - bp - 6, D - 1) translate(f) circle(d = 9);
        ext(bay_y - wall, D - 1) translate([px + 3 - wall, 0]) square([44 + 2 * wall, pz - 1]);   // port bay walls
      }
    }
  }
  // bezel screws: M3 x 10 through a 3 mm floor, heads sunk from the back
  for (c = COLS) { ext(split - 1, D + 1) translate(c) circle(d = 3.4); ext(split + 3, D + 1) translate(c) circle(d = 6.5); }
  // Pi: M2.5 from the back through the Pi into the X1001 brass standoffs
  for (h = PI5_HOLES) {
    ext(pi_bot - 1, D + 1) translate([px + h[0], pz + h[1]]) circle(d = 2.7);
    ext(D - 1.5, D + 1) translate([px + h[0], pz + h[1]]) circle(d = 5.2);
  }
  for (f = FIN_SCREWS) ext(D - 7.5, D + 1) translate(f) circle(d = 4);   // M3 heat-set inserts for the fins
  pi_place() pi5_cut_right(20);
  translate([px + 3, bay_y, -1]) cube([44, D - bay_y + 2, pz + 0.2]);    // port bay: USB-C + 2x micro-HDMI
  ext(D - bp - 1, D + 1) rr(px - 16, pz + 12, 20, 26, 3);                // hatch: microSD + power button
  ext(D - bp - 1, D + 1) difference() {                                  // back grille
    intersection() { rr(W * 0.14, pz + 8, W * 0.72, 40, 6); hexgrid(); }
    for (h = PI5_HOLES) translate([px + h[0], pz + h[1]]) circle(d = 11);
    offset(delta = 2.5) rr(px - 16, pz + 12, 20, 26, 3);
  }
  for (z = [-1, H - wall - 1]) translate([0, 0, z]) linear_extrude(wall + 2)          // chimney: in at the bottom, out the top
    for (x = [W * 0.22 : 5 : W * 0.78]) if (z > 0 || x < px - wall - 4 || x > px + 50 + wall)
      rr(x, split + 6, 2.4, D - split - 14, 1.2);
  for (p = [[PI5_LAN, "LAN"], [PI5_USB[0], "USB"], [PI5_USB[1], "USB"]])
    translate([W + 0.4, (split + pi_top - 16.8) / 2, pz + p[0]]) multmatrix([[0, 0, -1, 0], [0, -1, 0, 0], [1, 0, 0, 0]])
      linear_extrude(1) text(p[1], size = 2.6, font = FONT, halign = "center", valign = "center");
  for (p = [[PI5_USBC, "5V"], [PI5_HDMI[0], "HDMI0"], [PI5_HDMI[1], "HDMI1"]])
    translate([px + p[0], (split + bay_y - wall) / 2, -0.4]) mirror([1, 0, 0])
      linear_extrude(1) text(p[1], size = 2.4, font = FONT, halign = "center", valign = "center");
  ext(D - 0.6, D + 1) translate([W / 2, H - 15]) mirror([1, 0, 0])
    text("dumb pc", size = 5, font = FONT, halign = "center", valign = "center");
}

// Stand fin, drawn in the world side profile (u = depth, v = height), w = thickness.
// The pad is flush with the tilted back plate; the flange behind it carries the two screws.
function w2(p) = [p[0] * cos(tilt) + p[1] * sin(tilt), lift + D * sin(tilt) - p[0] * sin(tilt) + p[1] * cos(tilt)];
module pad(t) polygon([w2([D, PAD[0]]), w2([D + t, PAD[0]]), w2([D + t, PAD[1]]), w2([D, PAD[1]])]);
module fin() {
  ub = D * cos(tilt) + 4;   // rear foot starts behind the lowest corner of the case
  difference() {
    union() {
      linear_extrude(8) difference() {
        offset(r = 2) offset(delta = -2) offset(r = -6) offset(delta = 6) union() {
          hull() { pad(5); translate([ub, 0]) square([32, 8]); }
          translate([-22, 0]) square([ub + 54, 8]);
        }
        offset(r = 3) offset(delta = -12) hull() { pad(5); translate([ub, 0]) square([32, 8]); }   // open frame
      }
      linear_extrude(20) offset(r = 1) offset(delta = -1) pad(4);
    }
    for (z = FIN_Z) let(p = w2([D, z]))
      translate([p[0], p[1], 14]) rotate([0, 0, -tilt]) rotate([0, 90, 0]) translate([0, 0, -1]) cylinder(d = 3.4, h = 12);
  }
}
module fin_right() multmatrix([[0, 0, 1, W - fin_in - 8], [1, 0, 0, 0], [0, 1, 0, 0]]) fin();
module fin_left() multmatrix([[0, 0, -1, fin_in + 8], [1, 0, 0, 0], [0, 1, 0, 0]]) fin();

module screen_dummy() {
  color("#0b0c0e") translate([glass_x, fp, glass_z]) cube([gw, gt, gh]);
  color("#1b4f8a") translate([pcb_x, fp + gt, pcb_z]) cube([pw, 1.6, ph]);
  n = 16;
  for (i = [0 : n - 1]) let(t = i / (n - 1))
    color([0.77 - 0.73 * t, 0.10 + 0.01 * t, 0.29 - 0.06 * t])    // raspberry -> navy
      translate([glass_x + ax, fp - 0.05, glass_z + ay + i * ah / n]) cube([aw, 0.1, ah / n]);
  color("white") translate([glass_x + ax + 5, fp - 0.1, glass_z + ay + ah - 9]) rotate([90, 0, 0])
    linear_extrude(0.05) text("pi@dumbpc:~ $ _", size = ah * 0.055, font = "Liberation Mono:style=Bold");
}

module device() {
  color("#1d1f22") translate([0, -explode, 0]) bezel();
  translate([0, -explode * 0.5, 0]) screen_dummy();
  color("#f2f1ee") translate([0, explode, 0]) shell();
  translate([0, explode * 0.6, 0]) pi_place() pi5_dummy(hat_standoff);
}

if (part == "bezel") rotate([90, 0, 0]) bezel();
else if (part == "shell") translate([0, 0, D]) rotate([-90, 0, 0]) shell();
else if (part == "fin_right") fin();
else if (part == "fin_left") mirror([0, 1, 0]) fin();
else {
  translate([0, 0, lift + D * sin(tilt)]) rotate([-tilt, 0, 0]) device();
  color("#c51a4a") translate([0, explode * 1.6 * cos(tilt), -explode * 1.6 * sin(tilt)]) { fin_right(); fin_left(); }
}
