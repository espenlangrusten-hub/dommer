--!strict
--[[
	Theme
	One place for the look: palette, font, and the small builders every panel
	uses. Keeping it here means the roll cards, the inventory and the hotbar
	cannot drift apart.

	The style is the chunky cartoon game-UI look: near-black panels, a thick
	saturated border, bold rounded text with a heavy black outline, and gold
	count numbers.
]]

local Theme = {}

Theme.Font = Enum.Font.FredokaOne
Theme.FontFallback = Enum.Font.GothamBold

Theme.Colors = {
	PanelBody = Color3.fromRGB(17, 18, 24),
	PanelBodyDeep = Color3.fromRGB(10, 11, 15),
	PanelBorder = Color3.fromRGB(86, 224, 34),
	PanelBorderDark = Color3.fromRGB(44, 130, 14),
	HeaderLight = Color3.fromRGB(140, 240, 60),
	HeaderDark = Color3.fromRGB(70, 190, 22),
	Text = Color3.fromRGB(255, 255, 255),
	TextDim = Color3.fromRGB(186, 192, 204),
	Outline = Color3.fromRGB(0, 0, 0),
	Count = Color3.fromRGB(255, 178, 24),
	Close = Color3.fromRGB(228, 46, 46),
	CloseDark = Color3.fromRGB(140, 20, 20),
	SlotEmpty = Color3.fromRGB(24, 26, 33),
	Search = Color3.fromRGB(16, 17, 22),
	Equip = Color3.fromRGB(70, 180, 255),
	Danger = Color3.fromRGB(228, 78, 78),
}

--[[
	Optional tiling dot texture for the halftone pattern the reference UI uses
	behind every slot. Upload one and paste its id here to get that exact look;
	while it is empty the slots fall back to a two-stop gradient, which reads
	almost the same at slot size.
]]
Theme.DotTexture = ""
Theme.DotTileSize = UDim2.fromOffset(16, 16)
Theme.DotTransparency = 0.86

--[[
	Uploaded artwork. Paste Roblox image ids as "rbxassetid://123456789".
	Every entry is optional: an empty string keeps the drawn fallback, so the
	UI works with no art at all and improves one id at a time.
]]
Theme.Images = {
	-- Replaces the drawn roll button. The word ROLL is expected to be part of
	-- the artwork, so the button's own text is hidden when this is set.
	RollButton = "",

	-- One frame per hotbar slot, in order. Slots left empty keep the drawn
	-- frame, so a partial set is fine.
	HotbarSlots = { "", "", "", "", "", "" },
}

--[[
	Shape of the hotbar slot artwork.

	BodyHeightRatio is how much of the image's height the square body takes up.
	Art with a tab or ear sticking out of the top - a slot number, a ribbon -
	is taller than its body, and this lets the body line up with the slot while
	the tab overhangs. 1 means the art is all body.

	WidthRatio does the same for width when the art overhangs sideways.
]]
Theme.SlotArt = {
	BodyHeightRatio = 0.857,
	WidthRatio = 1.05,

	--[[
		Tint slot art by rarity. Image tinting multiplies, so it only works on
		art whose body is white or near white: black outlines stay black and
		the body takes the rarity colour, giving every tier from one image.
		Leave false for art that is already coloured, which would go muddy.
	]]
	Tint = false,
}

-- Instance helper ---------------------------------------------------------
function Theme.make(className: string, props: { [string]: any }, children: { any }?): any
	local instance = Instance.new(className)
	local parent = props.Parent
	for key, value in props do
		if key ~= "Parent" then
			(instance :: any)[key] = value
		end
	end
	if children then
		for _, child in children do
			child.Parent = instance
		end
	end
	-- Parent last so the engine does not replicate every later property.
	if parent then
		instance.Parent = parent
	end
	return instance
end

local make = Theme.make

--[[
	corner and gradient return `any` on purpose. They are almost always the
	first entry in a mixed children array, and Luau types an array literal from
	its first element - a precise return here would make every
	`{ Theme.corner(8), Theme.stroke(...), ... }` fail to type check.
]]
function Theme.corner(radius: number): any
	return make("UICorner", { CornerRadius = UDim.new(0, radius) })
end

function Theme.stroke(color: Color3, thickness: number, transparency: number?): UIStroke
	return make("UIStroke", {
		Color = color,
		Thickness = thickness,
		Transparency = transparency or 0,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		LineJoinMode = Enum.LineJoinMode.Round,
	})
end

function Theme.gradient(top: Color3, bottom: Color3, rotation: number?): any
	return make("UIGradient", {
		Rotation = rotation or 90,
		Color = ColorSequence.new(top, bottom),
	})
end

-- Bold text with the heavy black outline the reference UI uses everywhere.
function Theme.label(props: { [string]: any }, outlineThickness: number?): TextLabel
	local merged: { [string]: any } = {
		BackgroundTransparency = 1,
		Font = Theme.Font,
		TextColor3 = Theme.Colors.Text,
		TextScaled = true,
	}
	for key, value in props do
		merged[key] = value
	end
	return make("TextLabel", merged, {
		Theme.stroke(Theme.Colors.Outline, outlineThickness or 2.5),
	})
end

-- The dotted overlay, or nothing when no texture is configured.
function Theme.dots(zindex: number?): ImageLabel?
	if Theme.DotTexture == "" then
		return nil
	end
	return make("ImageLabel", {
		Name = "Dots",
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		Image = Theme.DotTexture,
		ImageTransparency = Theme.DotTransparency,
		ScaleType = Enum.ScaleType.Tile,
		TileSize = Theme.DotTileSize,
		ZIndex = zindex or 1,
	})
end

--[[
	A panel body: near-black, thick coloured border, rounded, with the dotted
	texture when one is set.
]]
function Theme.panel(props: { [string]: any }, borderColor: Color3?, children: { any }?): Frame
	local merged: { [string]: any } = {
		BackgroundColor3 = Theme.Colors.PanelBody,
		BorderSizePixel = 0,
	}
	for key, value in props do
		merged[key] = value
	end

	local kids: { any } = {
		Theme.corner(12),
		Theme.stroke(borderColor or Theme.Colors.PanelBorder, 4),
		Theme.gradient(Theme.Colors.PanelBody, Theme.Colors.PanelBodyDeep),
	}
	local dots = Theme.dots()
	if dots then
		table.insert(kids, dots)
	end
	if children then
		for _, child in children do
			table.insert(kids, child)
		end
	end
	return make("Frame", merged, kids)
end

-- A coloured tab / action pill.
function Theme.pill(props: { [string]: any }, color: Color3, text: string): TextButton
	local merged: { [string]: any } = {
		BackgroundColor3 = color,
		AutoButtonColor = false,
		Text = "",
		BorderSizePixel = 0,
	}
	for key, value in props do
		merged[key] = value
	end
	return make("TextButton", merged, {
		Theme.corner(8),
		Theme.gradient(Color3.new(1, 1, 1), Color3.fromRGB(205, 205, 205)),
		Theme.stroke(Theme.Colors.Outline, 2.5),
		Theme.label({
			Name = "Label",
			Size = UDim2.fromScale(1, 1),
			Text = text,
		}, 3),
	})
end

-- Magnifier for the search field, also drawn rather than uploaded.
function Theme.searchIcon(props: { [string]: any }): Frame
	local merged: { [string]: any } = {
		Name = "SearchIcon",
		BackgroundTransparency = 1,
	}
	for key, value in props do
		merged[key] = value
	end
	return make("Frame", merged, {
		make("Frame", {
			Name = "Ring",
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.42, 0.42),
			Size = UDim2.fromScale(0.62, 0.62),
			BackgroundTransparency = 1,
		}, {
			Theme.corner(999),
			Theme.stroke(Theme.Colors.TextDim, 2.5),
		}),
		make("Frame", {
			Name = "Handle",
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.74, 0.76),
			Size = UDim2.fromScale(0.3, 0.11),
			Rotation = 45,
			BackgroundColor3 = Theme.Colors.TextDim,
			BorderSizePixel = 0,
		}, { Theme.corner(999) }),
	})
end

-- Slot colours: saturated but dark enough for white text to sit on top.
function Theme.rarityBackdrop(color: Color3): (Color3, Color3)
	local black = Color3.new(0, 0, 0)
	return color:Lerp(black, 0.42), color:Lerp(black, 0.76)
end

--[[
	The tinted, bordered square every item sits in - used by both the hotbar
	and the inventory grid so they cannot drift apart.
]]
function Theme.slotFrame(props: { [string]: any }, color: Color3, children: { any }?): Frame
	local top, bottom = Theme.rarityBackdrop(color)
	local merged: { [string]: any } = {
		BackgroundColor3 = top,
		BorderSizePixel = 0,
		ClipsDescendants = true,
	}
	for key, value in props do
		merged[key] = value
	end

	local kids: { any } = {
		Theme.corner(10),
		Theme.gradient(top, bottom, 135),
		Theme.stroke(color, 3),
	}
	local dots = Theme.dots()
	if dots then
		table.insert(kids, dots)
	end
	if children then
		for _, child in children do
			table.insert(kids, child)
		end
	end
	return Theme.make("Frame", merged, kids)
end

--[[
	An item's picture. Falls back to the first letter of the name in the
	rarity colour when the card has no icon yet, so the layout still reads.
]]
function Theme.iconFor(name: string, icon: string, color: Color3, props: { [string]: any }): GuiObject
	if icon ~= "" then
		local merged: { [string]: any } = {
			Name = "Icon",
			BackgroundTransparency = 1,
			Image = icon,
			ScaleType = Enum.ScaleType.Fit,
		}
		for key, value in props do
			merged[key] = value
		end
		return Theme.make("ImageLabel", merged)
	end

	local merged: { [string]: any } = {
		Name = "Icon",
		Text = string.upper(string.sub(name, 1, 1)),
		TextColor3 = color:Lerp(Color3.new(1, 1, 1), 0.45),
	}
	for key, value in props do
		merged[key] = value
	end
	return Theme.label(merged, 3)
end

--[[
	Keeps offset-sized UI in proportion across screens. The reference layout is
	authored against a 900px tall viewport.
]]
function Theme.scaleFor(viewportY: number): number
	return math.clamp(viewportY / 900, 0.62, 1.3)
end

return Theme
