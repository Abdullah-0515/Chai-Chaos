-- Haveli themes. Two are free; every Naya Safar unlocks the next one.
--
-- Every haveli has the same bazaar look as the Chowk (see Themes.BASE): a red
-- brick ground floor, a cream upper floor with arches, cream stone trim and
-- battlements, teal doors and shutters. A theme adds its own colours on top:
--   trim   : the corner towers, pillars and the stripes of the awnings
--   accent : the domes
--   floor  : the courtyard floor (and floorMaterial)
-- plus its decorations and one small perk.
--
-- perk kinds:
--   income       : multiply your income
--   thiefSlow    : thieves carrying your brainrots walk this much slower
--   walkSpeed    : you walk this much faster
--   rollDiscount : Kismat Rolls cost this much less (0.15 = 15% off)
--   taalaBonus   : extra seconds on your Taala
--   rollMutation : multiply mutation chances in your Kismat Rolls
--   bonkRange    : multiply how far your chappal reaches
--   eventIncome  : multiply your income during events

local Themes = {}

local function rgb(r: number, g: number, b: number): Color3
	return Color3.fromRGB(r, g, b)
end

export type Theme = {
	id: string,
	name: string,
	rebirths: number,
	perkText: string,
	perk: string,
	value: number,
	trim: Color3,
	accent: Color3,
	floor: Color3,
	floorMaterial: string,
	reflectance: number?,
	decor: { string },
	upperDecor: string,
	roofDecor: string,
}

Themes.list = {
	{
		id = "MughalMarble",
		name = "Mughal Marble",
		rebirths = 0,
		perk = "income",
		value = 1.05,
		perkText = "Shahi Kamai: +5% income",
		trim = rgb(215, 95, 65),
		accent = rgb(255, 200, 60),
		floor = rgb(240, 232, 214),
		floorMaterial = "Marble",
		decor = { "lantern", "planter", "fountain" },
		upperDecor = "lantern",
		roofDecor = "chhatri",
	},
	{
		id = "BaghGarden",
		name = "Bagh Garden",
		rebirths = 0,
		perk = "thiefSlow",
		value = 0.85,
		perkText = "Kaanton Wali Baarh: thieves carrying your brainrots are 15% slower",
		trim = rgb(80, 175, 90),
		accent = rgb(255, 120, 165),
		floor = rgb(130, 205, 105),
		floorMaterial = "Grass",
		decor = { "tree", "hedge", "planter" },
		upperDecor = "planter",
		roofDecor = "tree",
	},
	{
		id = "TruckArt",
		name = "Truck Art",
		rebirths = 1,
		perk = "walkSpeed",
		value = 1.12,
		perkText = "Pon Pon: you walk 12% faster",
		trim = rgb(235, 40, 95),
		accent = rgb(30, 185, 230),
		floor = rgb(255, 245, 210),
		floorMaterial = "SmoothPlastic",
		decor = { "bells", "banner", "lantern" },
		upperDecor = "bells",
		roofDecor = "kites",
	},
	{
		id = "ChaiDhaba",
		name = "Chai Dhaba",
		rebirths = 2,
		perk = "rollDiscount",
		value = 0.15,
		perkText = "Chai Break: Kismat Rolls cost 15% fewer rupees",
		trim = rgb(115, 72, 40),
		accent = rgb(255, 175, 50),
		floor = rgb(195, 155, 110),
		floorMaterial = "WoodPlanks",
		decor = { "charpai", "kettle", "lantern" },
		upperDecor = "charpai",
		roofDecor = "chhatri",
	},
	{
		id = "SheeshMahal",
		name = "Sheesh Mahal",
		rebirths = 3,
		perk = "taalaBonus",
		value = 15,
		perkText = "Chamak: your Taala lasts 15 seconds longer",
		trim = rgb(175, 135, 255),
		accent = rgb(255, 255, 255),
		floor = rgb(235, 245, 255),
		floorMaterial = "Marble",
		reflectance = 0.25,
		decor = { "mirror", "crystal", "lantern" },
		upperDecor = "crystal",
		roofDecor = "chhatri",
	},
	{
		id = "BasantRooftop",
		name = "Basant Rooftop",
		rebirths = 4,
		perk = "rollMutation",
		value = 2,
		perkText = "Patang Luck: mutations are twice as likely in your Kismat Rolls",
		trim = rgb(255, 140, 20),
		accent = rgb(120, 205, 60),
		floor = rgb(255, 250, 215),
		floorMaterial = "SmoothPlastic",
		decor = { "kiteStand", "planter", "bunting" },
		upperDecor = "kiteStand",
		roofDecor = "kites",
	},
	{
		id = "CricketMaidan",
		name = "Cricket Maidan",
		rebirths = 5,
		perk = "bonkRange",
		value = 2,
		perkText = "Lambi Shot: your chappal reaches twice as far",
		trim = rgb(30, 135, 65),
		accent = rgb(0, 95, 180),
		floor = rgb(110, 195, 85),
		floorMaterial = "Grass",
		decor = { "stumps", "banner", "planter" },
		upperDecor = "stumps",
		roofDecor = "kites",
	},
	{
		id = "MelaLights",
		name = "Mela Lights",
		rebirths = 6,
		perk = "eventIncome",
		value = 1.25,
		perkText = "Mela Magic: +25% income during events",
		trim = rgb(145, 65, 205),
		accent = rgb(255, 225, 60),
		floor = rgb(255, 235, 245),
		floorMaterial = "SmoothPlastic",
		decor = { "balloons", "fairyLights", "bunting" },
		upperDecor = "balloons",
		roofDecor = "kites",
	},
} :: { Theme }

Themes.DEFAULT = "MughalMarble"
Themes.EMPTY = { -- an empty haveli: the bazaar look with plain canvas awnings
	trim = rgb(205, 180, 140),
	accent = rgb(220, 200, 165),
	floor = rgb(235, 225, 205),
	floorMaterial = "SmoothPlastic",
}

-- The bazaar look every haveli shares, in the colours of the reference picture
-- (docs/reference-chowk.jpg).
Themes.BASE = {
	brick = rgb(200, 96, 84), -- the ground floor
	upper = rgb(238, 214, 172), -- the upper floor
	stone = rgb(245, 235, 212), -- cream stone: ledges, arches, railings, battlements
	teal = rgb(28, 108, 98), -- doors, shutters and the name sign
	gold = rgb(240, 190, 60), -- the diamonds in the teal band
	stripe = rgb(250, 244, 230), -- the light stripes on the awnings
	wood = rgb(198, 128, 68),
}

Themes.byId = {} :: { [string]: Theme }
for _, theme in Themes.list do
	Themes.byId[theme.id] = theme
end

function Themes.isUnlocked(id: string, rebirths: number): boolean
	local theme = Themes.byId[id]
	return theme ~= nil and rebirths >= theme.rebirths
end

-- The perk value if `themeId` has a perk of this kind, otherwise nil.
function Themes.perk(themeId: string?, kind: string): number?
	local theme = themeId and Themes.byId[themeId]
	if theme and theme.perk == kind then
		return theme.value
	end
	return nil
end

return Themes
