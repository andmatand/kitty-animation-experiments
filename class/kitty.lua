require('class.sprite')

Kitty = Sprite:extend()

function Kitty:new()
    Kitty.super.new(self)

    self.skin = Skin(ANIM_TEMPLATES.kitty)
    self.collisionBox = {offset = {x = 1, y = 1},
                         size = {w = self.skin:get_width() - 2,
                                 h = self.skin:get_height() - 1}}
    self.prevState = {}
end

function Kitty:update_animation_state()
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

    if not self.onPlatform then
        self.skin:set_anim('jump')
    else
        if self.skin:get_anim() == 'jump' then
        end
    end

    self.moved = false
    self.prevState.onPlatform = self.onPlatform
end
