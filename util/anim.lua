require('class.animation')

-- Create a series quads from a left-to-right, top-to-bottom, grid-based layout
-- of sprites in an image
function create_quads(image, startPosition, size, count)
    local quads = {}
    local x = startPosition.x
    local y = startPosition.y

    while #quads < count do
        quads[#quads + 1] = love.graphics.newQuad(x, y, size.w, size.h,
                                                  image:getWidth(),
                                                  image:getHeight())
        x = x + size.w
        if x + size.w > image:getWidth() then
            x = 0
            y = y + size.h
        end
    end

    return quads
end

function load_animation_templates()
    local templates = {}

    if DEBUG then print('Loading animation templates') end

    local animPath = 'anim/'
    for _, item in pairs(love.filesystem.getDirectoryItems(animPath)) do
        if love.filesystem.isFile(animPath .. item) then
            -- If this is not a hidden file
            if item:sub(1, 1) ~= '.' then
                local groupName = item:sub(1, item:find('%.') - 1)

                if DEBUG then print('  ' .. groupName) end

                local chunk = love.filesystem.load(animPath .. item)
                templates[groupName] = chunk()
            end
        end
    end

    return templates
end
