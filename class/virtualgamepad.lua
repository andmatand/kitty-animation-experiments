VirtualGamepad = Object:extend()

function VirtualGamepad:new(spriteInputBuffer)
    self.spriteInputBuffer = spriteInputBuffer

    self:refresh_map_reverse_lookup_cache()
end

function VirtualGamepad:refresh_map_reverse_lookup_cache()
    self.keyToButtonMap = {}
    for button, keyOrKeys in pairs(KEYBOARD_BUTTON_MAP) do
        if type(keyOrKeys) == 'string' then
            self.keyToButtonMap[keyOrKeys] = button
        elseif type(keyOrKeys) == 'table' then
            for _, key in pairs(keyOrKeys) do
                self.keyToButtonMap[key] = button
            end
        end
    end

    self.joystickButtonToGamepadButtonMap = {}
    for gamepadButton, joystickButton in pairs(JOYSTICK_BUTTON_MAP) do
        self.joystickButtonToGamepadButtonMap[joystickButton] = gamepadButton
    end
end

function VirtualGamepad:get_axis(axis)
    if GAMEPAD then
        return GAMEPAD:getGamepadAxis(axis)
    elseif JOYSTICK then
        local joystickAxis = JOYSTICK_AXIS_MAP[axis]
        return JOYSTICK:getAxis(joystickAxis)
    else
        local keys = KEYBOARD_AXIS_MAP[axis]
        for key, value in pairs(keys) do
            if love.keyboard.isDown(key) then
                return value
            end
        end
    end

    return 0
end

function VirtualGamepad:is_down(button)
    if GAMEPAD then
        return GAMEPAD:isGamepadDown(button)
    elseif JOYSTICK then
        local joystickButton = JOYSTICK_BUTTON_MAP[button]
        return JOYSTICK:isDown(joystickButton)
    else
        local keys = KEYBOARD_BUTTON_MAP[button]
        if type(keys) == 'string' then
            return love.keyboard.isDown(keys)
        elseif type(keys) == 'table' then
            for _, keyname in pairs(keys) do
                if love.keyboard.isDown(keyname) then
                    return true
                end
            end

            return false
        end
    end
end

function VirtualGamepad:buttonpressed(button)
    if button == 'a' then
        -- If the lefty axis is down
        if self:get_axis('lefty') >= AXIS_DEADZONE then
            self.spriteInputBuffer:push('fall')
        end

        self.spriteInputBuffer:push('jump')
    elseif button == 'start' then
        restart()
    elseif button == 'back' then
        love.event.quit()
    end
end

function VirtualGamepad:joystickpressed(joystick, button)
    local gamepadButton = self.joystickButtonToGamepadButtonMap[button]
    if gamepadButton then
        self:buttonpressed(gamepadButton)
    end
end

function VirtualGamepad:keypressed(key)
    local gamepadButton = self.keyToButtonMap[key]
    if gamepadButton then
        self:buttonpressed(gamepadButton)
    end
end

function VirtualGamepad:send_directional_input()
    local leftx = self:get_axis('leftx')
    local lefty = self:get_axis('lefty')

    if leftx <= -AXIS_DEADZONE then
        self.spriteInputBuffer:push({4, leftx}) -- Right
    elseif leftx >= AXIS_DEADZONE then
        self.spriteInputBuffer:push({2, leftx}) -- Left
    elseif lefty >= AXIS_DEADZONE then
        self.spriteInputBuffer:push({3, lefty}) -- Down
    end
end
