function set_graphics_scale()
    -- Get the window resolution
    local w, h = love.window.getDimensions()

    -- Find the largest scale that will fit within the window
    GRAPHICS_SCALE = 1
    while BASE_SCREEN_W * (GRAPHICS_SCALE + 1) <= w and
          BASE_SCREEN_H * (GRAPHICS_SCALE + 1) <= h do
        GRAPHICS_SCALE = GRAPHICS_SCALE + 1
    end
end

function set_graphics_offset()
    -- Get the window resolution
    local w, h = love.window.getDimensions()

    -- Find the position at which the game screen should be drawn, in order
    -- to produce a letterbox effect if the actual window is wider or
    -- taller than the game screen
    GRAPHICS_X = (w / 2) - ((BASE_SCREEN_W * GRAPHICS_SCALE) / 2)
    GRAPHICS_Y = (h / 2) - ((BASE_SCREEN_H * GRAPHICS_SCALE) / 2)
end

function scale_and_letterbox()
    set_graphics_scale()
    set_graphics_offset()
end

function set_fullscreen(enable)
    if enable then
        love.window.setFullscreen(true, 'desktop')
    else
        love.window.setFullscreen(false)
    end

    scale_and_letterbox()
end

function align_to_grid(position)
    return {x = math.floor(position.x),
            y = math.floor(position.y)}
end
