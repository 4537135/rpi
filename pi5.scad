// Raspberry Pi 5 (+ Geekworm X1001 M.2 HAT) reference geometry shared by every case.
// Numbers come from the official mechanical drawing (RP-008347).
//
// Pi frame: origin at the PCB underside, bottom-left corner (the SD / micro-HDMI corner),
// +x towards USB/LAN, +y towards the GPIO header, +z up through the component side. mm.

PI5_W = 85;
PI5_D = 56;
PI5_PCB = 1.6;
PI5_HOLES = [[3.5, 3.5], [61.5, 3.5], [3.5, 52.5], [61.5, 52.5]];   // M2.5, ø2.7
PI5_USB = [29.1, 47];        // USB-A stacks, centre on y, right edge
PI5_LAN = 10.2;              // RJ45, centre on y, right edge
PI5_USBC = 11.2;             // power, centre on x, bottom edge
PI5_HDMI = [25.8, 39.2];     // micro-HDMI 0 / 1, centre on x, bottom edge
PI5_OVERHANG = 3;            // USB/LAN stick out past the right edge

module pi5_rr(w, h, r) offset(r = r) offset(delta = -r) square([w, h]);

// Wall cutters sized for the plug overmoulds, not the receptacles, so cables seat through a wall.
// len = how far past the board edge they reach.
module pi5_cut_right(len = 20) {
  for (p = [[PI5_USB[0], 15.5, 16.5], [PI5_USB[1], 15.5, 16.5], [PI5_LAN, 17, 14.5]])
    translate([PI5_W - 5, p[0] - p[1] / 2, PI5_PCB - 0.5])
      rotate([90, 0, 90]) linear_extrude(len + 5) pi5_rr(p[1], p[2] + 1, 1.5);
}

// One slot for USB-C + both micro-HDMI.
module pi5_cut_bottom(len = 20)
  translate([4.9, 6, -0.8]) rotate([90, 0, 0]) linear_extrude(len + 6) pi5_rr(40.2, 8.2, 2);

// microSD (underside) + power button.
module pi5_cut_left(len = 20)
  translate([-len, 14, -3.5]) rotate([90, 0, 90]) linear_extrude(len + 5) pi5_rr(22, 8, 2);

// Square case fan with an RGB ring, axis along +z, for renders.
LED = ["#ff2d55", "#ff9500", "#ffd60a", "#30d158", "#0a84ff", "#bf5af2"];
module fan_dummy(s = 40, t = 10) {
  color("#141518") difference() {
    translate([-s / 2, -s / 2, 0]) cube([s, s, t]);
    translate([0, 0, -1]) cylinder(d = s - 3, h = t + 2);
  }
  color([0.55, 0.95, 0.85, 0.55]) for (a = [0 : 72 : 359]) rotate(a) translate([0, -1, 1]) rotate([0, -25, 0]) cube([s / 2 - 2, 2, t - 3]);
  color("#141518") cylinder(d = s * 0.35, h = t);
  for (i = [0 : 11]) color(LED[i % 6]) rotate(i * 30) translate([s * 0.42, 0, t]) sphere(d = 2.2, $fn = 12);
}

module pi5_dummy(hat_standoff = 16, hat = true) {
  color("#1e7b3c") linear_extrude(PI5_PCB) difference() {
    pi5_rr(PI5_W, PI5_D, 3);
    for (h = PI5_HOLES) translate(h) circle(d = 2.7, $fn = 16);
  }
  color("#c9ccd1") {
    for (y = PI5_USB) translate([PI5_W + PI5_OVERHANG - 17.5, y - 7.25, PI5_PCB]) cube([17.5, 14.5, 16]);
    translate([PI5_W + PI5_OVERHANG - 21, PI5_LAN - 8, PI5_PCB]) cube([21, 16, 13.5]);
    translate([PI5_USBC - 4.5, -0.5, PI5_PCB]) cube([9, 7.5, 3.2]);
    for (x = PI5_HDMI) translate([x - 3.75, -0.5, PI5_PCB]) cube([7.5, 7.5, 3.4]);
  }
  color("#24262a") translate([7, 50, PI5_PCB]) cube([51, 5, 8.5]);        // GPIO header
  color("#9aa0a6") translate([20, 14, PI5_PCB]) cube([30, 30, 9]);         // Active Cooler footprint
  color("#111") translate([-2.5, 22.8, -1.4]) cube([14, 11, 1.4]);          // microSD
  if (hat) {
    color("#d4af37") for (h = PI5_HOLES) translate([h[0], h[1], PI5_PCB]) cylinder(d = 4.6, h = hat_standoff, $fn = 6);
    color("#202327") translate([0, 0, PI5_PCB + hat_standoff]) linear_extrude(1.6) difference() {
      pi5_rr(66, PI5_D, 3);
      for (h = PI5_HOLES) translate(h) circle(d = 2.7, $fn = 16);
    }
    color("#3a3f47") translate([2, 17, PI5_PCB + hat_standoff + 1.6]) cube([80, 22, 2.4]);   // M.2 2280
  }
}
