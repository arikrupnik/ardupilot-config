-- disable_throttle.lua: force throttle input to MIN for pure gliders
--
-- AP uses throttle input in a number of ways even in manual-throttle
-- modes, e.g., adjusting target attitude up with higher throttle and
-- down with lower settings. For a glider without a motor, these
-- adjustments are a distraction.

local MAV_SEVERITY = {EMERGENCY=0, ALERT=1, CRITICAL=2, ERROR=3, WARNING=4, NOTICE=5, INFO=6, DEBUG=7}

local THROTTLE_CHANNEL_N = param:get("RCMAP_THROTTLE")
if not THROTTLE_CHANNEL_N then
   gcs:send_text(MAV_SEVERITY.ERROR,
                 "RCMAP_THROTTLE parameter missing; throttle manipulation unavailable")
   return
end

-- if overrides are enabled, I want to set override value faster than
-- it times out; special values: 0 means overrides disabled; -1 means
-- "will never time out," in this case I set override once and go home
local RC_OVERRIDE_TIME_S = param:get("RC_OVERRIDE_TIME")
if RC_OVERRIDE_TIME_S == 0 then
   gcs:send_text(MAV_SEVERITY.ERROR, string.format(
                    "RC_OVERRIDE_TIME=%f disables throttle override",
                    RC_OVERRIDE_TIME_S))
   return
end

local THROTTLE_MIN = param:get(string.format("RC%d_MIN", THROTTLE_CHANNEL_N)) or 1000

gcs:send_text(MAV_SEVERITY.NOTICE,
              string.format("Throttle input override: %g", THROTTLE_MIN))


function update(run_once)
   rc:get_channel(THROTTLE_CHANNEL_N):set_override(THROTTLE_MIN)
   if not run_once then
      local rc_override_time_ms = RC_OVERRIDE_TIME_S * 1000
      return update, rc_override_time_ms / 2
   end
end

-- "-1 will never timeout"; run once without rescheduling
return update(RC_OVERRIDE_TIME_S == -1)
