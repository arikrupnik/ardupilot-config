-- armbuzz.lua: sound an external warning buzzer when ignition armed
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


-- no good way to determine which relay is buzzer...
local BUZZER_RELAY_NUM = 0
-- ...but can check that it exists
if not relay:enabled(BUZZER_RELAY_NUM) then
   gcs:send_text(2, "RELAY " .. tostring(BUZZER_RELAY_NUM) .. " missing, ARM buzzer unavailable")
   return
end

local SERVOx_FUNCTION_IGNITION = 67
if SRV_Channels:find_channel(SERVOx_FUNCTION_IGNITION) == nil then
   gcs:send_text(2, "SERVOx_FUNCTION_IGNITION missing, ARM buzzer unavailable")
   return
end

local ICE_PWM_IGN_ON = param:get("ICE_PWM_IGN_ON")
if ICE_PWM_IGN_ON == nil then
   gcs:send_text(2, "ICE_PWM_IGN_ON parameter missing, ARM buzzer unavailable")
   return
end


function buzzer(on_off)
   -- inverted signal
   if on_off then
      relay:off(BUZZER_RELAY_NUM)
   else
      relay:on(BUZZER_RELAY_NUM)
   end
end

function ignition_on()
   return SRV_Channels:get_output_pwm(SERVOx_FUNCTION_IGNITION) >= ICE_PWM_IGN_ON
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
