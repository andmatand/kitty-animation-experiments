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
require('system.disco-platform')
require('system.star')
require('system.suspension-platform')
require('system.textured-platform')
require('system.player-physics')

function love.load()
    love.mouse.setVisible(false)
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

    soundSources = {jump = love.audio.newSource('asset/jump.wav')}

    systems = {}
    systems.discoPlatform = DiscoPlatformSystem()
    systems.playerPhysics = PlayerPhysicsSystem()
    systems.star = StarSystem()
    systems.suspensionPlatform = SuspensionPlatformSystem()
    systems.texturedPlatform = TexturedPlatformSystem()

    -- Assign explicit update-order to systems that require it
    systemUpdateOrderMap = {
        systems.playerPhysics,
        systems.suspensionPlatform}

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
        a = {'k', 'space'},
        start = 'f5',
        back = 'escape'
    }

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

    room = {}
    room.sprites = {}
    room.platforms = {}

    room.sprites[1] = Kitty()
    VIRTUAL_GAMEPAD = VirtualGamepad(room.sprites[1].inputBuffer)
    room.sprites[1].virtualGamepad = VIRTUAL_GAMEPAD

    systems.playerPhysics:add_entity(room.sprites[1])

    for i = 1, #systems.discoPlatform.entities do
        local e = systems.discoPlatform.entities[i]
        systems.suspensionPlatform:add_entity(e)
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

    camera = Camera()


    SIM_HZ = 60
    timeAccumulator = 0
    frames = 0
    frameTimer = love.timer.getTime()
    currentFPS = 0
end

function love.joystickadded(joystick)
    if joystick:isGamepad() then
        -- If there is no current gamepad
        if not GAMEPAD then
            -- Set the current gamepad to this new one
            GAMEPAD = joystick
            JOYSTICK = nil
        end
    else
        -- If there is no current joystick or gamepad
        if not JOYSTICK and not GAMEPAD then
            -- Set the current joystick to this new one
            JOYSTICK = joystick
            GAMEPAD = nil
        end
    end
end

function love.joystickpressed(joystick, button)
    if joystick == GAMEPAD then return end

    -- Set the current joystick to this one
    JOYSTICK = joystick
    GAMEPAD = nil

    VIRTUAL_GAMEPAD:joystickpressed(joystick, button)
end

function love.gamepadpressed(joystick, button)
    print('gamepadpressed')
    -- Set the current gamepad to this one
    GAMEPAD = joystick
    JOYSTICK = nil

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

        -- Pre-update all systems
        for _, system in pairs(systems) do
            system:pre_update()
        end

        -- Process Input
        for i = 1, #room.sprites do
            room.sprites[i]:process_input()
        end

        -- Update all systems
        for i = 1, #systemUpdateOrderMap do
            systemUpdateOrderMap[i]:update()
        end

        -- Update sprites (TODO make this into a system)
        for i = 1, #room.sprites do
            local sprite = room.sprites[i]

            sprite:update_animation_state(stepTime)
            sprite:post_update_animation_state()
            sprite.skin:update(stepTime)
        end

        camera:update(room.sprites[1])
    end

    if love.timer.getTime() >= frameTimer + 1 then
        currentFPS = frames

        frameTimer = love.timer.getTime()
        frames = 0
    end
end

function love.keypressed(key)
    if key == 'f11' then
        set_fullscreen(not love.window.getFullscreen())
    else
        -- Disable gamepad and joystick input
        GAMEPAD = nil
        JOYSTICK = nil
        
        VIRTUAL_GAMEPAD:keypressed(key)
    end
end

function draw_sprites()
    love.graphics.setColor(255, 255, 255)

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

    love.graphics.setColor(255, 255, 255, 255)
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

    love.graphics.draw(CANVAS, 0, 0, 0, GRAPHICS_SCALE, GRAPHICS_SCALE)

    if shader then
        love.graphics.setShader()
    end

    love.graphics.pop()
end

function love.draw()
    determine_scale_and_letterboxing()

    love.graphics.setBackgroundColor(0, 0, 0)
    love.graphics.clear()

    -- Draw the platforms and stars on the canvas
    love.graphics.push()
    love.graphics.setCanvas(CANVAS)
    love.graphics.setBackgroundColor(10, 10, 10, 255)
    love.graphics.clear()
    systems.star:draw()
    camera:translate()
    systems.discoPlatform:draw()
    love.graphics.pop()

    -- Draw the canvas (with disco platforms and stars on it) on the screen,
    -- with the bloom shader
    draw_canvas_to_screen(shaders.bloom)

    -- Draw the textured platforms, ground, and sprites on the canvas
    love.graphics.push()
    love.graphics.setCanvas(CANVAS)
    love.graphics.setBackgroundColor(0, 0, 0, 0)
    love.graphics.clear()
    camera:translate()
    systems.texturedPlatform:draw()
    draw_ground()
    draw_sprites()
    love.graphics.pop()

    -- Draw the sprite canvas on the screen
    draw_canvas_to_screen()

    -- Display FPS
    love.graphics.setColor(255, 255, 255)
    love.graphics.print('FPS: ' .. love.timer.getFPS(), 1, 1)
end
