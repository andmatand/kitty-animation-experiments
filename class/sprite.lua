require('class.spriteinputbuffer')
require('util.graphics')

Sprite = Object:extend()

function Sprite:new()
    self.position = {x = 0, y = 0}
    self.velocity = {x = 0, y = 0}
    self.size = {w = 0, h = 0}

    self.collisionBox = {offset = {x = 0, y = 0},
                         size = {w = 0, h = 0}}
    self.inputBuffer = SpriteInputBuffer(self)
end

function Sprite:get_collision_box(position)
    local position = position or self.position

    return {x = position.x + self.collisionBox.offset.x,
            y = position.y + self.collisionBox.offset.y,
            w = self.collisionBox.size.w,
            h = self.collisionBox.size.h}
end

function Sprite:is_on_platform(testPosition, platform)
    testPosition = align_to_grid(testPosition)

    local box = self:get_collision_box(testPosition)

    if box.y + box.h == platform.position.y and
       box.x + (box.w - 1) > platform.position.x and
       box.x < platform.position.x + platform.size.w then
        return true
    else
        return false
    end
end

function Sprite:fall()
    if not self.onPlatform then return end

    self.onPlatform = false
    self.fallThroughPlatform = true
end

function Sprite:jump(fall)
    if not self.onPlatform or self.hitPlatformTooHard then return end


    self.onPlatform = false

    self.velocity.y = -2.5
    self.moved = true

    soundSources.jump:stop()
    soundSources.jump:play()
end

function Sprite:process_input()
    -- If we are moving upwards and the jump button is not being held
    if self.velocity.y < 0 and not self.virtualGamepad:is_down('jump') then
        if self.velocity.y < -1 then
            self.velocity.y = -1
        end
    end

    local leftx = self.virtualGamepad:get_axis('leftx')

    -- If we are moving on the X axis but neither left nor right are being held
    if (self.velocity.x ~= 0 and math.abs(leftx) < AXIS_DEADZONE) or
       self.hitPlatformTooHard
    then
        -- Apply X friction
        self.velocity.x = 0
    end

    self.virtualGamepad:send_directional_input()
    self.inputBuffer:process()
end
