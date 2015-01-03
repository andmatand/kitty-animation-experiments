Camera = Object:extend()

function Camera:new()
    self.zoom = 1
    self.box = {position = {x = 0, y = 0},
                size = {w = BASE_SCREEN_W / 4,
                        h = BASE_SCREEN_H / 3}}
    self.box.size.originalW = self.box.size.w
    self.box.size.originalH = self.box.size.h

    -- Automatically center the box (x, y) position based on the width
    self:refresh_box()

    self.position = {x = 0, y = 0}
    self.velocity = {x = 0, y = 0}
end

function Camera:set_player(player)
    self.player = player
end

function Camera:get_center_box()
    return {position = {x = self.position.x + self.box.position.x,
                        y = self.position.y + self.box.position.y},
            size = {w = self.box.size.w,
                    h = self.box.size.h}}
end

function Camera:refresh_box()
    self.box.size.w = self.box.size.originalW / self.zoom
    self.box.size.h = self.box.size.originalH / self.zoom
    self.box.position.x =
        ((BASE_SCREEN_W / self.zoom) / 2) - (self.box.size.w / 2)
    self.box.position.y =
        ((BASE_SCREEN_H / self.zoom) / 2) - (self.box.size.h / 2)
end

function Camera:get_zoom(value)
    return self.zoom
end

function Camera:set_zoom(value)
    self.zoom = value

    self:refresh_box()
    self:warp_to_player()
end

function Camera:get_player_center()
    return {x = self.player.position.x + self.player.skin:get_width() / 2,
            y = self.player.position.y + self.player.skin:get_height() / 2}
end

function Camera:screen_scroll()
    local target = self:get_player_center()

    local screen = self:get_screen_position()
    screen.w = BASE_SCREEN_W
    screen.h = BASE_SCREEN_H

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

function Camera:follow_player()
    local target = {
        x1 = self.player.position.x,
        x2 = self.player.position.x + self.player.skin:get_width() - 1,
        y1 = self.player.position.y,
        y2 = self.player.position.y + self.player.skin:get_height() - 1}
    target.x1 = math.floor(target.x1)
    target.x2 = math.floor(target.x2)
    target.y1 = math.floor(target.y1)
    target.y2 = math.floor(target.y2)

    local box = self:get_center_box()

    if target.x1 < box.position.x then
        local distance = math.abs(box.position.x - target.x1)

        if distance <= PlayerPhysicsSystem.MAX_VELOCITY_X then
            -- Move the camera locked with the player
            self.velocity.x = -distance
        else
            -- Move the camera smoothly up to the player
            self.velocity.x = -distance * .25
        end
    elseif target.x2 > box.position.x + box.size.w - 1 then
        local distance = math.abs(target.x2 - (box.position.x + box.size.w - 1))

        if distance <= PlayerPhysicsSystem.MAX_VELOCITY_X then
            -- Move the camera locked with the player
            self.velocity.x = distance
        else
            -- Move the camera smoothly up to the player
            self.velocity.x = distance * .25
        end
    end

    if target.y1 < box.position.y then
        local distance = math.abs(box.position.y - target.y1)

        if self.player.isOnPlatform then
            -- Move the camera smoothly up to the player
            self.velocity.y = -distance * .25
        end
    elseif target.y2 > box.position.y + box.size.h - 1 then
        local distance = math.abs(target.y2 - (box.position.y + box.size.h - 1))

        -- Move the camera locked with the player
        self.velocity.y = distance
    end
end

-- Draw a debug view of camera's box
function Camera:draw()
    love.graphics.push()

    love.graphics.scale(self.zoom, self.zoom)

    love.graphics.setLineWidth(1)

    love.graphics.setColor(255, 0, 0)
    love.graphics.rectangle('line',
        self.box.position.x + .5, self.box.position.y + .5,
        self.box.size.w, self.box.size.h)

    love.graphics.pop()
end

function Camera:update(player)
    self:follow_player()
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
    local maxY = BASE_SCREEN_H - (BASE_SCREEN_H / self.zoom) + 1
    maxY = math.floor(maxY)
    if self.position.y > maxY then
        self.position.y = maxY
    end
end

function Camera:transform(parallax)
    if not parallax then
        parallax = 1
    end

    local pos = self:get_screen_position()
    love.graphics.translate(-pos.x * self.zoom * parallax,
                            -pos.y * self.zoom * parallax)

    love.graphics.scale(self.zoom, self.zoom)
end

function Camera:warp_to_player()
    local target = self:get_player_center()

    self.position.x = target.x - self.box.position.x - (self.box.size.w / 2)
    self.position.y = target.y - self.box.position.y - (self.box.size.h / 2)
end

function Camera:get_screen_position()
    return {x = math.floor(self.position.x),
            y = math.floor(self.position.y)}
end
