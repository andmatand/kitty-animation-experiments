function love.conf(t)
    GRAPHICS_SCALE = 6
    BASE_SCREEN_W = 320 / 2
    BASE_SCREEN_H = 200 / 2
    t.window.width = BASE_SCREEN_W * GRAPHICS_SCALE
    t.window.height = BASE_SCREEN_H * GRAPHICS_SCALE
    t.window.title = 'kitty'
    t.window.vsync = true

    AXIS_DEADZONE = .2
end
