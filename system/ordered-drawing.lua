require('class.system')
require('util.box')

OrderedDrawingSystem = System:extend()

function OrderedDrawingSystem:new()
    OrderedDrawingSystem.super.new(self)

    self.requiredComponents = {
        'position',
        'quad'
    }

    self.background = {}
    self.foreground = {}
    self.newEntities = {}

    self.spritebatches = {fg = nil, bg = nil}
    self.spriteBatchesAreDirty = true

    self:init_test()
end

local function refresh_spritebatch(sb, entities)
    love.graphics.setColor(255, 255, 255, 255)

    sb:bind()
    sb:clear()
    for i = 1, #entities do
        local e = entities[i]
        sb:add(e.quad, e.position.x, e.position.y)
    end
    sb:unbind()
end

function OrderedDrawingSystem:refresh_spritebatches()
    local capacity = #self.background + #self.foreground
    if capacity < 1 then
        capacity = 1
    end

    if not self.spritebatches.bg then
        self.spritebatches.bg = love.graphics.newSpriteBatch(TEXTURE, capacity)
    else
        self.spritebatches.bg:setBufferSize(capacity)
    end
    refresh_spritebatch(self.spritebatches.bg, self.background)

    if not self.spritebatches.fg then
        self.spritebatches.fg = love.graphics.newSpriteBatch(TEXTURE, capacity)
    else
        self.spritebatches.fg:setBufferSize(capacity)
    end
    refresh_spritebatch(self.spritebatches.fg, self.foreground)
end

function OrderedDrawingSystem:init_test()
    -- Add a test bush somewhere on the first platform
    local platform = systems.texturedPlatform.entities[1]
    local e = {
        quad = BUSH_QUAD,
        position = {
            x = platform.position.x + math.random(3, platform.size.w - 10),
            y = platform.position.y - 4}}
    self:add_entity(e)

    -- Add some test bushes on the first platform
    --local grassPlatform = systems.texturedPlatform.entities[1]
    --for i = 1, 5 do
    --    local e = {
    --        quad = BUSH_QUAD,
    --        position = {x = grassPlatform.position.x + (i * 4),
    --                    y = grassPlatform.position.y - 4}}
    --    self:add_entity(e)
    --end

    -- Add some test bushes in random places
    --for i = 1, 5 do
    --    local x = math.random(-200, 200)
    --    local y = math.random(-200, 200)

    --    local e = {
    --        quad = BUSH_QUAD,
    --        position = {x = x,
    --                    y = y}}
    --    self:add_entity(e)
    --end
end

function OrderedDrawingSystem:add_entity(e)
    OrderedDrawingSystem.super.add_entity(self, e)

    -- Add the entity to the table for entities that need to be assigned to
    -- foreground or background
    self.newEntities[#self.newEntities + 1] = e

    local _, _, w, h = e.quad:getViewport()
    e.size = {w = w, h = h}
end

function OrderedDrawingSystem:draw_background()
    if self.spriteBatchesAreDirty then
        self:refresh_spritebatches()
        self.spriteBatchesAreDirty = false
    end

    love.graphics.setColor(255, 255, 255, 255)
    love.graphics.draw(self.spritebatches.bg)
end

function OrderedDrawingSystem:draw_foreground()
    love.graphics.setColor(255, 255, 255, 255)
    --love.graphics.setColor(255, 100, 100, 255)
    love.graphics.draw(self.spritebatches.fg)
end

function OrderedDrawingSystem:set_player(player)
    self.player = player
end

function OrderedDrawingSystem:entity_should_be_in_background(e)
    local playerBottom = math.floor(self.player.position.y) +
        self.player.skin:get_height()

    if e.position.y + e.size.h <= playerBottom then
        return true
    else
        return false
    end
end

function OrderedDrawingSystem:update()
    if math.floor(self.player.position.y) == self.playerPreviousY then
        return
    else
        self.playerPreviousY = math.floor(self.player.position.y)
    end


    -- Add any newly added entities to the correct layer
    for i = 1, #self.newEntities do
        local e = self.newEntities[i]

        if self:entity_should_be_in_background(e) then
            self.background[#self.background + 1] = e
        else
            self.foreground[#self.foreground + 1] = e
        end
    end

    if #self.newEntities > 0 then
        self.spriteBatchesAreDirty = true

        -- Clear the table of new entities, since they have all been assigned
        -- above
        self.newEntities = {}
    end

    -- Determine which background entities need to be moved to the foreground
    local moveToForeground = {}
    for i = 1, #self.background do
        local e = self.background[i]

        if not self:entity_should_be_in_background(e) then
            e.backgroundIndex = i
            moveToForeground[#moveToForeground + 1] = e
        end
    end

    -- Determine which foreground entities need to be moved to the background
    local moveToBackground = {}
    for i = 1, #self.foreground do
        local e = self.foreground[i]

        if self:entity_should_be_in_background(e) then
            e.foregroundIndex = i
            moveToBackground[#moveToBackground + 1] = e
        end
    end

    -- Copy the marked background entities to the foreground
    for i = 1, #moveToForeground do
        local e = moveToForeground[i]

        self.foreground[#self.foreground + 1] = e
    end

    -- Remove the entities from the background in reverse order (highest to
    -- lowest) so the indexes remain valid
    for i = #moveToForeground, 1, -1 do
        local e = moveToForeground[i]
        table.remove(self.background, e.backgroundIndex)
        e.backgroundIndex = nil
    end

    -- Copy the marked foreground entities to the background
    for i = 1, #moveToBackground do
        local e = moveToBackground[i]

        self.background[#self.background + 1] = e
    end

    -- Remove the entities from the foreground in reverse order (highest to
    -- lowest) so the indexes remain valid
    for i = #moveToBackground, 1, -1 do
        local e = moveToBackground[i]
        table.remove(self.foreground, e.foregroundIndex)
        e.foregroundIndex = nil
    end

    if #moveToForeground > 0 or #moveToBackground > 0 then
        self.spriteBatchesAreDirty = true
    end
end
