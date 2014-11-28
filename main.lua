Object = require('util.oo')
require('util.anim')
require('util.sprite')
require('util.graphics')
require('class.animation')
require('class.camera')
require('class.kitty')
require('class.skin')
require('class.sprite')
require('class.virtualgamepad')
require('system.star')

function love.load()
    DEBUG = true
    love.mouse.setVisible(false)
    love.graphics.setDefaultFilter('nearest', 'nearest')
    set_fullscreen(false)

    canvas = love.graphics.newCanvas(BASE_SCREEN_W, BASE_SCREEN_H)
    restart()
end

function restart()
    MAX_VELOCITY_X = 1.25
    MAX_VELOCITY_Y = 5.5

    SPRITE_IMAGE = love.graphics.newImage('asset/sprites.png')
    ANIM_TEMPLATES = load_animation_templates()

    soundSources = {jump = love.audio.newSource('asset/jump.wav')}

    systems = {}
    systems.star = StarSystem()

    PALETTE = {}
    PALETTE[1] = {7, 148, 202} -- blue
    PALETTE[2] = {226, 31, 149} -- purple
    PALETTE[3] = {249, 124, 57} -- orange
    PALETTE[4] = {254, 224, 76} -- yellow
    PALETTE[5] = {124, 210, 109} -- green

    camera = Camera()
    sprites = {}
    sprites[1] = Kitty()
    VIRTUAL_GAMEPAD = VirtualGamepad(sprites[1].inputBuffer)
    sprites[1].virtualGamepad = VIRTUAL_GAMEPAD

    room = {}
    room.platforms = {}
    local platforms = room.platforms

    local y = -100
    local i = 0
    while y < BASE_SCREEN_H - 10 do
        i = i + 1

        platforms[i] = {}
        platforms[i].position = {x = love.math.random(-100, 100), y = y}
        platforms[i].size = {w = love.math.random(5, 30),
                             h = love.math.random(4, 8)}

        local paletteIndex = love.math.random(1, #PALETTE)
        platforms[i].colorState = {srcIndex = paletteIndex}
        shift_platform_color(platforms[i])

        -- Prevent this platform from overlapping with another platform
        local anyOverlap
        repeat
            anyOverlap = false
            for j = 1, i - 1 do
                while box_overlap(platforms[i], platforms[j]) do
                    -- Move this platform a little
                    platforms[i].position.x = platforms[i].position.x - 1
                    platforms[i].position.y = platforms[i].position.y - 1
                    anyOverlap = true
                end
            end
        until anyOverlap == false

        y = y + love.math.random(1, 8)
    end

    sprites[1].room = room

    KEYS = {}
    KEYS.up = 'w'
    KEYS.down = 's'
    KEYS.left = 'a'
    KEYS.right = 'd'
    KEYS.jump = 'k'

    BUTTONS = {}
    BUTTONS.jump = 'a'

    FPS_LIMIT = 60
    timeAccumulator = 0
    frames = 0
    frameTimer = love.timer.getTime()
    currentFPS = 0
end

function love.joystickadded(joystick)
    if joystick:isGamepad() then
        GAMEPAD = joystick
    end
end

function love.gamepadpressed(joystick, button)
    GAMEPAD = joystick

    if GAMEPAD then
        VIRTUAL_GAMEPAD:gamepadpressed(joystick, button)
    else
        love.joystickadded(joystick)
    end

    if button == 'start' then
        restart()
    elseif button == 'back' then
        love.event.quit()
    end
end

function love.update(dt)
    --require('lume.lurker').update()

    local stepTime = 1 / FPS_LIMIT

    timeAccumulator = timeAccumulator + dt
    while timeAccumulator >= stepTime do
        frames = frames + 1
        timeAccumulator = timeAccumulator - stepTime

        systems.star:update()

        for i = 1, #sprites do
            sprites[i]:process_input()
        end

        do_physics()

        for i = 1, #room.platforms do
            room.platforms[i].hasOccupant = false
            shift_platform_color(room.platforms[i])
        end

        for i = 1, #sprites do
            local sprite = sprites[i]

            sprite:update_animation_state(stepTime)
            sprite:post_update_animation_state()
            sprite.skin:update(stepTime)
        end

        camera:update(sprites[1])
    end

    if love.timer.getTime() >= frameTimer + 1 then
        currentFPS = frames

        frameTimer = love.timer.getTime()
        frames = 0
    end
end

function check_for_y_collision(sprite, endY)
    local startY = sprite.position.y

    if sprite.velocity.y <= 0 or endY <= startY then
        return false
    end

    local groundY = BASE_SCREEN_H

    -- Check all pixels (between the current position and the post-velocity
    -- position) for collisions, on the Y-axis only
    local hit = false
    local testPosition = {x = sprite.position.x}
    for y = startY, endY do
        testPosition.y = y

        -- If the sprite would be on the ground
        local hitBox = sprite:get_collision_box(testPosition)
        if hitBox.y + hitBox.h >= groundY then
            hit = true
        end

        if not hit and not sprite.fallThroughPlatform then
            -- Check for collision with platforms
            local platforms = room.platforms
            for j = 1, #platforms do
                if sprite:is_on_platform(testPosition, platforms[j]) then
                    hit = true
                    break
                end
            end
        end

        if hit then
            -- Move the sprite to this position
            sprite.position.y = y

            -- Mark the sprite as being on a platform
            sprite.onPlatform = true

            -- If the sprite is falling too fast to survive the impact
            if sprite.velocity.y >= MAX_VELOCITY_Y then
                if sprite.checkpointPosition then
                    sprite.hitPlatformTooHard = true
                end
            else
                if not sprite.hitPlatformTooHard then
                    sprite.checkpointPosition = {x = sprite.position.x,
                                                 y = sprite.position.y}
                end
            end

            -- Stop the Y-axis velocity
            sprite.velocity.y = 0

            break
        end
    end

    return hit
end

function do_physics()
    -- Apply gravity
    for i = 1, #sprites do
        if sprites[i].fallThroughPlatform then
            sprites[i].velocity.y = 1
        else
            sprites[i].velocity.y = sprites[i].velocity.y + .2
        end
    end

    -- Apply velocity
    for i = 1, #sprites do
        local sprite = sprites[i]

        -- Limit X-axis velocity to top speed
        if sprite.velocity.x < -MAX_VELOCITY_X then
            sprite.velocity.x = -MAX_VELOCITY_X
        elseif sprite.velocity.x > MAX_VELOCITY_X then
            sprite.velocity.x = MAX_VELOCITY_X
        end

        -- Enforce y-axis terminal velocity
        if sprite.velocity.y > MAX_VELOCITY_Y then
            sprite.velocity.y = MAX_VELOCITY_Y
        end

        -- Apply X-axis velocity
        sprite.position.x = sprite.position.x + sprite.velocity.x

        local hit = false
        local newY = sprite.position.y + sprite.velocity.y
        if sprite.velocity.y > 0 then
            hit = check_for_y_collision(sprite, newY)
        end

        if not hit then
            -- Apply Y-axis velocity
            sprite.position.y = newY
        end

        -- If the sprite is still moving downward (it didn't collide)
        if sprite.velocity.y >= 1 then
            sprite.onPlatform = false
        end

        sprite.fallThroughPlatform = false
    end
end

function love.keypressed(key)
    if key == 'f11' then
        set_fullscreen(not love.window.getFullscreen())
    elseif key == 'f5' then
        restart()
    elseif key == 'escape' then
        love.event.quit()
    else
        -- Disable gamepad input
        GAMEPAD = nil
        
        VIRTUAL_GAMEPAD:keypressed(key)
    end
end

function shift_platform_color(platform)
    if not platform.colorState.destIndex then
        local delta
        if love.math.random(0, 1) == 0 then
            delta = -1
        else
            delta = 1
        end

        --local delta = 1--love.math.random(1, #PALETTE - 1)
        platform.colorState.destIndex = platform.colorState.srcIndex + delta
        if platform.colorState.destIndex < 1 then
            platform.colorState.destIndex = #PALETTE
        elseif platform.colorState.destIndex > #PALETTE then
            platform.colorState.destIndex = platform.colorState.destIndex - 
                #PALETTE
        end

        platform.colorState.percent = 0
        platform.color = {}
    end

    for i = 1, 3 do
        local src = PALETTE[platform.colorState.srcIndex][i]
        local dest = PALETTE[platform.colorState.destIndex][i]
        local percent = platform.colorState.percent

        platform.color[i] = src + (percent * (dest - src))
    end

    local changeDelta = .005
    platform.colorState.percent = platform.colorState.percent + changeDelta

    -- If we have reached the destination color
    if platform.colorState.percent >= 1 then
        platform.colorState.srcIndex = platform.colorState.destIndex
        platform.colorState.destIndex = nil
    end
end

function draw_platforms()
    love.graphics.setLineWidth(1)
    love.graphics.setLineStyle('rough')

    local platforms = room.platforms
    for i = 1, #platforms do
        local platform = platforms[i]

        local drawMode, x, y, w, h
        x = platform.position.x
        y = platform.position.y
        w = platform.size.w
        h = platform.size.h

        if platform.hasOccupant then
            drawMode = 'fill'
        else
            drawMode = 'line'
            x = x + 1
            y = y + 1
            w = w - 1
            h = h - 1
        end

        love.graphics.setColor(platform.color)
        love.graphics.rectangle(drawMode, x, y, w, h)
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
        x = math.floor(x)
        y = math.floor(y)

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
    love.graphics.setColor(PALETTE[1])
    love.graphics.rectangle('fill',
                            camera:get_screen_position().x, BASE_SCREEN_H,
                            BASE_SCREEN_W, 2)
end

function love.draw()
    love.graphics.setBackgroundColor(0, 0, 0)
    love.graphics.clear()

    -- Switch to the canvas
    love.graphics.setCanvas(canvas)
    --love.graphics.setBackgroundColor(10, 10, 10, 255)
    love.graphics.clear()

    -- Draw everything on the canvas
    love.graphics.push()
    systems.star:draw()
    --camera:draw() -- DEBUG
    camera:translate()
    draw_ground()
    draw_platforms()
    draw_sprites()
    love.graphics.pop()

    -- Switch to drawing on the screen
    love.graphics.setCanvas()

    -- Draw the canvas on the screen
    love.graphics.push()
    scale_and_letterbox()
    love.graphics.translate(GRAPHICS_X, GRAPHICS_Y)
    love.graphics.draw(canvas, 0, 0, 0, GRAPHICS_SCALE, GRAPHICS_SCALE)
    love.graphics.pop()

    love.graphics.print('FPS: ' .. love.timer.getFPS(), 1, 1)
end
