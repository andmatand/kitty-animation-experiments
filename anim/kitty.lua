require('class.animationtemplate')
require('util.anim')

local size = {w = 7, h = 5}
local quads = create_quads(SPRITE_IMAGE, {x = 0, y = 0}, size, 6)

local templates = {}
templates.default = AnimationTemplate({{1, 0}}, quads)
templates.walk    = AnimationTemplate({{2, .1}, {1, .1}}, quads, true)
templates.blink   = AnimationTemplate({{3, .1}}, quads)
templates.idle    = AnimationTemplate({{4, .25}}, quads)
templates.land    = AnimationTemplate({{5, .25}}, quads)
templates.jump    = AnimationTemplate({{6, 1}}, quads)

return templates
