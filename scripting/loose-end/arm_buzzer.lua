-- arm_buzzer.lua: sound an external warning buzzer when ignition armed
--
-- I want a sound when I arm ignition to warn spectators of imminent
-- takeoff. The simple solution is to slave a buzzer to arming
-- channel, but this means buzzing during the entire flight. Instead,
-- I stop the buzzer as soon as actual ignition occurs. For cases
-- where ignition fails, disarming resets the logic. Arming after a
-- disarm sounds the buzzer again.
--
-- On Matek H743, GPIO 81 switches Vsw, normally for switching a
-- secondary FPV camera on or off. The circuit is on when relay signal
-- is low. The circuit provides up to 2A, enough to drive a 30mA
-- buzzer directly. The parameter to activate this circuit as RELAY1
-- (0 in C++ and Lua bindings) is RELAY_PIN=81
--
-- This script depends for its operation on `ignition.lua' to set
-- IGNITION output. Without that script, the buzzer is on whenever
-- motors are armed.


local MAV_SEVERITY = {EMERGENCY=0, ALERT=1, CRITICAL=2, ERROR=3, WARNING=4, NOTICE=5, INFO=6, DEBUG=7}

-- no good way to determine which relay is buzzer...
local BUZZER_RELAY_N = 0
-- ...but can check that it exists
if not relay:enabled(BUZZER_RELAY_N) then
   gcs:send_text(
      MAV_SEVERITY.ERROR,
      string.format("RELAY %g missing, ARM buzzer unavailable", BUZZER_RELAY_N))
   return
end

local SERVOx_FUNCTION_IGNITION = 67
local IGNITION_SRV_CHANNEL_N = SRV_Channels:find_channel(SERVOx_FUNCTION_IGNITION)
if not IGNITION_SRV_CHANNEL_N then
   gcs:send_text(MAV_SEVERITY.ERROR, "IGNITION SRV channel missing; ARM buzzer unavailable")
   return
end
local IGNITION_MAX_PWM = param:get(string.format("SERVO%d_MAX", IGNITION_SRV_CHANNEL_N+1))


gcs:send_text(MAV_SEVERITY.INFO, string.format("ARM warning buzzer on RELAY%g",
                                               BUZZER_RELAY_N_N+1))


function buzzer(on_off)
   -- inverted signal
   if on_off then
      relay:off(BUZZER_RELAY_N)
   else
      relay:on(BUZZER_RELAY_N)
   end
end

function ignition_on()
   -- it is safe to compare these floats for equality: they are
   -- integers; `ignition.lua' is setting this output to the explicit
   -- (integer) value of the parameter
   return SRV_Channels:get_output_pwm(SERVOx_FUNCTION_IGNITION) == IGNITION_MAX_PWM
end


(function()
      local ignition_happened = false

      function update()
         if ignition_on() then
            -- tautologically
            ignition_happened = true
         end

         if not arming:is_armed() then
            -- disarming resets the state for a followup attempt
            ignition_happened = false
         end

         -- warning when armed but silent during flight
         buzzer(arming:is_armed() and not ignition_happened)

         return update, 50
      end
end)()

return update()
