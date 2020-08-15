# ardupilot-config
Configurations for my fleet of ArduPilot vehicles

I'm learning how to configure ArduPilot, the open source autopilot.
There are over a thousand parameters in the default configuration file; more with optional hardware.
To keep track of all these values, I'm putting them under GIT.
Now I can track how my configuration evolves as gain clearer understanding of the system.

## Files

Mission Planner downloads the entire parameter set as a flat list.
I prefer to break it up into functional subsets.
They correspond roughly to different pages in MP.
Mostly, I want to keep things together that have similar lifecycles.
For instance, the physical configuration of the sensors (which are present, and where they connect) is stable in a build.
As against that, PID values can change from flight to flight when I'm tuning the loop.

### Global

#### `arduplane-blank.param`

The default parameter file.
This is what you get from a fresh installation of ArduPlane before any local configuration.

#### `taranis-rctxconfig.param`

The "R/C calibration" for my Taranis.
I use the same transmitter model memory for all my ArduPilot airframes.
With an autopilot, the transmitter only needs send control inputs (Aileron, Elevator, etc.).
Configuration for control mixing, servo reversal and travel, etc. lives on the autopilot.
I do reverse the elevator in my Taranis configuration to match ArduPilot's default.
This way, I can leave all `RCx_REVERSED` parameters at their default `0` value.

### Airframe-type specific

For each airframe type, I make several configuration files.
If I build another airframe of the same type, the configuration carries over.

#### outputs-config.param

Servo, notification buzzer setup.

#### sensor-config.param

Which compass to use, which IMUs are on board, battery monitor, airspeed sensor.

#### fc-config.param

Flight controller configuration.
PID loops, yaw damper, NAVL1 loop, Waypoint radius.

### Airframe-specific

For each individual airframe, I make several calibration files.
If I build another airframe of the same type, or rebuild one after a bad crash, calibration is specific to this airframe.

#### sensor-calib.param


### Bixler

The first airframe I'm working with is a Bixler v2.
It is a vary stable, easy to tune aircraft.
My setup is:

* [Holybro Pixhawk4 Mini](http://www.holybro.com/product/pixhawk4-mini/)
* [Holybro Power Module PM06](http://www.holybro.com/product/micro-power-module-pm06/)
* [Holybro GPS Module](http://www.holybro.com/product/pixhawk-4-gps-module/)
* [Holybro 4525DO Airspeed Sensor](http://www.holybro.com/product/digital-air-speed-sensor/)
* [mRo 915 MHz Telemetry Radio](https://store.mrobotics.io/mRo-SiK-Telemetry-Radio-V2-915Mhz-p/mro-sikv2.htm)
* [FrSky R-XSR S.Bus Receiver](https://www.frsky-rc.com/product/r-xsr/)
* [Yaapu Telemetry Adapter](https://www.amazon.com/Telemetry-Converter-Pixhawk-Taranis-Receiver/dp/B07KJFWTCB)

<!--  LocalWords:  arduplane ArduPlane Airframe airframe
 -->
