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
end

function VirtualGamepad:get_axis(axis)
    if JOYSTICK then
        return JOYSTICK:getGamepadAxis(axis)
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

function VirtualGamepad:axis_moved(axis, value)
    if self:is_down('back') then
        if axis == 'lefty' then
            local zoom = camera:get_zoom()

            if value < -AXIS_DEADZONE then
                camera:set_zoom(zoom + 1)
            elseif value > AXIS_DEADZONE and zoom > 1 then
                camera:set_zoom(zoom - 1)
            end
        end
    end
end

function VirtualGamepad:is_down(button)
    if JOYSTICK then
        return JOYSTICK:isGamepadDown(button)
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
        if self:get_axis('lefty') > AXIS_DEADZONE then
            self.spriteInputBuffer:push('fall')
        end

        self.spriteInputBuffer:push('jump')
    elseif button == 'start' and self:is_down('back') then
        love.event.quit()
    elseif button == 'start' then
        restart()
    end
end

function VirtualGamepad:keypressed(key)
    if key == 'escape' then
        love.event.quit()
    end

    local gamepadButton = self.keyToButtonMap[key]
    if gamepadButton then
        self:buttonpressed(gamepadButton)
    end
end

function VirtualGamepad:send_directional_input()
    local leftx = self:get_axis('leftx')
    local lefty = self:get_axis('lefty')

    if leftx < -AXIS_DEADZONE then
        self.spriteInputBuffer:push({4, leftx}) -- Right
    elseif leftx > AXIS_DEADZONE then
        self.spriteInputBuffer:push({2, leftx}) -- Left
    elseif lefty > AXIS_DEADZONE then
        self.spriteInputBuffer:push({3, lefty}) -- Down
    end
end
