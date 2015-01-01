require('class.system')

PlayerPhysicsSystem = System:extend()

PlayerPhysicsSystem.MAX_VELOCITY_X = 1
PlayerPhysicsSystem.MAX_VELOCITY_Y = 4
PlayerPhysicsSystem.GRAVITY = .1

function PlayerPhysicsSystem:new()
    PlayerPhysicsSystem.super.new(self)

    self.requiredComponents = {
        'position',
        'size',
        'velocity'
    }
end

function PlayerPhysicsSystem:add_entity(e)
    PlayerPhysicsSystem.super.add_entity(self, e)

    e.prevState = {}
    e.offPlatformTime = 0
end

function PlayerPhysicsSystem:check_for_y_collision(e, endY)
    local startY = e.position.y

    if e.velocity.y <= 0 or endY <= startY then
        return false
    end

    local groundY = BASE_SCREEN_H - 2

    -- Check all pixels (between the current position and the post-velocity
    -- position) for collisions, on the Y-axis only
    local hit = false
    local testPosition = {x = e.position.x}
    for y = startY, endY do
        testPosition.y = y

        -- If the entity would be on the ground
        local hitBox = e:get_collision_box(testPosition)
        if hitBox.y + hitBox.h >= groundY then
            hit = true
        end

        if not hit and not e.fallingThroughPlatform then
            -- Check for collision with platforms
            for j = 1, #e.room.platforms do
                local platform = e.room.platforms[j]

                if e:is_on_platform(testPosition, platform) then
                    hit = true
                    platform.occupant = e
                    e.platform = platform
                    platform.hit = {velocity = {y = e.velocity.y}}
                    break
                end
            end
        end

        if hit then
            -- Move the entity to this position
            e.position.y = y

            -- Mark the entity as being on a platform
            e.isOnPlatform = true

            -- If the e is falling too fast to survive the impact
            if e.velocity.y >= PlayerPhysicsSystem.MAX_VELOCITY_Y then
                e.hitPlatformTooHard = true
            else
                if not e.hitPlatformTooHard then
                    e.checkpointPlatform = e.platform
                end
            end

            -- Stop the Y-axis velocity
            e.velocity.y = 0

            break
        end
    end

    return hit
end

function PlayerPhysicsSystem:apply_gravity()
    -- Apply gravity
    for i = 1, #self.entities do
        local e = self.entities[i]

        if e.fallingThroughPlatform then
            e.velocity.y = 1
        else
            e.velocity.y = e.velocity.y + PlayerPhysicsSystem.GRAVITY
        end
    end
end

function PlayerPhysicsSystem:apply_velocity()
    -- Apply velocity
    for i = 1, #self.entities do
        local e = self.entities[i]

        -- Limit X-axis velocity to top speed
        if e.velocity.x < -PlayerPhysicsSystem.MAX_VELOCITY_X then
            e.velocity.x = -PlayerPhysicsSystem.MAX_VELOCITY_X
        elseif e.velocity.x > PlayerPhysicsSystem.MAX_VELOCITY_X then
            e.velocity.x = PlayerPhysicsSystem.MAX_VELOCITY_X
        end

        -- Enforce y-axis terminal velocity
        if e.velocity.y > PlayerPhysicsSystem.MAX_VELOCITY_Y then
            e.velocity.y = PlayerPhysicsSystem.MAX_VELOCITY_Y
        end

        -- Apply X-axis velocity
        e.position.x = e.position.x + e.velocity.x

        local hit = false
        local newY = e.position.y + e.velocity.y
        if e.velocity.y > 0 then
            hit = self:check_for_y_collision(e, newY)
        end

        if not hit then
            -- Apply Y-axis velocity
            e.position.y = newY
        end
    end
end

function PlayerPhysicsSystem:pre_update()
    for i = 1, #self.entities do
        local e = self.entities[i]

        e.prevState.isOnPlatform = e.isOnPlatform

        e.isOnPlatform = false
    end
end

function PlayerPhysicsSystem:post_update()
    for i = 1, #self.entities do
        local e = self.entities[i]

        e.fallingThroughPlatform = false

        if e.prevState.isOnPlatform and not e.isOnPlatform then
            e.offPlatformTime = love.timer.getTime()
        end
    end
end

function PlayerPhysicsSystem:update()
    self:apply_gravity()
    self:apply_velocity()
end
