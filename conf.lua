function love.conf(t)
    BASE_SCREEN_W = 160
    BASE_SCREEN_H = 120
    GRAPHICS_SCALE = 6
    t.window.width = BASE_SCREEN_W * GRAPHICS_SCALE
    t.window.height = BASE_SCREEN_H * GRAPHICS_SCALE
    t.window.title = 'kitty'
    t.window.vsync = true

    AXIS_DEADZONE = .2

    -- Until I add in-game options to bind controller axes/buttons, the values
    -- below can be changed to support joysticks that SDL2 doesn't
    -- automatically recognize as a standardized Xbox 360-like "gamepad"
    JOYSTICK_AXIS_MAP = {
        leftx = 1,
        lefty = 2,
    }
    JOYSTICK_BUTTON_MAP = {
        a = 1,
        b = 2,
        start = 10,
        back = 9
    }
end
