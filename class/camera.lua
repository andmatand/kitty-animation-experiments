Camera = Object:extend()

function Camera:new()
    self.box = {x = 0, y = 0, w = BASE_SCREEN_W / 4, h = BASE_SCREEN_H / 2}

    -- Automatically center the box (x, y) position based on the width
    self.box.x = (BASE_SCREEN_W / 2) - (self.box.w / 2)
    self.box.y = (BASE_SCREEN_H / 2) - (self.box.h / 2)

    self.position = {x = 0, y = 0}
    self.velocity = {x = 0, y = 0}
end

function Camera:screen_scroll(player)
    local target = {x = player.position.x + player.skin:get_width() / 2,
                    y = player.position.y + player.skin:get_height() / 2}

    local screen = self:get_screen_position()
    screen.w = BASE_SCREEN_W
    screen.h = BASE_SCREEN_H
    print(screen.x, screen.y)

    if target.x < screen.x then
        self.velocity.x = -BASE_SCREEN_W
    elseif target.x > screen.x + screen.w then
        self.velocity.x = BASE_SCREEN_W
    end

    if target.y < screen.y then
        self.velocity.y = -BASE_SCREEN_H
    elseif target.y > screen.y + screen.h then
        self.velocity.y = BASE_SCREEN_H
    end
end

function Camera:move_toward(player)
    local x1, x2, y1, y2
    x1 = math.floor(player.position.x)
    x2 = math.floor(player.position.x + player.skin:get_width() - 1)
    y1 = math.floor(player.position.y)
    y2 = math.floor(player.position.y + player.skin:get_height() - 1)

    if x1 < self.position.x then
        local distance = math.abs(self.position.x - x1)

        if distance <= PlayerPhysicsSystem.MAX_VELOCITY_X then
            -- Move the camera locked with the player
            self.velocity.x = -distance
        else
            -- Move the camera smoothly up to the player
            self.velocity.x = -distance * .25
        end
    elseif x2 > self.position.x + self.box.w - 1 then
        local distance = math.abs(x2 - (self.position.x + self.box.w - 1))

        if distance <= PlayerPhysicsSystem.MAX_VELOCITY_X then
            -- Move the camera locked with the player
            self.velocity.x = distance
        else
            -- Move the camera smoothly up to the player
            self.velocity.x = distance * .25
        end
    end

    if y1 < self.position.y then
        local distance = math.abs(self.position.y - y1)

        --if -distance < self.velocity.y and player.onPlatform then
        if player.onPlatform then
            -- Move the camera smoothly up to the player
            self.velocity.y = -distance * .25
        end
    elseif y2 > self.position.y + self.box.h - 1 then
        local distance = math.abs(y2 - (self.position.y + self.box.h - 1))

        --if distance > self.velocity.y then
            -- Move the camera locked with the player
            self.velocity.y = distance
        --end
    end
end

-- Draw a debug view of camera's box
function Camera:draw()
    love.graphics.push()

    love.graphics.setColor(255, 0, 0)
    love.graphics.rectangle('line',
        self.box.x, self.box.y,
        self.box.w, self.box.h)

    love.graphics.pop()
end

function Camera:update(player)
    self:move_toward(player)
    --self:screen_scroll(player)
    self:do_physics()
end

function Camera:do_physics()
    self.position.x = self.position.x + self.velocity.x
    self.position.y = self.position.y + self.velocity.y

    -- Apply friction
    self.velocity.x = 0
    self.velocity.y = 0

    -- Don't go lower than the ground
    local maxY = self.box.y + 1
    if math.floor(self.position.y) > maxY then
        self.position.y = maxY
    end
end

function Camera:translate()
    local pos = self:get_screen_position()

    love.graphics.translate(-pos.x, -pos.y)
end

function Camera:get_screen_position()
    return {x = math.floor(self.position.x - self.box.x),
            y = math.floor(self.position.y - self.box.y)}
end

function Camera:get_position()
    return {x = self.position.x, y = self.position.y}
end
