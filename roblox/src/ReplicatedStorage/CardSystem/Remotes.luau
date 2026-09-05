--!strict
--[[
	Remotes
	One place that names the network surface. The server creates the objects,
	the client waits for them.

	client -> server : RequestRoll()             ask for a new hand
	                   SelectCard(rollId, slot)  keep one card from the hand
	                   EquipCard(slot, cardId)   put a card on the hotbar
	                                             (cardId nil clears the slot)
	server -> client : RollResult(rollId, {cardId})
	                   RollRejected(reason, retryAfterSeconds)
	                   SelectionResult(ok, cardId, slot)
	                   ProfileSync(profile)      counts, xp and hotbar
	                   Notice(text, isError)     one-line toast
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local FOLDER_NAME = "CardRemotes"
local EVENT_NAMES = {
	"RequestRoll",
	"RollResult",
	"RollRejected",
	"SelectCard",
	"SelectionResult",
	"EquipCard",
	"ProfileSync",
	"Notice",
}

export type Remotes = {
	RequestRoll: RemoteEvent,
	RollResult: RemoteEvent,
	RollRejected: RemoteEvent,
	SelectCard: RemoteEvent,
	SelectionResult: RemoteEvent,
	EquipCard: RemoteEvent,
	ProfileSync: RemoteEvent,
	Notice: RemoteEvent,
}

local cached: Remotes? = nil

local function build(): Remotes
	local remotes = {}

	if RunService:IsServer() then
		local folder = ReplicatedStorage:FindFirstChild(FOLDER_NAME)
		if not folder then
			folder = Instance.new("Folder")
			folder.Name = FOLDER_NAME
			folder.Parent = ReplicatedStorage
		end

		for _, name in EVENT_NAMES do
			local event = folder:FindFirstChild(name)
			if not event then
				event = Instance.new("RemoteEvent")
				event.Name = name
				event.Parent = folder
			end
			remotes[name] = event
		end
	else
		local folder = ReplicatedStorage:WaitForChild(FOLDER_NAME)
		for _, name in EVENT_NAMES do
			remotes[name] = folder:WaitForChild(name)
		end
	end

	return (remotes :: any) :: Remotes
end

return {
	get = function(): Remotes
		if not cached then
			cached = build()
		end
		return (cached :: any) :: Remotes
	end,
}
