require('class.sprite')

Kitty = Sprite:extend()

function Kitty:new()
    Kitty.super.new(self)

    self.skin = Skin(ANIM_TEMPLATES.kitty)
    self.collisionBox = {offset = {x = 1, y = 1},
                         size = {w = self.skin:get_width() - 2,
                                 h = self.skin:get_height() - 1}}
    self.blinkTimer = Timer(love.math.random(1, 6))
    self.prevState = {}
end

function Kitty:post_update_animation_state()
    self.moved = false
    self.prevState.onPlatform = self.onPlatform
end

function anim_is_playing(skin, animKey)
    if skin:get_anim() ~= animKey or
       (skin:get_anim() == animKey and skin.currentAnimation:is_stopped())
    then
        return false
    else
        return true
    end
end

function Kitty:update_animation_state(dt)
    if self.skin:get_anim() == 'splat' and
        self.skin.currentAnimation:is_stopped()
    then
        self.position = {x = self.checkpointPosition.x,
                         y = self.checkpointPosition.y}
        self.hitPlatformTooHard = false
    end

    if self.hitPlatformTooHard then
        self.skin:set_anim('splat')
        return
    end

    if self.moved then
        if not anim_is_playing(self.skin, 'land_walk') and
           not anim_is_playing(self.skin, 'turn') then
            self.skin:set_anim('walk')
        end

        TURN_VELOCITY = MAX_VELOCITY_X * .8

        -- It we are skidding from changing direction suddenly while moving
        if (self.dir == 2 and self.velocity.x <= -TURN_VELOCITY or
            self.dir == 4 and self.velocity.x >= TURN_VELOCITY)
        then
            self.skin:set_anim('turn')
        end
    end

    if not self.prevState.onPlatform and self.onPlatform then
        if self.skin:get_anim() == 'walk' then
            self.skin:set_anim('land_walk')
        else
            self.skin:set_anim('land')
        end
    end

    if not self.moved and self.skin:get_anim() == 'walk' then
        self.skin:set_anim('default')
    end

    if self.onPlatform then
        -- If we are over the edge of the platform
        if self:is_over_edge_of_platform() then
            if self.skin:get_anim() == 'land' then
                self.skin:set_anim('land_cliff')
            end

            if not anim_is_playing(self.skin, 'land_cliff') then
                self.skin:set_anim('cliff')
                self.skin.currentAnimation:rewind()
            end
        end
    else
        self.skin:set_anim('jump')
        self.skin.currentAnimation:rewind()
    end

    if self.skin:get_anim() == 'default' then
        if self.blinkTimer:update(dt) then
            if love.math.random(0, 1) == 0 then
                self.skin:set_anim('blink')
            else
                self.skin:set_anim('idle')
            end

            self.blinkTimer.secs = love.math.random(1, 6)
            self.blinkTimer:reset()
        end
    end
end

function Kitty:get_current_platform()
    for i = 1, #self.room.platforms do
        if self:is_on_platform(self.position, self.room.platforms[i]) then
            return self.room.platforms[i]
        end
    end
end

function Kitty:is_over_edge_of_platform()
    local platform = self:get_current_platform()
    if not platform then
        return false
    end

    platform.hasOccupant = true

    if self.position.x + (self.skin:get_width() - 1) - 1 >
       platform.position.x + platform.size.w then
        return true
    end

    if self.position.x + 1 < platform.position.x then
        return true
    end

    return false
end
