System = Object:extend()

function System:new()
    self.entities = {}
    self.requiredComponents = {}
end

function System:entity_has_reqiured_components(e)
    for i = 1, #self.requiredComponents do
        local componentName = self.requiredComponents[i]

        if not e[componentName] then
            print('rejected entity (missing component ' .. componentName .. ')')
            return false
        end
    end

    return true
end

function System:add_entity(e)
    if self:entity_has_reqiured_components(e) then
        table.insert(self.entities, e)
    end
end

function System:pre_update()
end

function System:post_update()
end

function System:update()
end
