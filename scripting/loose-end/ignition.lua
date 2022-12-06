-- ignition.lua: ignition control with arming checks
--
-- I use a 3-position locking-lever switch on the transmitter as
-- arm/disarm/ignition control. In this application, low position
-- means "disarm," middle means "arm" and high means "ignition." To
-- achieve this, I use an unusual curve in TX settings:
-- 1000-1900-2000. AP interprets anything above 1800us as high, so
-- both middle and high position of the TX switch mean "arming
-- request" to AP, but this script can differentiate between all three
-- positions.
--
-- Although the physical shape of the switch means "ignition request"
-- can be active only when "arm request" is active also, a request is
-- only a request and arming checks may fail on the vehicle. Therefore
-- this script checks vehicle arming state before attempting to
-- activate ignition.


-- Magic constant: above this value, switch is in the high position.
-- Raw PWM values are inaccesible in Lua for channels which it finds
-- by option number, so I must use a FP for the threshold. 1900us in a
-- 1000-2000 range normalizes to 500/400=0.8; 2000 normalizes to 1.0;
-- I use a value between them.
local IGNITION_THRESHOLD = 0.9

-- regular constants
local MAV_SEVERITY = {EMERGENCY=0, ALERT=1, CRITICAL=2, ERROR=3, WARNING=4, NOTICE=5, INFO=6, DEBUG=7}

-- vehicle configuration
--
local ARMDISARM_RC_CHANNEL = rc:find_channel_for_option(153)
if not ARMDISARM_RC_CHANNEL then
   gcs:send_text(MAV_SEVERITY.ERROR, "No ARM/DISARM RC channel; ignition unavailable")
   return
end

local IGNITION_SRV_CHANNEL_N = SRV_Channels:find_channel(67)
if not IGNITION_SRV_CHANNEL_N then
   gcs:send_text(MAV_SEVERITY.ERROR, "No IGNITION SRV channel; ignition unavailable")
   return
end
local IGNITION_MIN_PWM = param:get(string.format("SERVO%d_MIN", IGNITION_SRV_CHANNEL_N+1))
local IGNITION_MAX_PWM = param:get(string.format("SERVO%d_MAX", IGNITION_SRV_CHANNEL_N+1))


gcs:send_text(MAV_SEVERITY.NOTICE, string.format("Ignition control on SRV %g", IGNITION_SRV_CHANNEL_N+1))


function update()
   -- is the pilot requesting ignition
   local ignition_request = ARMDISARM_RC_CHANNEL:norm_input_ignore_trim() > IGNITION_THRESHOLD
   -- do I turn ignition on or off
   local ignition_on = arming:is_armed() and ignition_request
   -- what is the corresponding PWM
   local ignition_pwm = ignition_on and IGNITION_MAX_PWM or IGNITION_MIN_PWM

   SRV_Channels:set_output_pwm_chan(IGNITION_SRV_CHANNEL_N, ignition_pwm)

   return update, 100
end


return update()
