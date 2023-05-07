-- armed_passthrough_throttle.lua: pass-though throttle for manual and autothrottle modes
--
-- Achieves the same effect as having manual throttle in autothrottle
-- modes. Like an RCINxScaled, but only when armed.

local MAV_SEVERITY = {EMERGENCY=0, ALERT=1, CRITICAL=2, ERROR=3, WARNING=4, NOTICE=5, INFO=6, DEBUG=7}

local SERVO_FUNCTION_PTAT = 96  -- "Script3"

local THROTTLE_IN_CHANNEL_N1 = param:get("RCMAP_THROTTLE")  -- 1-based
if nil == THROTTLE_IN_CHANNEL_N1 then
  gcs:send_text(MAV_SEVERITY.ERROR,
                "No RCMAP_THROTTLE; armed passthrough unavailable")
  return
end
local THROTTLE_IN_CHANNEL = rc:get_channel(THROTTLE_IN_CHANNEL_N1)  -- 1-based

local THROTTLE_OUT_CHANNEL_N0 = SRV_Channels:find_channel(SERVO_FUNCTION_PTAT)  -- 0-based
if nil == THROTTLE_OUT_CHANNEL_N0 then
  gcs:send_text(MAV_SEVERITY.ERROR,
                "No Scripting Throttle Output; armed passthrough unavailable")
  return
end

gcs:send_text(MAV_SEVERITY.NOTICE, string.format("Armed Passthrough %g->%g",
                                                 THROTTLE_IN_CHANNEL_N1,
                                                 THROTTLE_OUT_CHANNEL_N0 + 1))

function update()
  local throttle_value = arming:is_armed() and
    THROTTLE_IN_CHANNEL:norm_input_ignore_trim() or
    -1.0
  -- Although the comment in SRV_Channel.h implies that this function
  -- ignores trim setting, it appears that trim plays a role in
  -- computing output. Until I gain a fuller understanding of this,
  -- the solution is to set SERVOx_TRIM halfway between _MIN and _MAX
  -- for this channel.
  SRV_Channels:set_output_norm(SERVO_FUNCTION_PTAT, throttle_value)
  return update, 20
end

return update()
