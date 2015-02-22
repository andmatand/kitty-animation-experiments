Object = require('util.oo')
require('util.anim')
require('util.box')
require('util.graphics')
require('class.animation')
require('class.camera')
require('class.kitty')
require('class.skin')
require('class.sprite')
require('class.virtualgamepad')
require('system.disco-platform')
require('system.star')
require('system.ordered-drawing')
require('system.suspension-platform')
require('system.textured-platform')
require('system.player-physics')

function love.load()
    love.mouse.setVisible(false)
    love.keyboard.setKeyRepeat(false)
    love.graphics.setDefaultFilter('nearest', 'nearest')
    set_fullscreen(false)

    CANVAS = love.graphics.newCanvas(BASE_SCREEN_W, BASE_SCREEN_H)

    shaders = {}
    shaders.bloom = love.graphics.newShader('shader/bloom.lsl')

    restart()
end

function restart()
    TEXTURE = love.graphics.newImage('asset/texture.png')
    ANIM_TEMPLATES = load_animation_templates()
    GRASS_QUADS = create_quads(TEXTURE, {x = 0, y = 53}, {w = 8, h = 8}, 3)
    GROUND_QUAD = love.graphics.newQuad(
        0, 61,
        16, 3,
        TEXTURE:getWidth(), TEXTURE:getHeight())
    BUSH_QUAD = love.graphics.newQuad(
        0, 48,
        6, 5,
        TEXTURE:getWidth(), TEXTURE:getHeight())
    WATER_QUADS = create_quads(TEXTURE, {x = 0, y = 40}, {w = 8, h = 8}, 3)

    soundSources = {jump = love.audio.newSource('asset/jump.wav')}

    systems = {}
    systems.discoPlatform = DiscoPlatformSystem()
    systems.playerPhysics = PlayerPhysicsSystem()
    systems.star = StarSystem()
    systems.suspensiisOnPlatform = SuspensionPlatformSystem()
    systems.texturedPlatform = TexturedPlatformSystem()
    systems.orderedDrawing = OrderedDrawingSystem()

    -- Assign explicit update-order to systems that require it
    systemUpdateOrderMap = {
        systems.playerPhysics,
        systems.suspensiisOnPlatform}

    -- Assign arbitrary update-order to any remaining systems 
    for _, system in pairs(systems) do
        if not table_contains_value(systemUpdateOrderMap, system) then
            table.insert(systemUpdateOrderMap, system)
        end
    end

    --for k, v in pairs(systemUpdateOrderMap) do
    --    local name
    --    for n, system in pairs(systems) do
    --        if system == v then
    --            name = n
    --        end
    --    end

    --    print(k, name)
    --end

    -- Emulate a gamepad by treating each keyboard direction key as 100% along
    -- its axis
    KEYBOARD_AXIS_MAP = {
        leftx = {a = -1, left = -1,
                 d = 1, right = 1},
        lefty = {w = -1, up = -1,
                 s = 1, down = 1},
    }

    KEYBOARD_BUTTON_MAP = {
        a = {'k', ' '},
        start = 'f5',
        back = 'escape'
    }

    room = {}
    room.sprites = {}
    room.platforms = {}

    room.sprites[1] = Kitty()
    VIRTUAL_GAMEPAD = VirtualGamepad(room.sprites[1].inputBuffer)
    room.sprites[1].virtualGamepad = VIRTUAL_GAMEPAD

    systems.playerPhysics:add_entity(room.sprites[1])

    for i = 1, #systems.discoPlatform.entities do
        local e = systems.discoPlatform.entities[i]
        systems.suspensiisOnPlatform:add_entity(e)
        e.room = room

        table.insert(room.platforms, e)
    end

    for _, tp in pairs(systems.texturedPlatform.entities) do
        table.insert(room.platforms, tp)
    end

    for i = 1, #room.sprites do
        room.sprites[i].room = room
    end

    -- Make sure the player is right on top of the first textured platform
    local firstPlatform = systems.texturedPlatform.entities[1]
    room.sprites[1]:warp_to_platform(firstPlatform)

    -- Give the ordered drawing system a pointer to the player
    systems.orderedDrawing:set_player(room.sprites[1])

    -- Create the camera
    camera = Camera()
    camera:set_player(room.sprites[1])
    camera:warp_to_player()


    SIM_HZ = 60
    timeAccumulator = 1 / SIM_HZ -- Make sure we update on the first frame
    frames = 0
    frameTimer = love.timer.getTime()
    currentFPS = 0
end

function love.joystickadded(joystick)
    -- If there is no current joystick
    if not JOYSTICK then
        -- Set the current joystick pointer to this new one
        JOYSTICK = joystick
    end

    -- If this joystick is not a recognized gamepad
    if not joystick:isGamepad() then
        for gamepadButton, index in pairs(JOYSTICK_BUTTON_MAP) do
            local success = love.joystick.setGamepadMapping(
                joystick:getGUID(), gamepadButton, 'button', index)

            if not success then
                print('failed to map input for button ' .. gamepadButton)
            end
        end

        for gamepadAxis, index in pairs(JOYSTICK_AXIS_MAP) do
            local success = love.joystick.setGamepadMapping(
                joystick:getGUID(), gamepadAxis, 'axis', index)
        end
    end
end

function love.gamepadaxis(joystick, axis, value)
    -- If your pet cat didn't accidentally bump the controller
    if math.abs(value) > AXIS_DEADZONE then
        -- Set the current joystick to this one
        JOYSTICK = joystick
    end
end

function love.gamepadpressed(joystick, button)
    -- Set the current joystick to this one
    JOYSTICK = joystick

    -- Send the button-press to the VirtualGamepad
    VIRTUAL_GAMEPAD:buttonpressed(button)
end

function love.update(dt)
    --require('lume.lurker').update()

    if dt > 0.25 then
        dt = 0.25 -- Avoid spiral of death
    end

    local stepTime = 1 / SIM_HZ

    timeAccumulator = timeAccumulator + dt
    while timeAccumulator >= stepTime do
        frames = frames + 1
        timeAccumulator = timeAccumulator - stepTime

        -- Process Input
        VIRTUAL_GAMEPAD:update()
        for i = 1, #room.sprites do
            room.sprites[i]:process_input()
        end

        -- Pre-update all systems
        for _, system in pairs(systems) do
            system:pre_update()
        end

        -- Update all systems
        for i = 1, #systemUpdateOrderMap do
            systemUpdateOrderMap[i]:update()
        end

        -- Post-update all systems
        for _, system in pairs(systems) do
            system:post_update()
        end

        -- Update sprites (TODO make this into a system)
        for i = 1, #room.sprites do
            local sprite = room.sprites[i]

            sprite:update_animation_state(stepTime)
            sprite:post_update_animation_state()
            sprite.skin:update(stepTime)
        end

        camera:update()
    end

    if love.timer.getTime() >= frameTimer + 1 then
        currentFPS = frames

        frameTimer = love.timer.getTime()
        frames = 0
    end
end

function love.keypressed(key)
    if love.keyboard.isDown('lctrl', 'rctrl') then
        if key == '-' and GRAPHICS_SCALE > 1 then
            set_window_scale(GRAPHICS_SCALE - 1)
            return
        elseif key == '+' or key == '=' then
            set_window_scale(GRAPHICS_SCALE + 1)
            return
        end

    end

    if key == 'f11' then
        set_fullscreen(not love.window.getFullscreen())
    else
        -- Disable joystick input
        JOYSTICK = nil
        
        -- Send the keypress to the VirtualGamepad
        VIRTUAL_GAMEPAD:keypressed(key)
    end
end

function draw_sprites()
    for i = 1, #room.sprites do
        local sprite = room.sprites[i]

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

        love.graphics.draw(TEXTURE, sprite.skin:get_quad(),
                           x, y,
                           0,
                           sx, 1)
    end
end

function draw_ground()
    local _, _, quadWidth = GROUND_QUAD:getViewport()
    local cameraPos = camera:get_screen_position()
    local x1 = cameraPos.x - (cameraPos.x % quadWidth)
    local x2 = cameraPos.x + BASE_SCREEN_W

    love.graphics.setColor(255, 255, 255)
    for x = x1, x2, quadWidth do
        love.graphics.draw(TEXTURE, GROUND_QUAD, x, BASE_SCREEN_H - 2)
    end
end

function draw_canvas_to_screen(shader)
    love.graphics.push()

    love.graphics.setCanvas()
    love.graphics.translate(GRAPHICS_X, GRAPHICS_Y)

    if shader then
        love.graphics.setShader(shader)
    end

    love.graphics.setColor(255, 255, 255)
    love.graphics.draw(CANVAS, 0, 0, 0, GRAPHICS_SCALE, GRAPHICS_SCALE)

    if shader then
        love.graphics.setShader()
    end

    love.graphics.pop()
end

function love.draw()
    determine_scale_and_letterboxing()

    -- Clear the screen
    love.graphics.setCanvas()
    love.graphics.setBackgroundColor(0, 0, 0)
    love.graphics.clear()

    -- Draw everything to the canvas, but with the disco platforms black
    love.graphics.push()
    love.graphics.setCanvas(CANVAS)
    love.graphics.setBackgroundColor(10, 10, 10, 255)
    love.graphics.setColor(255, 255, 255)
    love.graphics.clear()
    systems.star:draw()
    camera:transform()
    draw_ground()
    systems.texturedPlatform:draw()
    systems.discoPlatform:draw(true)
    love.graphics.setColor(255, 255, 255)
    systems.orderedDrawing:draw_background()
    draw_sprites()
    systems.orderedDrawing:draw_foreground()
    love.graphics.pop()

    -- Draw the canvas to the screen
    draw_canvas_to_screen()

    -- Draw the disco platforms on the screen, and redraw the things that are
    -- supposed to be in front of the disco platforms, but draw them in all
    -- black
    love.graphics.push()
    love.graphics.setCanvas(CANVAS)
    love.graphics.setBackgroundColor(0, 0, 0)
    love.graphics.clear()
    camera:transform()
    systems.discoPlatform:draw()
    love.graphics.setColor(0, 0, 0)
    systems.orderedDrawing:draw_background()
    draw_sprites()
    systems.orderedDrawing:draw_foreground()
    love.graphics.setColor(255, 255, 255)
    love.graphics.pop()

    -- Draw the canvas (with disco platforms on it) on the screen, with the
    -- bloom shader, using additive blend mode
    love.graphics.setBlendMode('additive')
    draw_canvas_to_screen(shaders.bloom)
    love.graphics.setBlendMode('alpha')

    -- Display FPS
    love.graphics.setColor(255, 255, 255)
    love.graphics.print('FPS: ' .. love.timer.getFPS(), 1, 1)
end
