-- StoryData (ModuleScript)
-- Place in: ReplicatedStorage
--
-- Every story that plays before a stage lives here.
--
-- To add a story before another stage, copy the Stages[1] block, change the
-- number to the stage it should play before (Stages[2], Stages[3], ...), and
-- write its sections.
--
-- A section can have:
--   Text    = "What appears in the dialog box" (required)
--   Speaker = "Name shown above the text"     (optional, leave out for narration)
--   Image   = "rbxassetid://123456" or 123456 (optional, the picture on the top 2/3)
--   Title   = "Big words over the picture"    (optional, e.g. "STAGE 1")
--
-- Sections without an Image use the stage's DefaultImage. If that is empty
-- too, a simple night-sky radio tower scene is drawn instead.
--
-- Long text is fine: anything that doesn't fit in the dialog box is split
-- onto extra pages automatically, so nothing is ever cut off.

return {
	Settings = {
		CharactersPerSecond = 38, -- typewriter speed
		PunctuationPause = 0.18, -- extra pause after . , ! ? …
		NextButtonText = "NEXT",
		LastButtonText = "START",
		AllowSkip = true, -- show a small "Skip" button
	},

	Stages = {
		[1] = {
			Name = "The Radio Tower",
			DefaultImage = nil, -- e.g. "rbxassetid://123456789"
			Sections = {
				{
					Text = "Every summer night, Eli and Milo slipped past the rusty gate and climbed to the very top of the old radio tower.",
				},
				{
					Text = "Up there the whole town looked like a toy set. They counted the blinking lights, traded secrets, and promised they would always come back.",
				},
				{
					Text = "Then one morning, Milo was gone. Nobody could say how. Nobody could say why.",
				},
				{
					Text = "The tower went quiet after that. Eli stopped climbing.",
				},
				{
					Text = "Until the night Milo came back... in a dream.",
				},
				{
					Speaker = "Milo",
					Text = "Eli. Hey. You still remember the way up, right?",
				},
				{
					Speaker = "Eli",
					Text = "Milo? But you're... how are you here?",
				},
				{
					Speaker = "Milo",
					Text = "No time. Something is hidden in this town. A puzzle. And I'm only one piece of it.",
				},
				{
					Speaker = "Milo",
					Text = "Solve it, and you'll find out what really happened to me. But be careful. It goes deeper than you could ever imagine.",
				},
				{
					Text = "Eli woke with a start. The old walkie-talkie on his shelf was crackling, and a voice he had never heard read out a place and a time.",
				},
				{
					Title = "STAGE 1",
					Text = "He didn't know it yet, but his first mission had already begun.",
				},
			},
		},

		-- Example: a story that plays before stage 2
		-- [2] = {
		-- 	Name = "Stage 2 title",
		-- 	DefaultImage = "rbxassetid://123456789",
		-- 	Sections = {
		-- 		{ Text = "First line of the stage 2 story." },
		-- 		{ Speaker = "Milo", Text = "Something Milo says.", Image = 123456789 },
		-- 	},
		-- },
	},
}
