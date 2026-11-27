-- StoryStarter (Server Script)
-- Place in: ServerScriptService
--
-- Plays the Stage 1 story when a player joins. When stages are built, call
-- StoryService.playBeforeStage(player, stageNumber) right before each stage
-- starts, the same way this script does for stage 1.

local Players = game:GetService("Players")
local StoryService = require(script.Parent:WaitForChild("StoryService"))

local FIRST_STAGE = 1

local function onPlayerAdded(player: Player)
	-- Wait for the first character so the screen is ready
	if not player.Character then
		player.CharacterAdded:Wait()
	end
	task.wait(1)

	StoryService.playBeforeStage(player, FIRST_STAGE)
	-- Stage 1 would start here
end

Players.PlayerAdded:Connect(onPlayerAdded)
for _, player in Players:GetPlayers() do
	task.spawn(onPlayerAdded, player)
end
