require('class.animation')

Skin = Object:extend()

function Skin:new(animationTemplateGroup)
    self.animations = {}
    for key, template in pairs(animationTemplateGroup) do
        self.animations[key] = Animation(template)
    end

    self:set_anim('default')
end

function Skin:set_anim(key)
    local oldAnimation = self.currentAnimation
    self.currentKey = key
    self.currentAnimation = self.animations[key]

    if self.currentAnimation ~= oldAnimation then
        self.currentAnimation:rewind()
    end
end

function Skin:get_anim()
    return self.currentKey
end

function Skin:get_quad()
    return self.currentAnimation:get_quad()
end

function Skin:get_height()
    local w, h = select(3, self:get_quad():getViewport())
    return h
end

function Skin:get_width()
    local w, h = select(3, self:get_quad():getViewport())
    return w
end

function Skin:update(dt)
    if self.currentAnimation:is_stopped() then
        self:set_anim('default')
    end

    self.currentAnimation:update(dt)
end
