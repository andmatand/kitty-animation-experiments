function box_overlap(sprite1, sprite2)
    if (sprite1.position.x + sprite1.size.w > sprite2.position.x and
        sprite1.position.x < sprite2.position.x + sprite2.size.w and
        sprite1.position.y + sprite1.size.h > sprite2.position.y and
        sprite1.position.y < sprite2.position.y + sprite2.size.h)
    then
        return true
    else
        return false
    end
end
