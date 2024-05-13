local Commands = {
    Admin = {

    },
    Public = {

    }
}
Commands.__index = Commands

function Commands:FindCommand(player, cmd)
    for i,v in self.Admin do
        local Command = i:lower():sub(1, #cmd)
        if Command == cmd then
            return i, v, true
        else
            print(Command, "Not the command")
        end
    end
    for i,v in self.Public do
        local Command = i:lower():sub(1, #cmd)
        if Command == cmd then
            return i, v, false
        else
            print("Not the command")
        end
    end
    print(self.Public, self.Admin)
    return nil
end

function Commands:RegisterCommand(name, AdminCommand, func)
    if AdminCommand then
        self.Admin[name] = func
    else
        self.Public[name] = func
    end
end

return Commands