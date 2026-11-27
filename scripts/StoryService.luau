-- StoryService (ModuleScript)
-- Place in: ServerScriptService
--
-- Plays the story for a stage on one player's screen and waits until they
-- finish it. Use it from any server script before a stage starts:
--
--   local StoryService = require(game.ServerScriptService.StoryService)
--   StoryService.playBeforeStage(player, 2) -- yields until the story ends
--   -- ...now start stage 2 for this player
--
-- Stories are written in ReplicatedStorage.StoryData.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local StoryData = require(ReplicatedStorage:WaitForChild("StoryData"))

local MAX_WAIT_SECONDS = 15 * 60 -- give up waiting after this long

-- Remotes the StoryPlayer LocalScript listens on
local remotes = ReplicatedStorage:FindFirstChild("StoryRemotes")
if not remotes then
	remotes = Instance.new("Folder")
	remotes.Name = "StoryRemotes"
	remotes.Parent = ReplicatedStorage
end

local function getRemote(name: string): RemoteEvent
	local r = remotes:FindFirstChild(name)
	if not r then
		r = Instance.new("RemoteEvent")
		r.Name = name
		r.Parent = remotes
	end
	return r :: RemoteEvent
end

local PlayStory = getRemote("PlayStory")
local StoryFinished = getRemote("StoryFinished")

local StoryService = {}

-- waiting[player][stage] = BindableEvent fired when that story ends
local waiting: { [Player]: { [number]: BindableEvent } } = {}

StoryFinished.OnServerEvent:Connect(function(player, stage)
	local list = waiting[player]
	local done = list and list[stage]
	if done then
		done:Fire()
	end
end)

Players.PlayerRemoving:Connect(function(player)
	local list = waiting[player]
	if list then
		for _, done in list do
			done:Fire()
		end
	end
	waiting[player] = nil
end)

function StoryService.hasStory(stage: number): boolean
	local s = StoryData.Stages[stage]
	return s ~= nil and s.Sections ~= nil and #s.Sections > 0
end

-- Shows the story that plays before `stage` and waits until the player
-- presses through it (or leaves). Returns right away if there is no story.
function StoryService.playBeforeStage(player: Player, stage: number)
	if not StoryService.hasStory(stage) or not player.Parent then
		return
	end

	waiting[player] = waiting[player] or {}
	local done = Instance.new("BindableEvent")
	waiting[player][stage] = done

	local finished = false
	local conn = done.Event:Connect(function()
		finished = true
	end)

	PlayStory:FireClient(player, stage)

	local started = os.clock()
	while not finished and os.clock() - started < MAX_WAIT_SECONDS do
		task.wait(0.2)
	end

	conn:Disconnect()
	done:Destroy()
	if waiting[player] then
		waiting[player][stage] = nil
	end
end

return StoryService
