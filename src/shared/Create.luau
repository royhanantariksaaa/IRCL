return function(class, properties)
    local object = Instance.new(class)
    for key, value in pairs(properties) do
        object[key] = value
    end
    return object
end