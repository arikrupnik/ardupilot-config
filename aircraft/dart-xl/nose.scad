

include <BOSL2/std.scad>
include <BOSL2/beziers.scad>

$fn=64;

// reconstructs shape of front former
BACK_OUTLINE = bezpath_curve([[-57.105, 0.000],
                              [-57.308,  8.568], [-50.786, 26.972], [-48.540, 28.075],
                              [-42.433, 32.032], [ -9.715, 33.508], [  0.000, 33.578],
                              [  9.715, 33.508], [ 42.433, 32.032], [ 48.540, 28.075],
                              [ 50.786, 26.972], [ 57.308,  8.568], [ 57.105,  0.000]], N=3);
// a simple circle
FRONT_OUTLINE_R = 10;
FRONT_OUTLINE = rot(-90, p=circle(r=FRONT_OUTLINE_R));

HEIGHT=20;

PITOT_TUBE_D = 4.2;

difference() {
  union() {
    skin([ymove(-15, p=xrot(10, p=path3d(BACK_OUTLINE))),
          path3d(FRONT_OUTLINE, HEIGHT)], 10);
    zmove(HEIGHT) zscale(.3) sphere(r=FRONT_OUTLINE_R);
  }
  zcyl(d=PITOT_TUBE_D, h=HEIGHT*2, anchor=BOTTOM);
  zcyl(d=14, h=HEIGHT/2, anchor=BOTTOM);
}
