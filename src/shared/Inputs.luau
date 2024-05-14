local UserInputService = game:GetService("UserInputService")
 
local Input = {
    InputBegans ={ },
    InputChangeds = { },
    InputEnds = { }
}
Input.__index = Input

function Input.GetMouseLocation()
    return UserInputService:GetMouseLocation()
end

function Input.OnKeyDown(keyCode, callback)
    table.insert(Input.InputBegans, {keyCode, callback})
end

function Input.OnBegin(inputType, callback)
    table.insert(Input.InputBegans, {inputType, callback})
end

function Input.OnChanged(inputType, callback)
    table.insert(Input.InputChangeds, {inputType, callback})
end

function Input.OnKeyReleased(keyCode, callback)
    table.insert(Input.InputEnds, {keyCode, callback})
end

function Input.OnEnd(inputType, callback)
    table.insert(Input.InputEnds, {inputType, callback})
end

function Input.Update()
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        for _, inputBegan in ipairs(Input.InputBegans) do
            if inputBegan[1] == input.UserInputType or inputBegan[1] == input.KeyCode then
                inputBegan[2]()
            end
        end
    end)
    UserInputService.InputChanged:Connect(function(input, gameProcessed)
        for _, inputChanged in ipairs(Input.InputChangeds) do
            if inputChanged[1] == input.UserInputType or inputChanged[1] == input.KeyCode then
                inputChanged[2]()
            end
        end
    end)
    UserInputService.InputEnded:Connect(function(input, gameProcessed)
        for _, inputEnd in ipairs(Input.InputEnds) do
            if inputEnd[1] == input.UserInputType or inputEnd[1] == input.KeyCode then
                inputEnd[2]()
            end
        end
    end)
end

Input.Update()

return Input