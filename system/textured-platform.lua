require('class.system')

TexturedPlatformSystem = System:extend()

function TexturedPlatformSystem:new()
    TexturedPlatformSystem.super.new(self)

    self.requiredComponents = {
        'position',
        'size',
        'terrainType'
    }

    self:init_random()

    self.spriteBatch = love.graphics.newSpriteBatch(TEXTURE, #self.entities)
end

function TexturedPlatformSystem:init_random()
    local e = {}
    e.position = {x = love.math.random(-10, 10),
                  y = love.math.random(-10, 10)}
    e.terrainType = 1
    e.size = {w = 8 * 7, h = 8}

    self:add_entity(e)
end

local function get_quad_indexes_for_platform(masterQuadSet, platformSize)
    local indexes = {}

    local _, _, quadWidth = masterQuadSet[1]:getViewport()

    for x = 0, platformSize.w - 1, quadWidth do
        local widthRemaining = platformSize.w - x

        if x == 0 then
            index = 1
        elseif widthRemaining == quadWidth then
            index = 3
        else
            index = 2
        end

        table.insert(indexes, index)
    end

    return indexes
end

function TexturedPlatformSystem:add_entity(e)
    TexturedPlatformSystem.super.add_entity(self, e)

    e.quadIndexes = {}
    if e.terrainType == 1 then
        e.quadIndexes = get_quad_indexes_for_platform(GRASS_QUADS, e.size)
    end

    self.spriteBatchIsDirty = true
end

function TexturedPlatformSystem:get_total_quad_count()
    local total = 0

    for i = 1, #self.entities do
        total = total + #self.entities[i].quadIndexes
    end

    return total
end

function TexturedPlatformSystem:refresh_spritebatch()
    self.spriteBatch:setBufferSize(self:get_total_quad_count())

    self.spriteBatch:bind()
    self.spriteBatch:clear()

    for i = 1, #self.entities do
        local e = self.entities[i]

        --love.graphics.rectangle(
        --    'fill',
        --    e.position.x, e.position.y,
        --    e.size.w, e.size.h)

        local quadTable
        if e.terrainType == 1 then
            quadTable = GRASS_QUADS
        end

        local _, _, quadWidth = quadTable[1]:getViewport()
        local x = e.position.x
        for i = 1, #e.quadIndexes do
            local quad = quadTable[e.quadIndexes[i]]
            self.spriteBatch:add(quad, x, e.position.y)

            x = x + quadWidth
        end
    end

    self.spriteBatch:unbind()
end

function TexturedPlatformSystem:draw()
    if self.spriteBatchIsDirty then
        self:refresh_spritebatch()
        self.spriteBatchIsDirty = false
    end

    love.graphics.setColor(255, 255, 255, 255)
    love.graphics.draw(self.spriteBatch)
end
