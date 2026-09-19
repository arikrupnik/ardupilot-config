// motor-mount-reinforcement.scad: add-on to dragonfly-mount.stl to
// attach mount to both sides of wing

include <BOSL2/std.scad>

$fn=64;

WING_THIKNESS=10;
SURFACE_TO_MOTOR_CENTER=11.5;

// reference plane x=0: center of motor shaft
// reference plane y=0: leading edge of wing
// reference plane z=0: inside surface of wing

// glues to the outside surface of the wing
down(WING_THIKNESS) {
  cube([20, 50, 2], anchor=FRONT+TOP);
  cube([20, 1.5, 2], anchor=BACK+TOP);
}

// attaches between motor and existing mount
up(SURFACE_TO_MOTOR_CENTER) {
  difference() {
    union() {
      ycyl(l=1.5, d=20, anchor=BACK);
      cube([20, 1.5, WING_THIKNESS+SURFACE_TO_MOTOR_CENTER], anchor=BACK+TOP);
    }
    fwd(1) {
      // motor shaft
      ycyl(l=3, d=5);
      yrot_copies(n=4, r=6, sa=45) {
        ycyl(l=3, d=2, circum=true);
      }
    }
  }
}
