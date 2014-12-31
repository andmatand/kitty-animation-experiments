function box_overlap(box1, box2)
    if (box1.position.x + box1.size.w > box2.position.x and
        box1.position.x < box2.position.x + box2.size.w and
        box1.position.y + box1.size.h > box2.position.y and
        box1.position.y < box2.position.y + box2.size.h)
    then
        return true
    else
        return false
    end
end

function box_overlap_margin(box1, box2, margin)
    local newBox1 = {
        position = {x = box1.position.x - margin.w,
                    y = box1.position.y - margin.h},
        size = {w = box1.size.w + margin.w,
                h = box1.size.h + margin.h}}
    local newBox2 = {
        position = {x = box2.position.x - margin.w,
                    y = box2.position.y - margin.h},
        size = {w = box2.size.w + margin.w,
                h = box2.size.h + margin.h}}

    return box_overlap(newBox1, newBox2)
end
