require('class.sprite')

Kitty = Sprite:extend()

function Kitty:new()
    Kitty.super.new(self)

    self.skin = Skin(ANIM_TEMPLATES.kitty)
    self.collisionBox = {offset = {x = 1, y = 1},
                         size = {w = self.skin:get_width() - 2,
                                 h = self.skin:get_height() - 1}}
end
