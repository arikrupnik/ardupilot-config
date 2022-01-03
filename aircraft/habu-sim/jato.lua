
-- consider looking up ICE_START_CHANNEL instead of constant
local starter_channel_num = 8
local starter_channel = rc:get_channel(starter_channel_num)

local out_jato_channel = SRV_Channels:find_channel(69)

local THRUST_DURATION = 10000
local THRUST_CHECK_INTERVAL = 300

function wait_for_start()
	if arming:is_armed() and (starter_channel:norm_input() > 0.9) then
		if out_jato_channel then
			SRV_Channels:set_output_pwm_chan_timeout(out_jato_channel, 2000, THRUST_DURATION)
		else
			gcs:end_text(0, "no jato output channel")
		end
        return end_thrust, THRUST_DURATION
    else
        return wait_for_start, THRUST_CHECK_INTERVAL
	end
end

function end_thrust()
	SRV_Channels:set_output_pwm_chan_timeout(out_jato_channel, 1000, THRUST_DURATION)
	return wait_for_start, THRUST_CHECK_INTERVAL

end


gcs:send_text(0, "JATO standing by")
return wait_for_start,  0