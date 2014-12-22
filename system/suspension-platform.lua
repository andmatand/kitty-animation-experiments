require('class.system')
require('util.sprite')

local TIGHTNESS = .15
local DAMPING = .12

SuspensionPlatform = System:extend()

function SuspensionPlatform:new()
    SuspensionPlatform.super.new(self)

    self.requiredComponents = {
        'position',
        'velocity',
    }
end

function SuspensionPlatform:add_entity(e)
    SuspensionPlatform.super.add_entity(self, e)

    if not e.originalPosition then
        e.originalPosition = copy_table(e.position)
    end

    if not e.velocity then
        e.velocity = {y = 0}
    end
end

function SuspensionPlatform:receive_velocity()
    for i = 1, #self.entities do
        local e = self.entities[i]

        -- If we have received a hit
        if e.hit then
            -- Add the hit's y-velocity to our own
            e.velocity.y = e.velocity.y + e.hit.velocity.y

            -- Consume the hit
            e.hit = nil
        end
    end
end

function SuspensionPlatform:apply_spring_force()
    for i = 1, #self.entities do
        local e = self.entities[i]

        local velocityDelta
        velocityDelta = TIGHTNESS * (e.originalPosition.y - e.position.y)
        velocityDelta = velocityDelta - (e.velocity.y * DAMPING)

        e.velocity.y = e.velocity.y + velocityDelta

        -- Apply a gate to the velocity
        if math.abs(e.velocity.y) < .01 and
           math.abs(e.originalPosition.y - e.position.y) < .01
        then
            e.velocity.y = 0
            e.position.y = e.originalPosition.y
        end
    end
end

function SuspensionPlatform:check_for_y_collision(e, newY)
    for y = e.position.y, newY, -1 do
        for i = 1, #e.room.sprites do
            local sprite = e.room.sprites[i]

            if not sprite.fallingThroughPlatform then
                local box1 = {position = {x = e.position.x,
                                          y = y},
                              size = {w = e.size.w, h = 1}}
                local box2 = {position = {
                    x = sprite.position.x,
                    y = sprite.position.y + sprite.skin:get_height() - 1},
                    size = {
                        w = sprite.skin:get_width(),
                        h = 1}}

                -- If this position is overlapping with the bottom of the
                -- sprite
                if box_overlap(box1, box2) then
                    -- Move the sprite up to where the platform is moving
                    sprite.position.y = newY - sprite.skin:get_height()

                    -- TEST
                    --sprite.velocity.y = sprite.velocity.y + e.velocity.y
                end
            end
        end
    end
end

function SuspensionPlatform:apply_velocity()
    for i = 1, #self.entities do
        local e = self.entities[i]

        if e.velocity.y < 0 then
            self:check_for_y_collision(e, e.position.y + e.velocity.y)
        end

        e.position.y = e.position.y + e.velocity.y

        if e.occupant and not e.fallingThroughPlatform then
            -- Move our occupant with us
            e.occupant.position.y = e.position.y - e.occupant.skin:get_height()
        end
    end
end

function SuspensionPlatform:pre_update()
    for i = 1, #self.entities do
        local e = self.entities[i]

        e.occupant = nil
    end
end

function SuspensionPlatform:update()
    self:receive_velocity()
    self:apply_spring_force()
    self:apply_velocity()
end
