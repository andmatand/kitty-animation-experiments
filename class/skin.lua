require('class.animation')

Skin = Object:extend()

function Skin:new(animationTemplateGroup)
    self.animations = {}
    for key, template in pairs(animationTemplateGroup) do
        self.animations[key] = Animation(template)
    end
end

function Skin:set_anim(key)
    local oldAnimation = self.currentAnimation
    self.currentAnimation = self.animations[key]

    if self.currentAnimation ~= oldAnimation then
        self.currentAnimation:rewind()
    end
end

function Skin:get_quad()
    return self.currentAnimation:get_quad()
end

function Skin:get_width()
    local w, h = select(3, self:get_quad():getViewport())
    return w
end

function Skin:update(dt)
    self.currentAnimation:update(dt)
end
