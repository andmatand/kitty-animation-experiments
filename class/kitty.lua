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

function Kitty:update_animation_state(dt)
    if self.moved then
        self.skin:set_anim('walk')
    else
        if not self.prevState.onPlatform and self.onPlatform then
            self.skin:set_anim('land')
        end

        if self.skin:get_anim() == 'walk' then
            self.skin:set_anim('default')
        end
    end

    if self.onPlatform then
        -- If we are over the edge of the platform
        if self:is_over_edge_of_platform() then
            self.skin:set_anim('cliff')
            self.skin.currentAnimation:rewind()
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

    self.moved = false
    self.prevState.onPlatform = self.onPlatform
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
