AnimationTemplate = Object:extend()

function AnimationTemplate:new(frameInfoTable, quads, loop)
    self.frames = {}
    self.loop = loop
    for i, frameInfo in pairs(frameInfoTable) do
        local frame = {quad = quads[frameInfo[1]],
                       delay = frameInfo[2]}
        table.insert(self.frames, frame)
    end
end
