function love.conf(t)
    GRAPHICS_SCALE = 9
    BASE_SCREEN_W = 32
    BASE_SCREEN_H = 32
    t.window.width = BASE_SCREEN_W * GRAPHICS_SCALE
    t.window.height = BASE_SCREEN_H * GRAPHICS_SCALE
    t.window.title = 'kitty'

    AXIS_THRESHOLD = .3
end
