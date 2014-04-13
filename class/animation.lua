require('class.timer')

Animation = Object:extend()

function Animation:new(animationTemplate)
    self.frames = animationTemplate.frames
    self.loop = animationTemplate.loop

    self.isStopped = false
    self:set_frame_index(1)
end

function Animation:get_quad()
    return self.currentFrame.quad
end

function Animation:is_stopped()
    return self.isStopped
end

function Animation:set_frame_index(index)
    self.currentFrame = {index = index,
                         quad = self.frames[index].quad,
                         timer = Timer(self.frames[index].delay)}
end

function Animation:rewind()
    self:set_frame_index(1)
end

function Animation:start()
    self.isStopped = false
end

function Animation:step_forward()
    -- If we have not yet gotten to the final frame
    if self.currentFrame.index < #self.frames then
        self:set_frame_index(self.currentFrame.index + 1)
    else
        if self.loop then
            -- Wrap around to the first frame
            self:set_frame_index(1)
        else
            self:stop()
        end
    end
end

function Animation:stop()
    self.isStopped = true
end

function Animation:update(dt)
    if #self.frames > 1 and not self.isStopped then
        if self.currentFrame.timer:update(dt) then
            self:step_forward()
        end
    end
end
