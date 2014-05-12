Object = require('util.oo')
require('util.anim')
require('class.animation')
require('class.camera')
require('class.kitty')
require('class.skin')
require('class.sprite')

function love.load()
    DEBUG = true
    love.mouse.setVisible(false)
    love.graphics.setDefaultFilter('nearest', 'nearest')
    love.graphics.setBackgroundColor(26, 17, 26)

    SPRITE_IMAGE = love.graphics.newImage('asset/sprites.png')
    ANIM_TEMPLATES = load_animation_templates()

    soundSources = {jump = love.audio.newSource('asset/jump.wav')}

    COLORS = {}
    COLORS.green = {142, 165, 20}

    camera = Camera()
    sprites = {}
    sprites[1] = Kitty()

    platforms = {}
    local y = 10
    for i = 1, 3 do
        platforms[i] = {}
        platforms[i].position = {x = love.math.random(1, 22),
                                 y = y}
        platforms[i].size = {w = love.math.random(5, 30),
                             h = love.math.random(5, BASE_SCREEN_H - y)}
        --platforms[i].color = {love.math.random(20, 100),
        --                      love.math.random(20, 100),
        --                      love.math.random(20, 50)}
        y = y + math.random(1, 8)
    end

    platforms[1].color = {0, 123, 150}
    platforms[2].color = {157, 100, 19}
    platforms[3].color = COLORS.green

    KEYS = {}
    KEYS.jump = 'k'
end

function love.update(dt)
    --require('lume.lurker').update()
    player_input(dt)

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

        sprite.position.x = sprites[i].position.x + sprite.velocity.x

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
    local player = sprites[1]
    local velocityDelta = {y = 2}

    -- If the jump button is pressed
    if key == KEYS.jump and player.onPlatform then
        player.onPlatform = false

        if love.keyboard.isDown('s') or love.keyboard.isDown('down') then
            player.fallThroughPlatform = true
        else
            player.velocity.y = -velocityDelta.y
            player.jump = {boost = 9}
            player.moved = true

            soundSources.jump:stop()
            soundSources.jump:play()
        end
    elseif key == 'f11' then
        love.window.setFullscreen(not love.window.getFullscreen(), 'desktop')
    elseif key == 'f5' then
        love.load()
    elseif key == 'escape' then
        love.event.quit()
    end
end

function player_input(dt)
    local player = sprites[1]
    local velocityDelta = {x = 40 * dt}
    local moved = false

    -- If the jump button is being held
    if love.keyboard.isDown(KEYS.jump) and player.jump then
        if player.jump.boost > 0 then
            player.velocity.y = player.velocity.y -.35
            player.jump.boost = player.jump.boost - 1
        end
    end

    if love.keyboard.isDown('right') or love.keyboard.isDown('d') then
        if player.dir == 2 then
            player.velocity.x = player.velocity.x + velocityDelta.x
            --player.velocity.x = velocityDelta.x
            player.moved = true
        else
            player.dir = 2
        end
    elseif love.keyboard.isDown('left') or love.keyboard.isDown('a') then
        if player.dir == 4 then
            player.velocity.x = player.velocity.x - velocityDelta.x
            --player.velocity.x = -velocityDelta.x
            player.moved = true
        else
            player.dir = 4
        end
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
    love.graphics.scale(GRAPHICS_SCALE)
    camera:translate()

    draw_ground()
    draw_platforms()
    draw_sprites()
end
