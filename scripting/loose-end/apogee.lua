-- apogee.lua: detect apogee and transition to RTL mode

-- AP constants
local MAV_SEVERITY = {
   EMERGENCY=0, ALERT=1,  CRITICAL=2, ERROR=3,
   WARNING=4,   NOTICE=5, INFO=6,     DEBUG=7,
}
local FLIGHT_MODE = {
   Manual=0, CIRCLE=1,  STABILIZE=2, TRAINING=3,    ACRO=4,
   FBWA=5,   FBWB=6,    CRUISE=7,    AUTOTUNE=8,    Auto=10,
   RTL=11,   Loiter=12, TAKEOFF=13,  AVOID_ADSB=14, Guided=15,
   QSTABILIZE=17,       QHOVER=18,   QLOITER=19,    QLAND=20,
   QRTL=21,  QAUTOTUNE=22,           QACRO=23,
   THERMAL=24,                       Loiter_to_QLand=25,
}

-- local constants

-- Flight modes valid for boost phase of flight. Script transitions to
-- RTL only from one of these modes--any other mode means pilot has
-- already taken control of glide
local BOOST_FLIGH_MODES = {
   [FLIGHT_MODE.Manual]=true,
   --[FLIGHT_MODE.FBWA]=true
}

local ALT_HOLD_RTL = param:get("ALT_HOLD_RTL") -- centimeters
if ALT_HOLD_RTL == nil then
  gcs:send_text(MAV_SEVERITY.ERROR, "ALT_HOLD_RTL param missing, auto RTL unavailable")
  return
end
local MIN_MODE_CHANGE_ALT = ALT_HOLD_RTL/100   -- meters; no automatic mode changes to RTL below this altitude

local APOGEE_MARGIN = MIN_MODE_CHANGE_ALT/10   -- meters below peak to call apogee

-- If vehicle is traveling below this airspeed (but is above
-- MIN_MODE_CHANGE_ALT), I transition to RTL without waiting for
-- apogee. This means vehicle is decelerating and I can perform a more
-- gentle transition.
-- (this may need to come from a different airspeed, once I figure out
-- how to make AP maintain airspeed with external thrust)
local ARSPD_FBW_MAX = param:get("ARSPD_FBW_MAX")
if ARSPD_FBW_MAX == nil then
  gcs:send_text(MAV_SEVERITY.ERROR, "ARSPD_FBW_MAX param missing, auto RTL unavailable")
  return
end

local max_altitude = 0
local started_rtl = false
local prev_likely_flying = vehicle:get_likely_flying()
local apogee_reported = false

function transition_to_rtl(reason)
  vehicle:set_mode(FLIGHT_MODE.RTL)
  started_rtl = true
  gcs:send_text(MAV_SEVERITY.NOTICE, reason)
  -- log?
end

function update()

  local alt = ahrs:get_hagl()
  max_altitude = math.max(max_altitude, alt)

  -- reset statistics at launch
  local likely_flying = vehicle:get_likely_flying()
  if likely_flying ~= prev_likely_flying then  -- change occurred
    if likely_flying then  -- at launch
      max_altitude = 0
      started_rtl = false
      apogee_reported = false
    end
  end
  prev_likely_flying = likely_flying

  -- report apogee in telemetry
  if (alt < (max_altitude - APOGEE_MARGIN)) then  -- past apogee
    if not apogee_reported then
      gcs:send_text(MAV_SEVERITY.EMERGENCY,
                    string.format("Apogee: %g", math.floor(max_altitude)))
      apogee_reported = true
    end
  end

  -- automatically transition to RTL at end of coast, under certain conditions
  -- safeguards first:
  if (alt > MIN_MODE_CHANGE_ALT) and                 -- vehicle is above script arm altitude
    BOOST_FLIGH_MODES[vehicle:get_mode()] and        -- pilot hasn't taken control yet
    (not started_rtl) then                           -- AP hasn't taken control yet
    -- now positive conditions
    if ahrs:airspeed_estimate() < ARSPD_FBW_MAX then -- vehicle is slowing down
      transition_to_rtl("airspeed")
    elseif alt < (max_altitude - APOGEE_MARGIN) then -- vehicle is past apogee and descending
      -- possibly OR unusual attitude (e.g., pitch < LIM_PITCH_MIN)
      -- although this will result in descent past apogee soon enough
      transition_to_rtl("apogee")
    end
  end

  return update, 100
end

gcs:send_text(MAV_SEVERITY.NOTICE, "Auto-RTL-at-apogee active")
gcs:send_text(MAV_SEVERITY.NOTICE, string.format("Min Auto-RTL alt: %sm", MIN_MODE_CHANGE_ALT))
gcs:send_text(MAV_SEVERITY.NOTICE, string.format("Min Auto-RTL transition AS: %sm/s", ARSPD_FBW_MAX))

return update()
