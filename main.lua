Object = require('util.oo')
require('util.anim')
require('util.graphics')
require('class.animation')
require('class.camera')
require('class.kitty')
require('class.skin')
require('class.sprite')
require('class.virtualgamepad')

function love.load()
    DEBUG = true
    love.mouse.setVisible(false)
    love.graphics.setDefaultFilter('nearest', 'nearest')
    set_fullscreen(false)

    SPRITE_IMAGE = love.graphics.newImage('asset/sprites.png')
    ANIM_TEMPLATES = load_animation_templates()

    soundSources = {jump = love.audio.newSource('asset/jump.wav')}

    COLORS = {}
    COLORS.green = {142, 165, 20}

    camera = Camera()
    sprites = {}
    sprites[1] = Kitty()
    VIRTUAL_GAMEPAD = VirtualGamepad(sprites[1].inputBuffer)
    sprites[1].virtualGamepad = VIRTUAL_GAMEPAD

    platforms = {}
    local y = 10
    for i = 1, 3 do
        platforms[i] = {}
        platforms[i].position = {x = love.math.random(1, 22),
                                 y = y}
        platforms[i].size = {w = love.math.random(5, 30),
                             h = love.math.random(4, 8)}
        --platforms[i].color = {love.math.random(20, 100),
        --                      love.math.random(20, 100),
        --                      love.math.random(20, 50)}
        y = y + math.random(1, 8)
    end

    platforms[1].color = {0, 123, 150}
    platforms[2].color = {157, 100, 19}
    platforms[3].color = COLORS.green

    KEYS = {}
    KEYS.up = 'w'
    KEYS.down = 's'
    KEYS.left = 'a'
    KEYS.right = 'd'
    KEYS.jump = 'k'

    BUTTONS = {}
    BUTTONS.jump = 'a'
end

function love.joystickadded(joystick)
    if joystick:isGamepad() then
        GAMEPAD = joystick
    end
end

function love.gamepadaxis(joystick, axis, value)
    if joystick ~= GAMEPAD then return end

    if axis == 'leftx' then
        if value <= -AXIS_THRESHOLD then
        end
    end
end

function love.gamepadpressed(joystick, button)
    if GAMEPAD then
        VIRTUAL_GAMEPAD:gamepadpressed(joystick, button)
    else
        love.joystickadded(joystick)
    end
end

function love.update(dt)
    --require('lume.lurker').update()

    for i = 1, #sprites do
        sprites[i]:process_input(dt)
    end

    do_physics()

    for i = 1, #sprites do
        local sprite = sprites[i]

        sprite:update_animation_state()
        sprite.skin:update(dt)
    end

    camera:update(dt, sprites[1])
end

function do_physics()
    -- Apply gravity
    for i = 1, #sprites do
        if sprites[i].fallThroughPlatform then
            sprites[i].velocity.y = 1
        else
            sprites[i].velocity.y = sprites[i].velocity.y + .35
        end
    end

    -- Apply velocity
    for i = 1, #sprites do
        local sprite = sprites[i]

        sprite.position.x = sprite.position.x + sprite.velocity.x

        -- Collide
        local groundY = 32
        if sprite.velocity.y > 0 then
            step = 1
        else
            step = -1
        end
        local hit = false
        for i = step, sprite.velocity.y, step do
            local testPosition = {x = sprite.position.x,
                                  y = sprite.position.y + step}

            -- If the sprite would be going below the ground
            local hitBox = sprite:get_collision_box(testPosition)
            if hitBox.y + hitBox.h > groundY then
                hit = true
            end

            if not hit and step == 1 and not sprite.fallThroughPlatform then
                -- Check for collision with platforms
                for j = 1, #platforms do
                    if sprite:is_on_platform(testPosition, platforms[j]) then
                        hit = true
                        break
                    end
                end
            end

            if hit then
                if step == 1 then
                    sprite.onPlatform = true
                end

                sprite.velocity.y = 0
                break
            end

            sprite.position.y = testPosition.y
        end

        -- If the sprite is still moving downward (it didn't collide)
        if sprite.velocity.y >= 1 then
            sprite.onPlatform = false
        end

        sprite.fallThroughPlatform = false
    end

    -- Apply X friction
    for i = 1, #sprites do
        --sprites[i].velocity.x = sprites[i].velocity.x * .5
        sprites[i].velocity.x = 0
    end
end

function love.keypressed(key)
    if key == 'f11' then
        set_fullscreen(not love.window.getFullscreen())
    elseif key == 'f5' then
        love.load()
    elseif key == 'escape' then
        love.event.quit()
    else
        -- Disable gamepad input
        GAMEPAD = nil
        
        VIRTUAL_GAMEPAD:keypressed(key)
    end
end

function draw_background()
    local screenW = love.window.getWidth()
    local screenH = love.window.getHeight()

    -- Draw a background
    love.graphics.setColor(30, 30, 30)
    love.graphics.setLineWidth(1)
    love.graphics.setLineStyle('rough')
    for y = 0, screenH / GRAPHICS_SCALE, 20 do
        for x = 0, screenW / GRAPHICS_SCALE, 20 do
            love.graphics.rectangle('fill', x, y, 10, 10)
        end
    end
end

function draw_platforms()
    love.graphics.setLineWidth(1)
    love.graphics.setLineStyle('rough')

    for i = 1, #platforms do
        local platform = platforms[i]

        --platforms[i].color = {50, 155, 151}
        love.graphics.setColor(platform.color)
        love.graphics.rectangle('fill',
                                platform.position.x, platform.position.y,
                                platform.size.w, platform.size.h)
    end
end

function draw_sprites()
    love.graphics.setColor(255, 255, 255)

    for i = 1, #sprites do
        local sprite = sprites[i]

        local w = sprite.skin:get_width()
        local h = sprite.skin:get_height()
        local x, y = sprite.position.x, sprite.position.y

        -- Ensure the position aligns to the grid
        x = math.floor((x * GRAPHICS_SCALE) / GRAPHICS_SCALE)
        y = math.floor((y * GRAPHICS_SCALE) / GRAPHICS_SCALE)

        local sx = 1
        if sprite.dir == 2 then
            sx = -1
            x = x + w
        end

        love.graphics.draw(SPRITE_IMAGE, sprite.skin:get_quad(),
                           x, y,
                           0,
                           sx, 1)
    end
end

function draw_ground()
    love.graphics.setColor(COLORS.green)
    love.graphics.rectangle('fill',
                            camera:get_position().x, BASE_SCREEN_H,
                            BASE_SCREEN_W, 2)
end

function love.draw()
    love.graphics.setBackgroundColor(0, 0, 0)
    love.graphics.clear()

    scale_and_letterbox()
    love.graphics.setScissor(GRAPHICS_X,
                             GRAPHICS_Y,
                             BASE_SCREEN_W * GRAPHICS_SCALE,
                             BASE_SCREEN_H * GRAPHICS_SCALE)
    love.graphics.translate(GRAPHICS_X, GRAPHICS_Y)

    love.graphics.setBackgroundColor(26, 17, 26)
    love.graphics.clear()

    love.graphics.scale(GRAPHICS_SCALE)
    camera:translate()

    draw_ground()
    draw_platforms()
    draw_sprites()

    love.graphics.setScissor()
end
