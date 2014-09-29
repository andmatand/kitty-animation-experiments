Camera = Object:extend()

function Camera:new()
    self.boxOffset = {x = BASE_SCREEN_W / 4, y = BASE_SCREEN_H / 6}
    self.box = {x = 0, y = 0,
                w = BASE_SCREEN_W / 2, h = BASE_SCREEN_H / 1.5}
end

function Camera:update(dt, player)
    local target = {x = player.position.x + (player.skin:get_width() / 2),
                    y = player.position.y + (player.skin:get_height() / 2)}

    local x1, x2, y1, y2
    x1 = math.floor(player.position.x)
    x2 = math.floor(player.position.x + player.skin:get_width() - 1)
    y1 = math.floor(player.position.y)
    y2 = math.floor(player.position.y + player.skin:get_height() - 1)

    if x1 < self.box.x then
        self.box.x = self.box.x - 1
    elseif x2 > self.box.x + self.box.w - 1 then
        self.box.x = self.box.x + 1
    end

    local dist = {y = target.y - (self.box.y + (self.box.h / 2))}
    if y1 < self.box.y or y2 > self.box.y + self.box.h - 1 then
        self.box.y = self.box.y + (dist.y * .1)
    end

    -- Don't let the camera go lower than the ground
    local maxBoxY = BASE_SCREEN_H - self.boxOffset.y - self.box.h + 1
    if math.floor(self.box.y) > maxBoxY then
        self.box.y = maxBoxY
    end
end

function Camera:translate()
    --if DEBUG then
    --    love.graphics.setColor(255, 0, 0)
    --    love.graphics.rectangle('line',
    --                            self.boxOffset.x,
    --                            self.boxOffset.y,
    --                            self.box.w,
    --                            self.box.h)
    --end

    --love.graphics.translate(math.floor(-self.box.x + self.boxOffset.x),
    --                        math.floor(-self.box.y + self.boxOffset.y))
    love.graphics.translate(-self.box.x + self.boxOffset.x,
                            -self.box.y + self.boxOffset.y)
end

function Camera:get_position()
    return {x = self.box.x - self.boxOffset.x, y = y}
end
