-- Haveli themes. Two are free; every Naya Safar unlocks the next one.
-- Each theme changes how your haveli looks and gives one small perk.
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
	wall: Color3,
	trim: Color3,
	accent: Color3,
	floor: Color3,
	wallMaterial: string,
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
		wall = rgb(250, 246, 238),
		trim = rgb(215, 95, 65),
		accent = rgb(255, 200, 60),
		floor = rgb(240, 232, 214),
		wallMaterial = "Marble",
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
		wall = rgb(255, 240, 205),
		trim = rgb(80, 175, 90),
		accent = rgb(255, 120, 165),
		floor = rgb(130, 205, 105),
		wallMaterial = "SmoothPlastic",
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
		wall = rgb(255, 215, 50),
		trim = rgb(235, 40, 95),
		accent = rgb(30, 185, 230),
		floor = rgb(255, 245, 210),
		wallMaterial = "SmoothPlastic",
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
		wall = rgb(215, 150, 95),
		trim = rgb(115, 72, 40),
		accent = rgb(255, 175, 50),
		floor = rgb(195, 155, 110),
		wallMaterial = "Brick",
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
		wall = rgb(205, 232, 255),
		trim = rgb(175, 135, 255),
		accent = rgb(255, 255, 255),
		floor = rgb(235, 245, 255),
		wallMaterial = "SmoothPlastic",
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
		wall = rgb(255, 238, 90),
		trim = rgb(255, 140, 20),
		accent = rgb(120, 205, 60),
		floor = rgb(255, 250, 215),
		wallMaterial = "SmoothPlastic",
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
		wall = rgb(245, 245, 245),
		trim = rgb(30, 135, 65),
		accent = rgb(0, 95, 180),
		floor = rgb(110, 195, 85),
		wallMaterial = "SmoothPlastic",
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
		wall = rgb(255, 160, 205),
		trim = rgb(145, 65, 205),
		accent = rgb(255, 225, 60),
		floor = rgb(255, 235, 245),
		wallMaterial = "SmoothPlastic",
		floorMaterial = "SmoothPlastic",
		decor = { "balloons", "fairyLights", "bunting" },
		upperDecor = "balloons",
		roofDecor = "kites",
	},
} :: { Theme }

Themes.DEFAULT = "MughalMarble"
Themes.EMPTY = { -- an empty haveli
	wall = rgb(226, 196, 150),
	trim = rgb(190, 150, 105),
	accent = rgb(210, 180, 140),
	floor = rgb(235, 225, 205),
	wallMaterial = "SmoothPlastic",
	floorMaterial = "SmoothPlastic",
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
