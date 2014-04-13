Timer = Object:extend()

function Timer:new(secs)
    self.secs = secs
    self:reset()
end

function Timer:update(dt)
    self.value = self.value - dt

    if self.value <= 0 then
        return true
    end
end

function Timer:reset()
    self.value = self.secs
end
