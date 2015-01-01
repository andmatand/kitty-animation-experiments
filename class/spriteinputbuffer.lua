SpriteInputBuffer = Object:extend()

function SpriteInputBuffer:new(sprite)
    self.sprite = sprite

    self.queue = {}
end

function SpriteInputBuffer:push(event)
    table.insert(self.queue, event)
end

function SpriteInputBuffer:process()
    self.sprite.isCrouching = false

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
    if self.sprite.hitPlatformTooHard then return end

    -- Normalize the amount to account for the Axis Deadzone
    local normalizedAmount
    normalizedAmount = (math.abs(amount) - AXIS_DEADZONE) / (1 - AXIS_DEADZONE)

    local velocityDelta = {x = .1 * math.abs(normalizedAmount)}

    -- If the sprite is in the air (not standing on a platform)
    if not self.sprite.isOnPlatform then
        -- Decrease the amount of control
        velocityDelta.x = velocityDelta.x * .5
    end

    -- Left
    if direction == 4 then
        if self.sprite.dir ~= 4 then
            self.sprite.dir = 4
            velocityDelta.x = velocityDelta.x * 2
        end

        self.sprite.velocity.x = self.sprite.velocity.x - velocityDelta.x
        self.sprite.moved = true

    -- Right
    elseif direction == 2 then
        if self.sprite.dir ~= 2 then
            self.sprite.dir = 2
            velocityDelta.x = velocityDelta.x * 2
        end

        self.sprite.velocity.x = self.sprite.velocity.x + velocityDelta.x
        self.sprite.moved = true

    -- Down
    elseif direction == 3 and self.sprite.isOnPlatform then
        self.sprite.isCrouching = true
    end
end
