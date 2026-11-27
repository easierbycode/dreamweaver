--!strict
-- ChibiAvatars (Server Script)
-- Place in: ServerScriptService
--
-- On join and on every respawn, turns each player's own avatar into a chibi
-- version: short, slim body with a big head, plus big sparkly black anime eyes.
-- Their clothing, accessories, skin colour and animations are kept, because
-- we start from the avatar they already have and only change the scales.
--
-- Body scaling needs R15 avatars (Game Settings > Avatar > Avatar Type: R15).
-- R6 characters still get the sparkly eyes, just not the resize.

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

---------------------------------------------------------------------------
-- Tweak these to taste
---------------------------------------------------------------------------
local CHIBI_SCALES = {
	HeightScale = 0.75, -- overall body height (1 = normal)
	WidthScale = 0.85,
	DepthScale = 0.85,
	HeadScale = 1.45, -- big head
	BodyTypeScale = 0, -- 0 = blocky/childlike proportions
	ProportionScale = 0, -- 0 = wider, less lanky
}

local EYE_SETTINGS = {
	IrisTop = Color3.fromRGB(45, 45, 45), -- gradient top of the iris (dark grey)
	IrisBottom = Color3.fromRGB(0, 0, 0), -- gradient bottom of the iris (black)
	Outline = Color3.fromRGB(0, 0, 0),
	Pupil = Color3.fromRGB(255, 255, 255), -- white dot in the middle
	SparkleColor = Color3.fromRGB(255, 255, 255),
	HideOriginalFace = true, -- hide the classic face decal so eyes don't overlap
	Sparkles = true, -- tiny glitter particles around the eyes
}

local CHIBI_ATTRIBUTE = "ChibiApplied"

---------------------------------------------------------------------------
-- Sparkly eyes (built from GUI frames, so no image uploads are needed)
---------------------------------------------------------------------------
local function round(parent: Instance, radius: UDim?)
	local c = Instance.new("UICorner")
	c.CornerRadius = radius or UDim.new(0.5, 0)
	c.Parent = parent
end

local function twinkle(obj: GuiObject, delay: number)
	-- Gentle pulsing highlight, repeating forever (cleaned up with the character)
	local info = TweenInfo.new(0.9, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true, delay)
	TweenService:Create(obj, info, { BackgroundTransparency = 0.45 }):Play()
end

local function makeEye(parent: Instance, centerX: number, isLeft: boolean)
	-- Outer eye (dark outline / sclera edge)
	local eye = Instance.new("Frame")
	eye.Name = isLeft and "LeftEye" or "RightEye"
	eye.AnchorPoint = Vector2.new(0.5, 0.5)
	eye.Position = UDim2.fromScale(centerX, 0.55)
	eye.Size = UDim2.fromScale(0.3, 0.42)
	eye.BackgroundColor3 = EYE_SETTINGS.Outline
	eye.BorderSizePixel = 0
	round(eye)
	eye.Parent = parent

	-- Iris with a vertical colour gradient
	local iris = Instance.new("Frame")
	iris.Name = "Iris"
	iris.AnchorPoint = Vector2.new(0.5, 0.5)
	iris.Position = UDim2.fromScale(0.5, 0.52)
	iris.Size = UDim2.fromScale(0.82, 0.86)
	iris.BackgroundColor3 = Color3.new(1, 1, 1)
	iris.BorderSizePixel = 0
	round(iris)
	local grad = Instance.new("UIGradient")
	grad.Rotation = 90
	grad.Color = ColorSequence.new(EYE_SETTINGS.IrisTop, EYE_SETTINGS.IrisBottom)
	grad.Parent = iris
	iris.Parent = eye

	-- Pupil
	local pupil = Instance.new("Frame")
	pupil.Name = "Pupil"
	pupil.AnchorPoint = Vector2.new(0.5, 0.5)
	pupil.Position = UDim2.fromScale(0.5, 0.55)
	pupil.Size = UDim2.fromScale(0.18, 0.16)
	pupil.BackgroundColor3 = EYE_SETTINGS.Pupil
	pupil.BorderSizePixel = 0
	round(pupil)
	pupil.Parent = iris

	-- Big highlight (upper corner, toward the outside of the face)
	local big = Instance.new("Frame")
	big.Name = "Shine"
	big.AnchorPoint = Vector2.new(0.5, 0.5)
	big.Position = UDim2.fromScale(isLeft and 0.32 or 0.68, 0.3)
	big.Size = UDim2.fromScale(0.38, 0.32)
	big.BackgroundColor3 = Color3.new(1, 1, 1)
	big.BorderSizePixel = 0
	big.ZIndex = 3
	round(big)
	big.Parent = iris

	-- Small highlight (lower, opposite side)
	local small = Instance.new("Frame")
	small.Name = "Glint"
	small.AnchorPoint = Vector2.new(0.5, 0.5)
	small.Position = UDim2.fromScale(isLeft and 0.68 or 0.32, 0.72)
	small.Size = UDim2.fromScale(0.16, 0.14)
	small.BackgroundColor3 = Color3.new(1, 1, 1)
	small.BorderSizePixel = 0
	small.ZIndex = 3
	round(small)
	small.Parent = iris

	twinkle(big, isLeft and 0 or 0.3)
	twinkle(small, isLeft and 0.45 or 0.15)
end

local function addSparklyEyes(character: Model)
	local head = character:FindFirstChild("Head")
	if not head or not head:IsA("BasePart") then
		return
	end

	-- Remove old eyes if this runs twice on the same head
	local old = head:FindFirstChild("ChibiEyes")
	if old then
		old:Destroy()
	end

	if EYE_SETTINGS.HideOriginalFace then
		local face = head:FindFirstChild("face")
		if face and face:IsA("Decal") then
			face.Transparency = 1
		end
	end

	local gui = Instance.new("SurfaceGui")
	gui.Name = "ChibiEyes"
	gui.Face = Enum.NormalId.Front
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 100
	gui.LightInfluence = 0.3
	gui.ZOffset = 1
	gui.Adornee = head
	gui.Parent = head

	makeEye(gui, 0.3, true)
	makeEye(gui, 0.7, false)

	if EYE_SETTINGS.Sparkles then
		local att = Instance.new("Attachment")
		att.Name = "ChibiSparkleAttachment"
		att.Position = Vector3.new(0, 0, -head.Size.Z * 0.5)
		att.Parent = head

		-- The default ParticleEmitter texture is already a sparkle
		local p = Instance.new("ParticleEmitter")
		p.Name = "ChibiSparkles"
		p.Rate = 3
		p.Lifetime = NumberRange.new(0.6, 1.1)
		p.Speed = NumberRange.new(0.2, 0.6)
		p.SpreadAngle = Vector2.new(180, 180)
		p.Size = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0),
			NumberSequenceKeypoint.new(0.3, 0.18),
			NumberSequenceKeypoint.new(1, 0),
		})
		p.Color = ColorSequence.new(EYE_SETTINGS.SparkleColor)
		p.LightEmission = 1
		p.Parent = att
	end
end

---------------------------------------------------------------------------
-- Chibi body (scales on the player's own HumanoidDescription)
---------------------------------------------------------------------------
local function applyChibiBody(humanoid: Humanoid)
	if humanoid.RigType ~= Enum.HumanoidRigType.R15 then
		return -- R6 can't be rescaled this way
	end

	local ok, desc = pcall(function()
		return humanoid:GetAppliedDescription()
	end)
	if not ok or not desc then
		warn("[ChibiAvatars] Could not read avatar description:", desc)
		return
	end

	for prop, value in CHIBI_SCALES do
		(desc :: any)[prop] = value
	end

	local applied, err = pcall(function()
		humanoid:ApplyDescription(desc)
	end)
	if not applied then
		warn("[ChibiAvatars] ApplyDescription failed:", err)
	end
end

local function chibify(character: Model)
	if character:GetAttribute(CHIBI_ATTRIBUTE) then
		return
	end
	character:SetAttribute(CHIBI_ATTRIBUTE, true)

	local humanoid = character:WaitForChild("Humanoid", 10)
	if not humanoid or not humanoid:IsA("Humanoid") then
		return
	end

	-- ApplyDescription only works once the character is in the workspace
	while not character:IsDescendantOf(workspace) do
		character.AncestryChanged:Wait()
	end
	-- Let the avatar finish loading its accessories first
	if not character:FindFirstChild("Head") then
		character:WaitForChild("Head", 5)
	end
	task.wait(0.1)

	applyChibiBody(humanoid)
	-- ApplyDescription can rebuild the head, so add the eyes afterwards
	addSparklyEyes(character)
end

local function onPlayerAdded(player: Player)
	player.CharacterAdded:Connect(function(character)
		task.spawn(chibify, character)
	end)
	if player.Character then
		task.spawn(chibify, player.Character)
	end
end

Players.PlayerAdded:Connect(onPlayerAdded)
for _, player in Players:GetPlayers() do
	task.spawn(onPlayerAdded, player)
end
