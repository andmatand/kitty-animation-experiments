VirtualGamepad = Object:extend()

function VirtualGamepad:new(spriteInputBuffer)
    self.spriteInputBuffer = spriteInputBuffer
end

function VirtualGamepad:get_axis(axis)
    if GAMEPAD then
        return GAMEPAD:getGamepadAxis(axis)
    else
        -- Emulate a gamepad by treating each keyboard direction key as 100%
        -- along its axis
        if axis == 'leftx' then
            if love.keyboard.isDown(KEYS.left) then
                return -1
            else if love.keyboard.isDown(KEYS.right) then
                return 1
            end
        end
        elseif axis == 'lefty' then
            if love.keyboard.isDown(KEYS.up) then
                return -1
            elseif love.keyboard.isDown(KEYS.down) then
                return 1
            end
        end
    end

    return 0
end

function VirtualGamepad:is_down(gameButton)
    if GAMEPAD then
        return GAMEPAD:isGamepadDown(BUTTONS[gameButton])
    else
        return love.keyboard.isDown(KEYS[gameButton])
    end
end

function VirtualGamepad:gamepadpressed(joystick, button)
    if joystick ~= GAMEPAD then return end

    if button == BUTTONS.jump then
        -- If the lefty axis is down
        if self:get_axis('lefty') >= AXIS_DEADZONE then
            self.spriteInputBuffer:push('fall')
        end

        self.spriteInputBuffer:push('jump')
    end
end

function VirtualGamepad:keypressed(key)
    if key == KEYS.jump then
        if self:get_axis('lefty') >= AXIS_DEADZONE then
            self.spriteInputBuffer:push('fall')
        end

        self.spriteInputBuffer:push('jump')
    end
end

function VirtualGamepad:send_directional_input()
    local leftx = self:get_axis('leftx') 

    if leftx <= -AXIS_DEADZONE then
        self.spriteInputBuffer:push({4, leftx}) -- Right
    elseif leftx >= AXIS_DEADZONE then
        self.spriteInputBuffer:push({2, leftx}) -- Left
    end
end
