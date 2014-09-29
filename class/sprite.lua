require('class.spriteinputbuffer')

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
    if not self.onPlatform then return end

    local velocityDelta = {y = 2}

    self.onPlatform = false

    self.velocity.y = -velocityDelta.y
    self.currentJump = {boost = 9}
    self.moved = true

    soundSources.jump:stop()
    soundSources.jump:play()
end

function Sprite:process_input(dt)
    self.inputBuffer:process(dt)

    if not self.virtualGamepad then return end

    self.virtualGamepad:send_directional_input()

    -- If we are in the middle of a jump, and the jump button is being held
    if self.currentJump and self.virtualGamepad:is_down('jump') then
        if self.currentJump.boost > 0 then
            self.velocity.y = self.velocity.y -.35
            self.currentJump.boost = self.currentJump.boost - 1
        end
    end
end
