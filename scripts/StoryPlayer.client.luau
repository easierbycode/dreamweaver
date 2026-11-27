-- StoryPlayer (LocalScript)
-- Place in: StarterPlayer > StarterPlayerScripts
--
-- Shows a story on screen: a picture on the top 2/3 and a dialog box on the
-- bottom 1/3. Words appear typewriter style, and the player presses NEXT
-- (or Enter / Space / the gamepad A button) to move on.
--
-- The stories themselves are written in ReplicatedStorage.StoryData, and the
-- server decides when to play them (see ServerScriptService.StoryService).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TextService = game:GetService("TextService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local StoryData = require(ReplicatedStorage:WaitForChild("StoryData"))
local remotes = ReplicatedStorage:WaitForChild("StoryRemotes")
local PlayStory = remotes:WaitForChild("PlayStory") :: RemoteEvent
local StoryFinished = remotes:WaitForChild("StoryFinished") :: RemoteEvent

local SETTINGS = StoryData.Settings or {}
local CHARS_PER_SECOND = SETTINGS.CharactersPerSecond or 38
local PUNCTUATION_PAUSE = SETTINGS.PunctuationPause or 0.18
local NEXT_TEXT = SETTINGS.NextButtonText or "NEXT"
local LAST_TEXT = SETTINGS.LastButtonText or "START"
local ALLOW_SKIP = SETTINGS.AllowSkip ~= false

local TEXT_FONT = Enum.Font.GothamMedium
local SPEAKER_COLOR = Color3.fromRGB(255, 214, 102)
local PANEL_COLOR = Color3.fromRGB(16, 16, 24)

---------------------------------------------------------------------------
-- Building the screen
---------------------------------------------------------------------------
local function make(className: string, props: { [string]: any }, parent: Instance?): any
	local obj = Instance.new(className)
	for k, v in props do
		(obj :: any)[k] = v
	end
	obj.Parent = parent
	return obj
end

local function corner(parent: Instance, radius: UDim)
	make("UICorner", { CornerRadius = radius }, parent)
end

local gui = make("ScreenGui", {
	Name = "StoryPlayer",
	IgnoreGuiInset = true,
	ResetOnSpawn = false,
	DisplayOrder = 100,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	Enabled = false,
}, player:WaitForChild("PlayerGui"))

local root = make("CanvasGroup", {
	Name = "Root",
	Size = UDim2.fromScale(1, 1),
	BackgroundColor3 = Color3.new(0, 0, 0),
	BorderSizePixel = 0,
	GroupTransparency = 0,
}, gui)

-- Top 2/3: the picture
local imageArea = make("Frame", {
	Name = "ImageArea",
	Size = UDim2.fromScale(1, 2 / 3),
	BackgroundColor3 = Color3.new(0, 0, 0),
	BorderSizePixel = 0,
	ClipsDescendants = true,
}, root)

-- Drawn when a section has no image: a night sky with the radio tower
local function buildPlaceholder(parent: Instance): Frame
	local scene = make("Frame", {
		Name = "PlaceholderScene",
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color3.new(1, 1, 1),
		BorderSizePixel = 0,
	}, parent)
	make("UIGradient", {
		Rotation = 90,
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(6, 8, 28)),
			ColorSequenceKeypoint.new(0.6, Color3.fromRGB(34, 26, 72)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(86, 48, 92)),
		}),
	}, scene)

	-- Stars
	local rng = Random.new(7)
	for i = 1, 45 do
		local s = rng:NextInteger(2, 4)
		local star = make("Frame", {
			Name = "Star",
			Position = UDim2.fromScale(rng:NextNumber(), rng:NextNumber() * 0.7),
			Size = UDim2.fromOffset(s, s),
			BackgroundColor3 = Color3.new(1, 1, 1),
			BackgroundTransparency = rng:NextNumber(0, 0.4),
			BorderSizePixel = 0,
		}, scene)
		corner(star, UDim.new(1, 0))
		local info = TweenInfo.new(rng:NextNumber(0.8, 2), Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true, rng:NextNumber(0, 2))
		TweenService:Create(star, info, { BackgroundTransparency = 0.85 }):Play()
	end

	-- Moon
	local moon = make("Frame", {
		Name = "Moon",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.2, 0.22),
		Size = UDim2.fromScale(0.12, 0.12),
		BackgroundColor3 = Color3.fromRGB(245, 240, 220),
		BorderSizePixel = 0,
	}, scene)
	make("UIAspectRatioConstraint", { AspectRatio = 1, DominantAxis = Enum.DominantAxis.Height }, moon)
	corner(moon, UDim.new(1, 0))

	local silhouette = Color3.fromRGB(5, 5, 12)

	-- Ground
	make("Frame", {
		Name = "Ground",
		Position = UDim2.fromScale(0, 0.86),
		Size = UDim2.fromScale(1, 0.14),
		BackgroundColor3 = silhouette,
		BorderSizePixel = 0,
	}, scene)

	-- Radio tower: two leaning legs, cross bars and a blinking light
	local towerX, towerTop, towerBottom = 0.64, 0.12, 0.87
	local height = towerBottom - towerTop
	for _, side in { -1, 1 } do
		make("Frame", {
			Name = "TowerLeg",
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(towerX + side * 0.028, towerTop + height / 2),
			Size = UDim2.new(0, 5, height, 0),
			Rotation = -side * 3.2,
			BackgroundColor3 = silhouette,
			BorderSizePixel = 0,
		}, scene)
	end
	for i = 1, 8 do
		local y = towerTop + height * (i / 9)
		make("Frame", {
			Name = "TowerBar",
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(towerX, y),
			Size = UDim2.new(0.012 + 0.06 * (i / 9), 0, 0, 3),
			BackgroundColor3 = silhouette,
			BorderSizePixel = 0,
		}, scene)
	end
	local light = make("Frame", {
		Name = "TowerLight",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(towerX, towerTop - 0.01),
		Size = UDim2.fromOffset(9, 9),
		BackgroundColor3 = Color3.fromRGB(255, 60, 60),
		BorderSizePixel = 0,
	}, scene)
	corner(light, UDim.new(1, 0))
	TweenService:Create(
		light,
		TweenInfo.new(0.7, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
		{ BackgroundTransparency = 0.9 }
	):Play()

	return scene
end

local placeholder = buildPlaceholder(imageArea)

local image = make("ImageLabel", {
	Name = "SectionImage",
	Size = UDim2.fromScale(1, 1),
	BackgroundTransparency = 1,
	ScaleType = Enum.ScaleType.Crop,
	Visible = false,
}, imageArea)

local title = make("TextLabel", {
	Name = "Title",
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.45),
	Size = UDim2.fromScale(0.9, 0.22),
	BackgroundTransparency = 1,
	Font = Enum.Font.GothamBlack,
	TextScaled = true,
	TextColor3 = Color3.new(1, 1, 1),
	TextStrokeTransparency = 0.3,
	Text = "",
	Visible = false,
	ZIndex = 3,
}, imageArea)
make("UITextSizeConstraint", { MaxTextSize = 110 }, title)

local skipButton = make("TextButton", {
	Name = "Skip",
	AnchorPoint = Vector2.new(1, 0),
	Position = UDim2.new(1, -16, 0, 16),
	Size = UDim2.fromOffset(84, 34),
	BackgroundColor3 = Color3.new(0, 0, 0),
	BackgroundTransparency = 0.5,
	Font = Enum.Font.GothamBold,
	TextSize = 16,
	TextColor3 = Color3.new(1, 1, 1),
	Text = "Skip",
	Visible = ALLOW_SKIP,
	ZIndex = 4,
}, imageArea)
corner(skipButton, UDim.new(0, 8))

-- Bottom 1/3: the dialog box
local panel = make("Frame", {
	Name = "DialogPanel",
	Position = UDim2.fromScale(0, 2 / 3),
	Size = UDim2.fromScale(1, 1 / 3),
	BackgroundColor3 = PANEL_COLOR,
	BorderSizePixel = 0,
}, root)
make("Frame", {
	Name = "TopEdge",
	Size = UDim2.new(1, 0, 0, 3),
	BackgroundColor3 = Color3.new(1, 1, 1),
	BackgroundTransparency = 0.75,
	BorderSizePixel = 0,
}, panel)

local content = make("Frame", {
	Name = "Content",
	Size = UDim2.fromScale(1, 1),
	BackgroundTransparency = 1,
}, panel)
make("UIPadding", {
	PaddingTop = UDim.new(0.1, 0),
	PaddingBottom = UDim.new(0.1, 0),
	PaddingLeft = UDim.new(0.05, 0),
	PaddingRight = UDim.new(0.05, 0),
}, content)

local speakerLabel = make("TextLabel", {
	Name = "Speaker",
	Size = UDim2.fromScale(0.6, 0.2),
	BackgroundTransparency = 1,
	Font = Enum.Font.GothamBold,
	TextScaled = true,
	TextXAlignment = Enum.TextXAlignment.Left,
	TextColor3 = SPEAKER_COLOR,
	Text = "",
}, content)
make("UITextSizeConstraint", { MaxTextSize = 30 }, speakerLabel)

local textLabel = make("TextLabel", {
	Name = "Dialog",
	BackgroundTransparency = 1,
	Font = TEXT_FONT,
	TextWrapped = true,
	TextXAlignment = Enum.TextXAlignment.Left,
	TextYAlignment = Enum.TextYAlignment.Top,
	TextColor3 = Color3.new(1, 1, 1),
	Text = "",
}, content)

local nextButton = make("TextButton", {
	Name = "Next",
	AnchorPoint = Vector2.new(1, 1),
	Position = UDim2.fromScale(1, 1),
	Size = UDim2.fromScale(0.16, 0.2),
	BackgroundColor3 = Color3.new(1, 1, 1),
	Font = Enum.Font.GothamBold,
	TextScaled = true,
	TextColor3 = PANEL_COLOR,
	Text = NEXT_TEXT,
}, content)
corner(nextButton, UDim.new(0.25, 0))
make("UISizeConstraint", { MinSize = Vector2.new(96, 34) }, nextButton)
make("UITextSizeConstraint", { MaxTextSize = 24 }, nextButton)
make("UIPadding", {
	PaddingTop = UDim.new(0.18, 0),
	PaddingBottom = UDim.new(0.18, 0),
}, nextButton)

---------------------------------------------------------------------------
-- Text fitting: split a section's text into pages that fit the dialog box
---------------------------------------------------------------------------
local function dialogTextSize(): number
	local camera = workspace.CurrentCamera
	local h = camera and camera.ViewportSize.Y or 720
	return math.clamp(math.floor(h * 0.034), 16, 36)
end

local function paginate(text: string): { string }
	local width = textLabel.AbsoluteSize.X
	local height = textLabel.AbsoluteSize.Y
	if width <= 0 or height <= 0 then
		return { text }
	end
	local size = textLabel.TextSize
	local function fits(s: string): boolean
		return TextService:GetTextSize(s, size, TEXT_FONT, Vector2.new(width, 100000)).Y <= height
	end
	if fits(text) then
		return { text }
	end

	local pages = {}
	local current = ""
	for _, word in string.split(text, " ") do
		local candidate = if current == "" then word else current .. " " .. word
		if current == "" or fits(candidate) then
			current = candidate
		else
			table.insert(pages, current)
			current = word
		end
	end
	if current ~= "" then
		table.insert(pages, current)
	end
	return pages
end

---------------------------------------------------------------------------
-- Input and the typewriter
---------------------------------------------------------------------------
local typing = false
local skipTyping = false
local skipAll = false
local advance = Instance.new("BindableEvent")

local function onNextPressed()
	if not gui.Enabled then
		return
	end
	if typing then
		skipTyping = true -- first press finishes the line
	else
		advance:Fire()
	end
end

nextButton.Activated:Connect(onNextPressed)
skipButton.Activated:Connect(function()
	skipAll = true
	skipTyping = true
	advance:Fire()
end)
UserInputService.InputBegan:Connect(function(input)
	if not gui.Enabled then
		return
	end
	local key = input.KeyCode
	if key == Enum.KeyCode.Return or key == Enum.KeyCode.Space or key == Enum.KeyCode.ButtonA then
		onNextPressed()
	end
end)

local function isPause(ch: string): boolean
	return ch == "." or ch == "," or ch == "!" or ch == "?" or ch == ";" or ch == ":"
end

local function typeOut(page: string)
	textLabel.Text = page
	textLabel.MaxVisibleGraphemes = 0
	nextButton.BackgroundTransparency = 0.45

	local total = utf8.len(page) or #page
	local shown = 0
	local carry = 0
	local lastPaused = 0
	typing = true
	skipTyping = false

	while shown < total and not skipTyping do
		carry += RunService.Heartbeat:Wait() * CHARS_PER_SECOND
		while carry >= 1 and shown < total do
			carry -= 1
			shown += 1
		end
		textLabel.MaxVisibleGraphemes = shown

		-- Short breath after punctuation
		local offset = utf8.offset(page, shown)
		local ch = if offset then string.sub(page, offset, offset) else ""
		if shown > lastPaused and shown < total and isPause(ch) then
			lastPaused = shown
			local waited = 0
			while waited < PUNCTUATION_PAUSE and not skipTyping do
				waited += RunService.Heartbeat:Wait()
			end
			carry = 0
		end
	end

	textLabel.MaxVisibleGraphemes = -1
	nextButton.BackgroundTransparency = 0
	typing = false
end

---------------------------------------------------------------------------
-- Pictures
---------------------------------------------------------------------------
local function resolveImage(value: any): string?
	if typeof(value) == "number" then
		return "rbxassetid://" .. tostring(value)
	elseif typeof(value) == "string" and value ~= "" then
		if string.match(value, "^%d+$") then
			return "rbxassetid://" .. value
		end
		return value
	end
	return nil
end

local function showImage(id: string?)
	if id then
		if image.Image ~= id or not image.Visible then
			image.Image = id
			image.ImageTransparency = 1
			image.Visible = true
			TweenService:Create(image, TweenInfo.new(0.4), { ImageTransparency = 0 }):Play()
		end
		placeholder.Visible = false
	else
		image.Visible = false
		placeholder.Visible = true
	end
end

local function layoutFor(section: any)
	local hasSpeaker = typeof(section.Speaker) == "string" and section.Speaker ~= ""
	speakerLabel.Visible = hasSpeaker
	speakerLabel.Text = if hasSpeaker then section.Speaker else ""
	if hasSpeaker then
		textLabel.Position = UDim2.fromScale(0, 0.26)
		textLabel.Size = UDim2.fromScale(1, 0.5)
	else
		textLabel.Position = UDim2.fromScale(0, 0)
		textLabel.Size = UDim2.fromScale(1, 0.76)
	end
	textLabel.TextSize = dialogTextSize()

	local hasTitle = typeof(section.Title) == "string" and section.Title ~= ""
	title.Visible = hasTitle
	title.Text = if hasTitle then section.Title else ""
end

---------------------------------------------------------------------------
-- Playing a story
---------------------------------------------------------------------------
-- Stop the player walking around while the story is on screen
local controls = nil
task.spawn(function()
	local module = player:WaitForChild("PlayerScripts"):WaitForChild("PlayerModule", 5)
	if module then
		pcall(function()
			controls = (require(module :: any) :: any):GetControls()
		end)
	end
end)

local savedSpeed, savedJump = nil, nil
local function freezePlayer(frozen: boolean)
	if controls then
		if frozen then
			controls:Disable()
		else
			controls:Enable()
		end
		return
	end
	-- Fallback when the game has no default PlayerModule
	local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return
	end
	if frozen then
		savedSpeed, savedJump = humanoid.WalkSpeed, humanoid.JumpHeight
		humanoid.WalkSpeed, humanoid.JumpHeight = 0, 0
	elseif savedSpeed then
		humanoid.WalkSpeed, humanoid.JumpHeight = savedSpeed, savedJump
		savedSpeed, savedJump = nil, nil
	end
end

local playing = false

local function playStory(stage: number)
	while playing do
		task.wait(0.2)
	end
	local story = StoryData.Stages[stage]
	if not story or not story.Sections or #story.Sections == 0 then
		StoryFinished:FireServer(stage)
		return
	end
	playing = true
	skipAll = false

	freezePlayer(true)
	root.GroupTransparency = 1
	gui.Enabled = true
	TweenService:Create(root, TweenInfo.new(0.5), { GroupTransparency = 0 }):Play()

	local sections = story.Sections
	for i, section in sections do
		if skipAll then
			break
		end
		showImage(resolveImage(section.Image) or resolveImage(story.DefaultImage))
		layoutFor(section)
		task.wait() -- let the layout settle before measuring the text box

		local pages = paginate(tostring(section.Text or ""))
		for p, page in pages do
			if skipAll then
				break
			end
			local isLast = i == #sections and p == #pages
			nextButton.Text = if isLast then LAST_TEXT else NEXT_TEXT
			typeOut(page)
			if skipAll then
				break
			end
			advance.Event:Wait()
		end
	end

	local fade = TweenService:Create(root, TweenInfo.new(0.4), { GroupTransparency = 1 })
	fade:Play()
	fade.Completed:Wait()
	gui.Enabled = false
	textLabel.Text = ""
	freezePlayer(false)
	playing = false
	StoryFinished:FireServer(stage)
end

PlayStory.OnClientEvent:Connect(function(stage)
	if typeof(stage) == "number" then
		playStory(stage)
	end
end)
