require('class.animationtemplate')
require('util.anim')

local size = {w = 7, h = 5}
local quads = create_quads(TEXTURE, {x = 0, y = 0}, size, 13)

local templates = {}
templates.default    = AnimationTemplate({{1, 0}}, quads)
templates.walk       = AnimationTemplate({{2, .1}, {1, .1}}, quads, true)
templates.blink      = AnimationTemplate({{3, .1}}, quads)
templates.idle       = AnimationTemplate({{4, .25}}, quads)
templates.land       = AnimationTemplate({{5, .25}}, quads)
templates.jump       = AnimationTemplate({{6, 1}}, quads)
templates.cliff      = AnimationTemplate({{7, 1}}, quads)
templates.splat      = AnimationTemplate({{8, .1}, {9, .5}, {10, .5}}, quads)
templates.land_walk  = AnimationTemplate({{11, .1}}, quads)
templates.land_cliff = AnimationTemplate({{12, .25}}, quads)
templates.turn       = AnimationTemplate({{13, .25}}, quads)

return templates
