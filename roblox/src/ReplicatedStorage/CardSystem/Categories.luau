--!strict
--[[
	Categories
	The inventory tab strip is built from this list. Add an entry here, put the
	same id on a card in Cards.luau, and the tab appears with no other edits.

	"All" is implicit and always first.
]]

export type Category = {
	Id: string,
	Name: string,
	Color: Color3,
}

local Categories = {}

Categories.AllId = "All"
Categories.AllColor = Color3.fromRGB(79, 195, 247)

Categories.List = {
	{ Id = "Weapons", Name = "Weapons", Color = Color3.fromRGB(255, 196, 40) },
	{ Id = "Relics", Name = "Relics", Color = Color3.fromRGB(255, 152, 40) },
	{ Id = "Trinkets", Name = "Trinkets", Color = Color3.fromRGB(120, 214, 60) },
	{ Id = "Tickets", Name = "Tickets", Color = Color3.fromRGB(86, 200, 90) },
} :: { Category }

Categories.ById = {} :: { [string]: Category }
for _, category in Categories.List do
	Categories.ById[category.Id] = category
end

function Categories.exists(id: string): boolean
	return id == Categories.AllId or Categories.ById[id] ~= nil
end

return Categories
