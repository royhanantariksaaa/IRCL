return function(object, properties)
    if not object or typeof(object) ~= "Instance" then return end
    for key, value in pairs(properties) do
        object[key] = value
    end
    return object
end