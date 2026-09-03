--!strict
--[[
	Config
	Every tunable number for the card roll system lives here.
	Shared between server and client, so both agree on timings.
]]

local Config = {
	-- Roll rules -------------------------------------------------------
	CardsPerRoll = 3, -- how many cards are dealt each roll
	RollCooldown = 2, -- seconds a player must wait between rolls
	PityRolls = 12, -- rolls without a Rare+ before one is guaranteed (0 disables)
	PityMinimumRarity = "Rare",

	-- Card geometry (studs) --------------------------------------------
	CardSize = Vector3.new(3.8, 5.3, 0.16),
	CardSpacing = 4.3, -- centre-to-centre distance between cards
	CameraDistance = 9, -- how far in front of the camera the hand spawns
	CameraHeightOffset = 0.4, -- lift the hand slightly above eye level
	PixelsPerStud = 110, -- SurfaceGui resolution

	-- Animation ---------------------------------------------------------
	EnterDuration = 0.45,
	EnterStagger = 0.13, -- delay between each card entering
	EnterDrop = 4, -- studs the card rises from
	EnterScale = 0.82, -- starting size multiplier
	FlipDuration = 0.55,
	FlipStagger = 0.24, -- delay between each card flipping face up
	ExitDuration = 0.5,

	-- Interaction --------------------------------------------------------
	MaxTilt = math.rad(15), -- how far a card leans toward the cursor
	TiltSmoothing = 10, -- higher = snappier tilt
	HoverPop = 0.5, -- studs a hovered card moves toward the camera
	HoverScale = 1.06,
	HoverLift = 0.25, -- studs a hovered card rises

	-- Sounds (leave "" to stay silent) -----------------------------------
	Sounds = {
		Roll = "",
		Flip = "",
		Select = "",
		Rare = "",
	},
}

return table.freeze(Config)
