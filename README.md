# Configurations for my fleet of ArduPilot vehicles

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

* `rcinput-config.param`: "R/C calibration" and input configuration. I use the same transmitter model memory for all my ArduPilot airframes. With an autopilot, the transmitter only needs send control inputs (Aileron, Elevator, etc.). Configuration for control mixing, servo reversal and travel, etc. lives on the autopilot. This file also configures which channel controls flight modes, which is the arming switch, etc.

### Airframe-specific

For each airframe, I make two files:

* `config.param`: settings that reflect decisions about the aircraft. These are decisions I make at the bench and include:
  * INS orientation
  * servo functions
  * sensor connections
  * `SYSID_THISMAV`
    * this controls where Mission Planner stored the logs it downloads
* `tune.param`: settings that reflect flight performance of the aircraft, including
  * PIDF values
  * TECS values including target airspeeds
  * Navigation controller tuning

### Odds and Ends:

* `Santa Clara County Model Aircraft Skypark North_AP.RFX`: a modification to the stock RealFlight airfield that aligns correctly with North, for use with ArduPilot simulations in RF.
* `update-from-dl.sh`: Mission Planner downloads all parameter into a single, flat file. This utility updates different `.param` files from this single download.
* `opentx-config`: copies of model and radio configurations from my TX.
