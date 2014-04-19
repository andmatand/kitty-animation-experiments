Sprite = Object:extend()

function Sprite:new()
    self.position = {x = 0, y = 0}
    self.velocity = {x = 0, y = 0}
    self.size = {w = 0, h = 0}

    self.collisionBox = {offset = {x = 0, y = 0},
                           size = {w = 0, h = 0}}
end

function Sprite:is_on_platform(testPosition, platform)
    local box = self:get_collision_box(testPosition)

    if box.y + box.h == platform.position.y + 1 and
       box.x + box.w - 1 > platform.position.x and
       box.x < platform.position.x + platform.size.w then
        return true
    else
        return false
    end
end

function Sprite:get_collision_box(position)
    local position = position or self.position

    return {x = position.x + self.collisionBox.offset.x,
            y = position.y + self.collisionBox.offset.y,
            w = self.collisionBox.size.w,
            h = self.collisionBox.size.h}
end
