-- disable_throttle.lua: force throttle input to MIN for pure gliders
--
-- AP uses throttle input in a number of ways even in manual-throttle
-- modes, e.g., adjusting target attitude up with higher throttle and
-- down with lower settings. For a glider without a motor, these
-- adjustments are a distraction.

local MAV_SEVERITY = {EMERGENCY=0, ALERT=1, CRITICAL=2, ERROR=3, WARNING=4, NOTICE=5, INFO=6, DEBUG=7}

local THROTTLE_CHANNEL = param:get("RCMAP_THROTTLE")
if not THROTTLE_CHANNEL then
   gcs:send_text(MAV_SEVERITY.ERROR,
                 "RCMAP_THROTTLE parameter missing; throttle manipulation unavailable")
   return
end

-- if overrides are enabled, I want to set override value faster than
-- it times out; if there is no timeout, I set override once and go home
local RC_OVERRIDE_TIME = param:get("RC_OVERRIDE_TIME")
if RC_OVERRIDE_TIME == 0 then
   gcs:send_text(MAV_SEVERITY.ERROR, string.format(
                    "RC_OVERRIDE_TIME=%f disables throttle override",
                    RC_OVERRIDE_TIME))
   return
end

local THROTTLE_MIN = param:get(string.format("RC%d_MIN", THROTTLE_CHANNEL))

function update(run_once)
   rc:get_channel(THROTTLE_CHANNEL):set_override(THROTTLE_MIN)
   if not run_once then
      return update, RC_OVERRIDE_TIME * 1000 / 2
   end
end

gcs:send_text(MAV_SEVERITY.NOTICE, string.format("Activating throttle input override: %g", THROTTLE_MIN))

-- "-1 will never timeout"; run once without rescheduling
return update(RC_OVERRIDE_TIME == -1)
