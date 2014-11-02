function love.conf(t)
    GRAPHICS_SCALE = 8
    BASE_SCREEN_W = 85
    BASE_SCREEN_H = 64
    t.window.width = BASE_SCREEN_W * GRAPHICS_SCALE
    t.window.height = BASE_SCREEN_H * GRAPHICS_SCALE
    t.window.title = 'kitty'
    t.window.vsync = true

    AXIS_THRESHOLD = .3
end
