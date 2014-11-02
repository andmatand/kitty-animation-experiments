SpriteInputBuffer = Object:extend()

function SpriteInputBuffer:new(sprite)
    self.sprite = sprite

    self.queue = {}
end

function SpriteInputBuffer:push(event)
    table.insert(self.queue, event)
end

function SpriteInputBuffer:process()
    -- Process all input events in the queue
    for _, event in pairs(self.queue) do
        if type(event) == 'table' then
            self:process_direction_event(event[1], event[2])
        else
            if event == 'jump' then
                self.sprite:jump()
            elseif event == 'fall' then
                self.sprite:fall()
            end
        end
    end

    -- Clear the queue
    self.queue = {}
end

function SpriteInputBuffer:process_direction_event(direction, amount)
    local velocityDelta = {x = 1 * math.abs(amount)}

    -- Left
    if direction == 4 then
        if self.sprite.dir == 4 then
            self.sprite.velocity.x = self.sprite.velocity.x - velocityDelta.x
            self.sprite.moved = true
        else
            self.sprite.dir = 4
        end

    -- Right
    elseif direction == 2 then
        if self.sprite.dir == 2 then
            self.sprite.velocity.x = self.sprite.velocity.x + velocityDelta.x
            self.sprite.moved = true
        else
            self.sprite.dir = 2
        end
    end
end
