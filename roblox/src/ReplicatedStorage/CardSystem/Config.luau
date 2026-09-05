--!strict
--[[
	Config
	Every tunable number for the card system lives here.
	Shared between server and client, so both agree on timings and limits.
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

	-- Screen layout (pixels, authored against a 900px tall viewport) ------
	Layout = {
		HotbarSlot = 84,
		HotbarGap = 10,
		HotbarBottom = 16, -- gap from the bottom edge
		RollBottom = 106, -- the odds strip sits just above the hotbar
		SideButton = 62, -- the inventory button on the left edge
	},

	-- Hotbar --------------------------------------------------------------
	Hotbar = {
		Slots = 6,
	},

	-- Inventory -----------------------------------------------------------
	Inventory = {
		Columns = 5,
		VisibleRows = 3,
		SlotSize = 92,
		SlotGap = 8,
		PanelPadding = 12,
	},

	-- Showcase -------------------------------------------------------------
	Showcase = {
		Distance = 8,
		Size = Vector3.new(5.4, 3.4, 0.2),
		SpinSpeed = 0.35, -- radians per second
		BobHeight = 0.15,
		BobSpeed = 1.6,
	},

	-- The stock Roblox backpack sits exactly where our hotbar goes.
	HideDefaultBackpack = true,

	-- Freeze the character while a hand of cards or the showcase is up, so
	-- walking away cannot leave the cards behind you.
	LockMovementDuringCards = true,

	-- Keys -----------------------------------------------------------------
	Keys = {
		Roll = Enum.KeyCode.R,
		Inventory = Enum.KeyCode.E,
	},

	-- Sounds (leave "" to stay silent) -----------------------------------
	Sounds = {
		Roll = "",
		Flip = "",
		Select = "",
		Rare = "",
		Open = "",
		Close = "",
	},
}

return table.freeze(Config)
