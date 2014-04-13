Object = require('util.oo')
require('util.anim')
require('class.animation')
require('class.skin')

function love.load()
    DEBUG = true
    GRAPHICS_SCALE = 6
    love.graphics.setDefaultFilter('nearest', 'nearest')

    love.window.setMode(640, 480, {resizable = true})

    SPRITE_IMAGE = love.graphics.newImage('asset/sprites.png')

    ANIM_TEMPLATES = load_animation_templates()

    sprites = {}
    sprites[1] = {x = 50, y = 10}
    sprites[1].skin = Skin(ANIM_TEMPLATES.kitty)
end

function love.update(dt)
    player_input(dt)

    for i = 1, #sprites do
        local sprite = sprites[i]

        sprite.skin:update(dt)
    end
end

function player_input(dt)
    local player = sprites[1]
    local speed = 1--40 * dt
    local moved = false

    if love.keyboard.isDown('up') or love.keyboard.isDown('w') then
        player.y = player.y - speed
        moved = true
    elseif love.keyboard.isDown('right') or love.keyboard.isDown('d') then
        if player.dir == 2 then
            player.x = player.x + speed
            moved = true
        else
            player.dir = 2
        end
    elseif love.keyboard.isDown('down') or love.keyboard.isDown('s') then
        player.y = player.y + speed
        moved = true
    elseif love.keyboard.isDown('left') or love.keyboard.isDown('a') then
        if player.dir == 4 then
            player.x = player.x - speed
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

function love.draw()
    local screenW = love.window.getWidth()
    local screenH = love.window.getHeight()

    love.graphics.translate((screenW / 2), (screenH / 2))

    local playerW = sprites[1].skin:get_width()
    love.graphics.scale(GRAPHICS_SCALE)
    love.graphics.translate(-sprites[1].x - (playerW / 2), -sprites[1].y)

    -- Draw a background
    love.graphics.setColor(30, 30, 30)
    for y = 0, screenH, 30 do
        for x = 0, screenW, 30 do
            love.graphics.rectangle('line', x, y, 10, 10)
        end
    end
    love.graphics.setColor(255, 255, 255)

    for i = 1, #sprites do
        local sprite = sprites[i]

        local w = sprite.skin:get_width()
        local x = sprite.x
        local sx = 1
        if sprite.dir == 2 then
            sx = -1
            x = x + w
        end

        love.graphics.draw(SPRITE_IMAGE, sprite.skin:get_quad(),
                           x, sprite.y,
                           0,
                           sx, 1)
    end
end
