--!native
--!optimize 2
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local types = require(script.Parent.Parent.types)
local read = require(script.Parent.read)
local bufferWriter = require(script.Parent.bufferWriter)

local alloc = bufferWriter.alloc
local u8 = bufferWriter.u8
local load = bufferWriter.load

-- All channelData is set to nil upon being sent which is why these are all optionals
local perPlayerReliable: { [Player]: types.channelData } = {}
local perPlayerUnreliable: { [Player]: types.channelData } = {}
local perPlayerExceptionReliable: { [Player]: types.channelData } = {}
local perPlayerExceptionUnreliable: { [Player]: types.channelData } = {}

-- Shared with: src/process/client.luau (Infeasible to split this into another file)
local function create()
	return {
		cursor = 0,
		size = 256,
		references = {},
		buff = buffer.create(256),
	}
end

local function dump(channel: types.channelData): (buffer, { unknown }?)
	local cursor = channel.cursor
	local dumpBuffer = buffer.create(cursor)

	buffer.copy(dumpBuffer, 0, channel.buff, 0, cursor)

	return dumpBuffer, if #channel.references > 0 then channel.references else nil
end
-- No longer shared

local globalReliable: types.channelData = create()
local globalUnreliable: types.channelData = create()
local listReliable: types.channelData = create()
local listUnreliable: types.channelData = create()
local listOfListsReliable: {Player} = {}
local listOfListsUnreliable: {Player} = {}

-- TODO handle invalid data better
local function onServerEvent(player: Player, data, references)
	-- Only accept buffer data
	if not (typeof(data) == "buffer") then
		return
	end

	read(data, references, player)
end

local function playerAdded(player)
	if not perPlayerReliable[player] then
		perPlayerReliable[player] = create()
		perPlayerExceptionReliable[player] = create()
	end

	if not perPlayerUnreliable[player] then
		perPlayerUnreliable[player] = create()
		perPlayerExceptionUnreliable[player] = create()
	end
end

local checkIfListHasSameValueAsList = function(list1, list2)
	for i, value in ipairs(list1) do
		if not table.find(list2, value) then
			return nil
		end
	end
	return list2
end

local function loadListOnList(newList, List)
	local doesItExist = true
	for _, player in ipairs(newList) do
		for _, otherList in ipairs(List) do
			local checkOnOtherList = checkIfListHasSameValueAsList(otherList, player)
			if checkOnOtherList then
				table.remove(List, checkOnOtherList)
			end
		end
	end	
end

-- local function loadList(newList, List)
-- 	local doesItExist = true
-- 	for _, player in ipairs(newList) do
-- 		for _, otherList in ipairs(List) do
-- 			local checkOnOtherList = table.find(otherList, player)
-- 		end
-- 	end	

-- end

local serverProcess = {}

function serverProcess.sendAllReliable(id: number, writer: (value: any) -> (), data: { [string]: any })
	load(globalReliable)
	
	alloc(1)
	u8(id)
	writer(data)
	
	globalReliable = bufferWriter.export()
end

function serverProcess.sendAllUnreliable(id: number, writer: (value: any) -> (), data: { [string]: any })
	load(globalUnreliable)

	alloc(1)
	u8(id)
	writer(data)

	globalUnreliable = bufferWriter.export()
end

function serverProcess.sendListReliable(players: { Player }, id: number, writer: (value: any) -> (), data: { [string]: any })
	load(listReliable)
	alloc(1)
	u8(id)
	writer(data)
	listReliable = bufferWriter.export()
	for _, player in ipairs(players) do
		if not table.find(listOfListsReliable, player) then
			table.insert(listOfListsReliable, player)
		end
	end
end

function serverProcess.sendListUnreliable(players: { Player }, id: number, writer: (value: any) -> (), data: { [string]: any })
	load(listUnreliable)
	alloc(1)
	u8(id)
	writer(data)
	listUnreliable = bufferWriter.export()
	for _, player in ipairs(players) do
		if not table.find(listOfListsUnreliable, player) then
			table.insert(listOfListsUnreliable, player)
		end
	end
end

function serverProcess.sendPlayerReliableExcept(
	player: Player,
	id: number,
	writer: (value: any) -> (),
	data: { [string]: any }
)
	playerAdded(player)
	load(perPlayerExceptionReliable[player])

	alloc(1)
	u8(id)
	writer(data)

	perPlayerExceptionReliable[player] = bufferWriter.export()
end

function serverProcess.sendPlayerUnreliableExcept(
	player: Player,
	id: number,
	writer: (value: any) -> (),
	data: { [string]: any }
)
	playerAdded(player)
	load(perPlayerExceptionUnreliable[player])

	alloc(1)
	u8(id)
	writer(data)
	perPlayerExceptionUnreliable[player] = bufferWriter.export()
end


function serverProcess.sendPlayerReliable(
	player: Player,
	id: number,
	writer: (value: any) -> (),
	data: { [string]: any }
)
	playerAdded(player)
	load(perPlayerReliable[player])
	
	alloc(1)
	u8(id)
	writer(data)
	perPlayerReliable[player] = bufferWriter.export()
end

function serverProcess.sendPlayerUnreliable(
	player: Player,
	id: number,
	writer: (value: any) -> (),
	data: { [string]: any }
)
	playerAdded(player)
	load(perPlayerUnreliable[player] )

	alloc(1)
	u8(id)
	writer(data)
	perPlayerUnreliable[player] = bufferWriter.export()
end

function serverProcess.start()
	local reliableRemote = Instance.new("RemoteEvent")
	reliableRemote.Name = "ByteNetReliable"
	reliableRemote.OnServerEvent:Connect(onServerEvent)
	reliableRemote.Parent = ReplicatedStorage

	local unreliableRemote = Instance.new("UnreliableRemoteEvent")
	unreliableRemote.Name = "ByteNetUnreliable"
	unreliableRemote.OnServerEvent:Connect(onServerEvent)
	unreliableRemote.Parent = ReplicatedStorage

	for _, player in Players:GetPlayers() do
		playerAdded(player)
	end

	Players.PlayerAdded:Connect(playerAdded)

	RunService.Heartbeat:Connect(function()
		if globalReliable.cursor > 0 then
			local b, r = dump(globalReliable)
			reliableRemote:FireAllClients(b, r)

			globalReliable.cursor = 0
			table.clear(globalReliable.references)
		end

		if globalUnreliable.cursor > 0 then
			local b, r = dump(globalUnreliable)
			
			unreliableRemote:FireAllClients(b, r)

			globalUnreliable.cursor = 0
			table.clear(globalUnreliable.references)
		end

		if listReliable.cursor > 0 then
			local b, r = dump(listReliable)
			for i, player in ipairs(listOfListsReliable) do
				reliableRemote:FireClient(player, b, r)
				table.remove(listOfListsReliable, i)
			end

			listReliable.cursor = 0
			table.clear(listReliable.references)
		end

		if listUnreliable.cursor > 0 then
			local b, r = dump(listUnreliable)
			for i, player in ipairs(listOfListsUnreliable) do
				unreliableRemote:FireClient(player, b, r)
				table.remove(listOfListsUnreliable, i)
			end

			listUnreliable.cursor = 0
			table.clear(listUnreliable.references)
		end
		for _, player in Players:GetPlayers() do
			if perPlayerReliable[player].cursor > 0 then
				local b, r = dump(perPlayerReliable[player])
				reliableRemote:FireClient(player, b, r)

				perPlayerReliable[player].cursor = 0
				table.clear(perPlayerReliable[player].references)
			end

			if perPlayerUnreliable[player].cursor > 0 then
				local b, r = dump(perPlayerUnreliable[player])
				unreliableRemote:FireClient(player, b, r)
				-- print(b, r, player.Name)
				perPlayerUnreliable[player].cursor = 0
				table.clear(perPlayerUnreliable[player].references)
			end

			if perPlayerExceptionReliable[player].cursor > 0 then
				local b, r = dump(perPlayerExceptionReliable[player])
				perPlayerExceptionReliable[player].cursor = 0
				for _, otherPlayer in Players:GetPlayers() do
					if otherPlayer ~= player then
						reliableRemote:FireClient(otherPlayer, b, r)
					end
				end

				perPlayerExceptionReliable[player].cursor = 0
				table.clear(perPlayerExceptionReliable[player].references)
			end

			if perPlayerExceptionUnreliable[player].cursor > 0 then
				local b, r = dump(perPlayerExceptionUnreliable[player])
				for _, otherPlayer in Players:GetPlayers() do
					if otherPlayer ~= player then
						unreliableRemote:FireClient(otherPlayer, b, r)
						-- print(b, r[1].Name, otherPlayer.Name)
					end
				end

				perPlayerExceptionUnreliable[player].cursor = 0
				table.clear(perPlayerExceptionUnreliable[player].references)
			end
		end

	end)
end

return serverProcess
