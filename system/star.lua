require('class.system')
require('util.tables')

StarSystem = System:extend()

function StarSystem:new()
    self.entities = {}

    for i = 1, 200 do
        local x = love.math.random(-100, 200)
        local y = love.math.random(-100, 200)

        local e = {}
        e.position = {x = x, y = y}
        e.color = choose_random_color()
        self.entities[i] = e
    end

    -- Initialize state for updating stars in groups
    self.updateState = {start = 1, step = 10}
end

function StarSystem:update(dt)
    for i = self.updateState.start, #self.entities, self.updateState.step do
        local e = self.entities[i]

        if love.math.random(0, 50) == 0 or not e.color then
            -- Change the star's color
            e.color = choose_random_color()
        end
    end

    -- Advance to the group of stars (they will be updated next time)
    self.updateState.start = self.updateState.start + 1
    if self.updateState.start > self.updateState.step then
        self.updateState.start = 1
    end
end

function StarSystem:draw()
    love.graphics.push()
    camera:transform(.5)
    love.graphics.setPointStyle('rough')
    love.graphics.setPointSize(camera:get_zoom())

    for i = 1, #self.entities do
        local entity = self.entities[i]

        local offsets = {
            {x = 0, y = -1},
            {x = -1, y = 0}, {x = 0, y = 0}, {x = 1, y = 0},
            {x = 0, y = 1}}

        if entity.color then
            for _, offset in pairs(offsets) do
                local x = entity.position.x + offset.x
                local y = entity.position.y + offset.y
                local color = copy_table(entity.color)

                -- If this is not the middle of the star
                if not (offset.x == 0 and offset.y == 0) then
                    -- Make the color transparent
                    color[4] = 75
                end

                love.graphics.setColor(color)
                love.graphics.point(x + .5, y + .5)
            end
        end
    end

    love.graphics.pop()
end

function choose_random_color()
    local c = love.math.random(20, 25)
    if love.math.random(0, 5) == 0 then
        c = c * 2
    end

    return {c, c, c}
end
