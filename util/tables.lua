function tables_have_equal_values(t1, t2)
    for k, v in pairs(t1) do
        if v ~= t2[k] then
            return false
        end
    end

    return true
end

function copy_table(t1)
    t2 = {}

    for k, v in pairs(t1) do
        t2[k] = v
    end

    return t2
end
