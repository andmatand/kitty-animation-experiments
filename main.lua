Object = require('util.oo')
require('util.anim')
require('class.animation')
require('class.kitty')
require('class.skin')
require('class.sprite')

function love.load()
    DEBUG = true
    GRAPHICS_SCALE = 6

    love.window.setMode(100 * GRAPHICS_SCALE, 75 * GRAPHICS_SCALE)
    love.mouse.setVisible(false)
    love.graphics.setDefaultFilter('nearest', 'nearest')

    SPRITE_IMAGE = love.graphics.newImage('asset/sprites.png')
    ANIM_TEMPLATES = load_animation_templates()

    soundSources = {jump = love.audio.newSource('asset/jump.wav')}

    sprites = {}
    sprites[1] = Kitty()

    platforms = {}
    local y = 10
    for i = 1, 10 do
        platforms[i] = {}
        platforms[i].position = {x = love.math.random(1, 90),
                                 y = y}
        platforms[i].size = {w = love.math.random(5, 30),
                             h = love.math.random(5, 10)}
        platforms[i].color = {love.math.random(20, 100),
                              love.math.random(20, 100),
                              love.math.random(20, 100)}
        y = y + math.random(1, 10)
    end
end

function love.update(dt)
    player_input(dt)

    do_physics()

    for i = 1, #sprites do
        local sprite = sprites[i]

        sprite.skin:update(dt)
    end
end

function do_physics()
    -- Apply gravity
    for i = 1, #sprites do
        sprites[i].velocity.y = sprites[i].velocity.y + .35
    end

    -- Apply X friction
    for i = 1, #sprites do
        sprites[i].velocity.x = sprites[i].velocity.x * .5
    end

    -- Apply velocity
    for i = 1, #sprites do
        local sprite = sprites[i]

        sprite.position.x = sprites[i].position.x + sprite.velocity.x

        -- Collide
        local groundY = love.window.getHeight() / GRAPHICS_SCALE
        if sprite.velocity.y > 0 then
            step = 1
        else
            step = -1
        end
        for i = step, sprite.velocity.y, step do
            local hit = false
            local testPosition = {x = sprite.position.x,
                                  y = sprite.position.y + step}

            -- If the sprite would be going below the ground
            local hitBox = sprite:get_collision_box(testPosition)
            if hitBox.y + hitBox.h > groundY then
                hit = true
            end

            if not hit and step == 1 then
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
    end
end

function love.keypressed(key)
    local player = sprites[1]
    local velocityDelta = {y = 2}

    -- If the jump button is pressed
    if key == 'k' and player.onPlatform then
        player.onPlatform = false

        --player.velocity.y = player.velocity.y - velocityDelta.y
        player.velocity.y = -velocityDelta.y
        player.jump = {boost = 9}
        moved = true

        soundSources.jump:stop()
        soundSources.jump:play()
    end
end

function player_input(dt)
    local player = sprites[1]
    local velocityDelta = {x = 80 * dt}
    local moved = false

    -- If the jump button is being held
    if love.keyboard.isDown('k') and player.jump then
        if player.jump.boost > 0 then
            player.velocity.y = player.velocity.y -.4
            player.jump.boost = player.jump.boost - 1
        end
    end

    if love.keyboard.isDown('right') or love.keyboard.isDown('d') then
        if player.dir == 2 then
            player.velocity.x = player.velocity.x + velocityDelta.x
            --player.velocity.x = velocityDelta.x
            moved = true
        else
            player.dir = 2
        end
    elseif love.keyboard.isDown('left') or love.keyboard.isDown('a') then
        if player.dir == 4 then
            player.velocity.x = player.velocity.x - velocityDelta.x
            --player.velocity.x = -velocityDelta.x
            moved = true
        else
            player.dir = 4
        end
    end

    if moved then
        player.skin:set_anim('walk')
    else
        player.skin:set_anim('default')
    end
end

function camera_follow_player()
    local screenW = love.window.getWidth()
    local screenH = love.window.getHeight()

    love.graphics.translate((screenW / 2), (screenH / 2))

    local playerW = sprites[1].skin:get_width()
    --love.graphics.scale(GRAPHICS_SCALE)
    love.graphics.translate(-sprites[1].position.x - (playerW / 2),
                            -sprites[1].y)
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

function love.draw()
    love.graphics.scale(GRAPHICS_SCALE)

    draw_platforms()
    draw_sprites()
end
