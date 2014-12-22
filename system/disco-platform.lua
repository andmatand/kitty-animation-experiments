require('class.system')

DiscoPlatformSystem = System:extend()

local DISCO_PALETTE = {
    {  7, 148, 202}, -- blue
    {226,  31, 149}, -- purple
    {249, 124,  57}, -- orange
    {254, 224,  76}, -- yellow
    {124, 210, 109}  -- green
}


function DiscoPlatformSystem:new()
    self.entities = {}

    self:init_random()
end

local function shift_color(platform)
    if not platform.colorState.destIndex then
        local delta
        if love.math.random(0, 1) == 0 then
            delta = -1
        else
            delta = 1
        end

        platform.colorState.destIndex = platform.colorState.srcIndex + delta
        if platform.colorState.destIndex < 1 then
            platform.colorState.destIndex = #DISCO_PALETTE
        elseif platform.colorState.destIndex > #DISCO_PALETTE then
            platform.colorState.destIndex = platform.colorState.destIndex - 
                #DISCO_PALETTE
        end

        platform.colorState.percent = 0
        platform.color = {}
        platform.velocity = {x = 0, y = 0}
    end

    for i = 1, 3 do
        local src = DISCO_PALETTE[platform.colorState.srcIndex][i]
        local dest = DISCO_PALETTE[platform.colorState.destIndex][i]
        local percent = platform.colorState.percent

        platform.color[i] = src + (percent * (dest - src))
    end

    local changeDelta = .005
    platform.colorState.percent = platform.colorState.percent + changeDelta

    -- If we have reached the destination color
    if platform.colorState.percent >= 1 then
        platform.colorState.srcIndex = platform.colorState.destIndex
        platform.colorState.destIndex = nil
    end
end

function DiscoPlatformSystem:init_random()
    local platforms = self.entities

    local y = -100
    local i = 0
    while y < BASE_SCREEN_H - 10 do
        i = i + 1

        platforms[i] = {}
        platforms[i].position = {x = love.math.random(-100, 100), y = y}
        platforms[i].size = {w = love.math.random(5, 30),
                             h = love.math.random(3, 8)}
        platforms[i].fillAlpha = 0

        local paletteIndex = love.math.random(1, #DISCO_PALETTE)
        platforms[i].colorState = {srcIndex = paletteIndex}
        shift_color(platforms[i])

        -- Prevent this platform from overlapping with another platform
        local anyOverlap
        repeat
            anyOverlap = false
            for j = 1, i - 1 do
                while box_overlap(platforms[i], platforms[j]) do
                    -- Move this platform a little
                    platforms[i].position.x = platforms[i].position.x - 1
                    platforms[i].position.y = platforms[i].position.y - 1
                    anyOverlap = true
                end
            end
        until anyOverlap == false

        y = y + love.math.random(1, 8)
    end
end

function DiscoPlatformSystem:draw()
    love.graphics.setLineWidth(1)
    love.graphics.setLineStyle('rough')

    local platforms = self.entities
    for i = 1, #platforms do
        local platform = platforms[i]

        local drawMode, x, y, w, h
        x = math.floor(platform.position.x)
        y = math.floor(platform.position.y)
        w = platform.size.w
        h = platform.size.h

        if platform.occupant then
            platform.isLit = true
        end

        if platform.isLit then
            drawMode = 'fill'
            platform.fillAlpha = platform.fillAlpha + 10
            if platform.fillAlpha > 255 then
                platform.fillAlpha = 255
            end
            platform.color[4] = platform.fillAlpha
        else
            drawMode = 'line'
            platform.fillAlpha = 0
            platform.color[4] = 255
            x = x + 1
            y = y + 1
            w = w - 1
            h = h - 1
        end

        love.graphics.setColor(platform.color)
        love.graphics.rectangle(drawMode, x, y, w, h)

    end
end

function DiscoPlatformSystem:all_platforms_are_lit()
    for i = 1, #self.entities do
        local e = self.entities[i]

        if not e.isLit then
            return false
        end
    end

    return true
end

function DiscoPlatformSystem:update()
    for i = 1, #self.entities do
        shift_color(self.entities[i])
    end

    if self:all_platforms_are_lit() then
        restart()
    end
end
