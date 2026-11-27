--!strict
-- ChibiAvatars (Server Script)
-- Place in: ServerScriptService
--
-- On join and on every respawn, turns each player's own avatar into a chibi
-- plush version: tiny squat body, giant head, plus big glossy black eyes.
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
	-- Plush-toy proportions: a tiny, squat, chubby body under a huge head
	HeightScale = 0.55, -- overall body height (1 = normal)
	WidthScale = 1.2, -- wider = chubbier
	DepthScale = 1.2,
	HeadScale = 2, -- giant plush head
	BodyTypeScale = 0, -- 0 = blocky/childlike proportions
	ProportionScale = 0, -- 0 = wider, less lanky
}

local EYE_SETTINGS = {
	-- Big glossy black eyes with a cluster of white highlights on top
	-- and a few small white dots near the bottom. No colour anywhere.
	EyeTop = Color3.fromRGB(0, 0, 0), -- gradient top of the eye (pure black)
	EyeBottom = Color3.fromRGB(70, 70, 70), -- gradient bottom (soft dark grey glow)
	Lash = Color3.fromRGB(0, 0, 0), -- heavy top lash line
	Highlight = Color3.fromRGB(255, 255, 255),
	SparkleColor = Color3.fromRGB(255, 255, 255),
	HideOriginalFace = true, -- remove the avatar's own face (brows, eyes, mouth) so only these eyes show
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

local function dot(parent: Instance, name: string, x: number, y: number, w: number, h: number)
	local d = Instance.new("Frame")
	d.Name = name
	d.AnchorPoint = Vector2.new(0.5, 0.5)
	d.Position = UDim2.fromScale(x, y)
	d.Size = UDim2.fromScale(w, h)
	d.BackgroundColor3 = EYE_SETTINGS.Highlight
	d.BorderSizePixel = 0
	d.ZIndex = 3
	round(d)
	d.Parent = parent
	return d
end

local function makeEye(parent: Instance, centerX: number, isLeft: boolean)
	-- x positions below are written for the left eye; the right eye mirrors them
	local function mx(x: number): number
		return if isLeft then x else 1 - x
	end

	-- The eye: a big, wide black oval with a soft grey glow at the bottom
	local eye = Instance.new("Frame")
	eye.Name = isLeft and "LeftEye" or "RightEye"
	eye.AnchorPoint = Vector2.new(0.5, 0.5)
	eye.Position = UDim2.fromScale(centerX, 0.56)
	eye.Size = UDim2.fromScale(0.4, 0.46)
	eye.BackgroundColor3 = Color3.new(1, 1, 1)
	eye.BorderSizePixel = 0
	eye.ClipsDescendants = false
	round(eye)
	local grad = Instance.new("UIGradient")
	grad.Rotation = 90
	grad.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, EYE_SETTINGS.EyeTop),
		ColorSequenceKeypoint.new(0.6, EYE_SETTINGS.EyeTop),
		ColorSequenceKeypoint.new(1, EYE_SETTINGS.EyeBottom),
	})
	grad.Parent = eye
	eye.Parent = parent

	-- Heavy lash line across the top so the eye looks droopy and soft
	local lash = Instance.new("Frame")
	lash.Name = "Lash"
	lash.AnchorPoint = Vector2.new(0.5, 0)
	lash.Position = UDim2.fromScale(0.5, -0.04)
	lash.Size = UDim2.fromScale(1.06, 0.3)
	lash.BackgroundColor3 = EYE_SETTINGS.Lash
	lash.BorderSizePixel = 0
	lash.ZIndex = 2
	round(lash)
	lash.Parent = eye

	-- Cloud-shaped cluster of highlights near the top, toward the nose
	local c1 = dot(eye, "ShineA", mx(0.56), 0.2, 0.2, 0.17)
	local c2 = dot(eye, "ShineB", mx(0.7), 0.17, 0.15, 0.13)
	local c3 = dot(eye, "ShineC", mx(0.44), 0.24, 0.12, 0.1)
	dot(eye, "ShineD", mx(0.8), 0.24, 0.08, 0.07)

	-- A few small dots near the bottom
	local d1 = dot(eye, "GlintA", mx(0.8), 0.64, 0.1, 0.09)
	local d2 = dot(eye, "GlintB", mx(0.24), 0.8, 0.09, 0.08)
	dot(eye, "GlintC", mx(0.48), 0.84, 0.06, 0.05)

	twinkle(c1, isLeft and 0 or 0.3)
	twinkle(c2, isLeft and 0.2 or 0.5)
	twinkle(c3, isLeft and 0.4 or 0.1)
	twinkle(d1, isLeft and 0.45 or 0.15)
	twinkle(d2, isLeft and 0.7 or 0.35)
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
		-- Wipe everything off the face so only the chibi eyes show.
		-- Classic heads draw the face with Decals; 3D/dynamic heads bake the
		-- eyebrows, eyes and mouth into a SurfaceAppearance or mesh texture.
		for _, child in head:GetChildren() do
			if child:IsA("Decal") then
				child.Transparency = 1
			elseif child:IsA("SurfaceAppearance") or child:IsA("FaceControls") then
				child:Destroy()
			end
		end
		if head:IsA("MeshPart") then
			(head :: MeshPart).TextureID = ""
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

	makeEye(gui, 0.27, true)
	makeEye(gui, 0.73, false)

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
