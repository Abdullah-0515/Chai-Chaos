-- All 36 brainrots from docs/game-design.md, 4 Secret brainrots that only hatch in
-- Barfani Pahar, and 6 special quest brainrots.
--
-- id     : the Model name to use in ServerStorage/Brainrots if you build your own model.
-- price  : the price from the design doc; the game multiplies it by Config.PRICE_MULTIPLIER.
-- shape  : the body of the blocky placeholder that is made when no model exists yet.
-- extras : small add-ons for the placeholder (glasses, crown, legs and so on).
-- float  : hovers above the ground instead of standing on it.
-- questOnly : never hatches; earned from the Collection Book. Cannot be stolen or sold.
--
-- Which brainrots hatch from which biome's eggs is in Biomes.luau.

local Config = require(script.Parent.Config)

local Brainrots = {}

-- The rarities that hatch from eggs (Secret only from Barfani Pahar's eggs,
-- never from Kismat Rolls).
Brainrots.RARITY_ORDER = { "Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythic", "Secret" }
-- The Collection Book also shows the special quest brainrots.
Brainrots.BOOK_ORDER = { "Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythic", "Secret", "Special" }

Brainrots.RARITY_COLORS = {
	Common = Color3.fromRGB(190, 190, 190),
	Uncommon = Color3.fromRGB(90, 210, 90),
	Rare = Color3.fromRGB(70, 150, 255),
	Epic = Color3.fromRGB(180, 90, 255),
	Legendary = Color3.fromRGB(255, 195, 40),
	Mythic = Color3.fromRGB(255, 80, 170),
	Secret = Color3.fromRGB(190, 230, 255),
	Special = Color3.fromRGB(40, 225, 200),
}

export type Def = {
	id: string,
	name: string,
	rarity: string,
	price: number,
	income: number,
	phrase: string,
	color: Color3,
	shape: string,
	extras: { string },
	float: boolean?,
	eyes: number?,
	questOnly: boolean?,
	basePrice: number?,
}

local function rgb(r: number, g: number, b: number): Color3
	return Color3.fromRGB(r, g, b)
end

-- stylua: ignore start
Brainrots.list = {
	-- Batch 1
	{ id = "GolGappaGhostu", name = "Gol Gappa Ghostu", rarity = "Common", price = 25, income = 1, phrase = "Thora aur khatta daalo!", color = rgb(214, 160, 80), shape = "Ball", extras = {}, float = true },
	{ id = "SamosaSupremo", name = "Samosa Supremo", rarity = "Common", price = 50, income = 2, phrase = "Main course main hoon!", color = rgb(205, 140, 60), shape = "Wedge", extras = { "glasses" } },
	{ id = "ChaiyooKettlesaurus", name = "Chaiyoo Kettlesaurus", rarity = "Common", price = 100, income = 4, phrase = "Doodh patti, extra cheeni.", color = rgb(160, 165, 175), shape = "Cylinder", extras = { "legs", "tail" } },
	{ id = "ParathaPilot", name = "Paratha Pilot", rarity = "Uncommon", price = 300, income = 10, phrase = "Ghee landing in 3... 2... 1!", color = rgb(230, 190, 110), shape = "Disc", extras = { "goggles" }, float = true },
	{ id = "RickshawRaptor", name = "Rickshaw Raptor", rarity = "Uncommon", price = 600, income = 18, phrase = "Pon pon! Kahan jaana hai?", color = rgb(40, 150, 70), shape = "Block", extras = { "legs", "tail" } },
	{ id = "LoadSheddingLattoo", name = "Load Shedding Lattoo", rarity = "Rare", price = 1500, income = 40, phrase = "Light aa gayi!", color = rgb(240, 80, 60), shape = "Ball", extras = { "headband" } },
	{ id = "BiryaniBadshah", name = "Biryani Badshah", rarity = "Rare", price = 3000, income = 75, phrase = "Aloo wali biryani hi asli hai!", color = rgb(240, 170, 60), shape = "Cylinder", extras = { "crown" } },
	{ id = "ChipaSahab", name = "Chipa Sahab", rarity = "Epic", price = 8000, income = 180, phrase = "Beta, meri baat suno...", color = rgb(150, 110, 85), shape = "Ball", extras = { "moustache", "legs" } },
	{ id = "JalebiJinn", name = "Jalebi Jinn", rarity = "Epic", price = 15000, income = 320, phrase = "Teen wishes... teeno meethi!", color = rgb(255, 150, 30), shape = "Ball", extras = { "moustache", "crown" }, float = true },
	{ id = "TruckArtTotaa", name = "Truck Art Totaa", rarity = "Legendary", price = 40000, income = 800, phrase = "Dekh magar pyar se!", color = rgb(30, 170, 150), shape = "Ball", extras = { "wings", "tail" } },
	{ id = "SixerSher", name = "Sixer Sher", rarity = "Legendary", price = 75000, income = 1400, phrase = "Chakka! Sorry, sheesha toot gaya!", color = rgb(230, 160, 50), shape = "Block", extras = { "ears", "bat", "legs" } },
	{ id = "AmmiKiUdtiChappal", name = "Ammi ki Udti Chappal", rarity = "Mythic", price = 250000, income = 4000, phrase = "Whoooosh! Homework kiya?", color = rgb(60, 110, 210), shape = "Slab", extras = { "wings" }, float = true },

	-- Batch 2
	{ id = "ChanaChaatChacha", name = "Chana Chaat Chacha", rarity = "Common", price = 40, income = 2, phrase = "Imli wali, imli wali!", color = rgb(200, 150, 70), shape = "Cylinder", extras = { "moustache", "legs" } },
	{ id = "KulfiKangaroo", name = "Kulfi Kangaroo", rarity = "Common", price = 75, income = 3, phrase = "Pighla... phir jam gaya!", color = rgb(245, 225, 180), shape = "Tall", extras = { "ears", "legs" } },
	{ id = "PakoraPanda", name = "Pakora Panda", rarity = "Common", price = 120, income = 5, phrase = "Baarish? Pakora time!", color = rgb(190, 120, 40), shape = "Ball", extras = { "ears" } },
	{ id = "LassiLlama", name = "Lassi Llama", rarity = "Uncommon", price = 400, income = 13, phrase = "Malai moochh, full style!", color = rgb(250, 248, 235), shape = "Cylinder", extras = { "moustache", "ears" } },
	{ id = "BunKebabBhai", name = "Bun Kebab Bhai", rarity = "Uncommon", price = 800, income = 24, phrase = "Ek dum garam!", color = rgb(170, 100, 45), shape = "Disc", extras = { "legs" } },
	{ id = "RoohAfzaRhino", name = "Rooh Afza Rhino", rarity = "Uncommon", price = 1000, income = 30, phrase = "Sab kuch pink!", color = rgb(220, 30, 60), shape = "Block", extras = { "horn", "legs" } },
	{ id = "CricketBatBhaijaan", name = "Cricket Bat Bhaijaan", rarity = "Rare", price = 2000, income = 55, phrase = "Aur yeh gaya... chauka!", color = rgb(225, 200, 140), shape = "Tall", extras = { "headband", "legs" } },
	{ id = "DhabaDragon", name = "Dhaba Dragon", rarity = "Rare", price = 4000, income = 100, phrase = "Ek naan, extra garam!", color = rgb(200, 60, 40), shape = "Block", extras = { "wings", "horn", "tail" } },
	{ id = "MehndiMummy", name = "Mehndi Mummy", rarity = "Epic", price = 10000, income = 230, phrase = "Haath idhar karo!", color = rgb(160, 95, 45), shape = "Tall", extras = { "headband" } },
	{ id = "DholakDino", name = "Dholak Dino", rarity = "Epic", price = 20000, income = 400, phrase = "Dhak dhina dhin!", color = rgb(90, 170, 80), shape = "Cylinder", extras = { "legs", "tail" } },
	{ id = "TongaTornado", name = "Tonga Tornado", rarity = "Epic", price = 30000, income = 600, phrase = "Driver kaun hai?!", color = rgb(160, 110, 70), shape = "Wheel", extras = { "ears" } },
	{ id = "ChilgozaChachaChipka", name = "Chilgoza Chacha Chipka", rarity = "Legendary", price = 100000, income = 1800, phrase = "Ghar ka pankha hoon main!", color = rgb(175, 125, 85), shape = "Ball", extras = { "moustache", "wings" } },
	{ id = "MelaMaharaja", name = "Mela Maharaja", rarity = "Legendary", price = 150000, income = 2600, phrase = "Ek chakkar aur!", color = rgb(240, 80, 160), shape = "Wheel", extras = { "crown" } },
	{ id = "KiteKaptaan", name = "Kite Kaptaan", rarity = "Mythic", price = 500000, income = 8000, phrase = "Bo kata!", color = rgb(255, 60, 60), shape = "Kite", extras = { "tail" }, float = true },

	-- Batch 3
	{ id = "NaanNinja", name = "Naan Ninja", rarity = "Common", price = 60, income = 2, phrase = "Roti star! Hiyaa!", color = rgb(235, 200, 140), shape = "Disc", extras = { "headband" } },
	{ id = "PyaazPehelwan", name = "Pyaaz Pehelwan", rarity = "Common", price = 90, income = 4, phrase = "Ro kyun rahe ho?", color = rgb(170, 60, 120), shape = "Ball", extras = { "moustache", "legs" } },
	{ id = "GajarHalwaGorilla", name = "Gajar Halwa Gorilla", rarity = "Uncommon", price = 500, income = 15, phrase = "Sardi aa gayi!", color = rgb(240, 110, 30), shape = "Block", extras = { "ears", "legs" } },
	{ id = "DoodhPattiDolphin", name = "Doodh Patti Dolphin", rarity = "Uncommon", price = 900, income = 26, phrase = "Chai mein chhalaang!", color = rgb(185, 135, 95), shape = "Ball", extras = { "wings", "tail" }, float = true },
	{ id = "GeneratorGainda", name = "Generator Gainda", rarity = "Rare", price = 2500, income = 65, phrase = "Light gayi? Main aaya! Brrrr!", color = rgb(115, 115, 125), shape = "Block", extras = { "horn", "legs" } },
	{ id = "ShaadiShehnaiShark", name = "Shaadi Shehnai Shark", rarity = "Rare", price = 5000, income = 120, phrase = "Shaadi kahan hai?", color = rgb(90, 130, 185), shape = "Wedge", extras = { "wings" } },
	{ id = "TikkaTiger", name = "Tikka Tiger", rarity = "Epic", price = 12000, income = 270, phrase = "Apna tikka khud banata hoon!", color = rgb(245, 140, 30), shape = "Block", extras = { "ears", "tail", "legs" } },
	{ id = "RishtaAuntyRobot", name = "Rishta Aunty Robot", rarity = "Epic", price = 25000, income = 500, phrase = "Beta, kya karte ho?", color = rgb(200, 200, 215), shape = "Tall", extras = { "glasses" } },
	{ id = "CylinderCycleChacha", name = "Cylinder Cycle Chacha", rarity = "Legendary", price = 120000, income = 2200, phrase = "Cylinder le lo, cylinder!", color = rgb(200, 40, 40), shape = "Wheel", extras = { "moustache" } },
	{ id = "ChandRaatCheetah", name = "Chand Raat Cheetah", rarity = "Mythic", price = 400000, income = 6500, phrase = "Choorian chamak rahi hain!", color = rgb(250, 210, 80), shape = "Block", extras = { "ears", "tail", "legs" } },
	-- Secret brainrots: only from Barfani Pahar's eggs (4 rebirths)
	{ id = "KahwaYeti", name = "Kahwa Yeti", rarity = "Secret", price = 1200000, income = 15000, phrase = "Ek cup kahwa, garam garam!", color = rgb(240, 245, 250), shape = "Ball", extras = { "ears", "legs" } },
	{ id = "GolaGandaGolem", name = "Gola Ganda Golem", rarity = "Secret", price = 1800000, income = 21000, phrase = "Thanda thanda, rang birangi!", color = rgb(150, 220, 255), shape = "Block", extras = { "legs" } },
	{ id = "BarfiBarfaniBagh", name = "Barfi Barfani Bagh", rarity = "Secret", price = 2500000, income = 28000, phrase = "Barf bhi, barfi bhi!", color = rgb(245, 245, 235), shape = "Block", extras = { "ears", "tail", "legs" } },
	{ id = "JalebiMarkhor", name = "Jalebi Markhor", rarity = "Secret", price = 3500000, income = 36000, phrase = "Seengh meethe, dil bhi meetha!", color = rgb(200, 160, 110), shape = "Block", extras = { "horn", "legs" } },

	-- Special quest brainrots: rewards for finishing a rarity in the Collection Book
	{ id = "MithaiMamu", name = "Mithai Mamu", rarity = "Special", price = 2000, income = 60, phrase = "Ek aur laddoo, beta!", color = rgb(255, 170, 60), shape = "Block", extras = { "moustache", "legs" }, questOnly = true },
	{ id = "LassiLightning", name = "Lassi Lightning", rarity = "Special", price = 8000, income = 220, phrase = "Thandi thandi... ZAP!", color = rgb(235, 245, 255), shape = "Tall", extras = { "goggles", "wings" }, float = true, questOnly = true },
	{ id = "ChowkidarChoocha", name = "Chowkidar Choocha", rarity = "Special", price = 30000, income = 800, phrase = "Jaagte raho!", color = rgb(255, 225, 70), shape = "Ball", extras = { "headband", "legs" }, questOnly = true },
	{ id = "RangeelaRaja", name = "Rangeela Raja", rarity = "Special", price = 120000, income = 3000, phrase = "Rang hi rang!", color = rgb(40, 160, 220), shape = "Ball", extras = { "crown", "wings", "tail" }, questOnly = true },
	{ id = "ShalimarSultan", name = "Shalimar Sultan", rarity = "Special", price = 500000, income = 11000, phrase = "Bagh mein khush aamdeed!", color = rgb(60, 190, 120), shape = "Cylinder", extras = { "crown" }, float = true, questOnly = true },
	{ id = "TaaronWalaTonga", name = "Taaron Wala Tonga", rarity = "Special", price = 2000000, income = 40000, phrase = "Chalo, taaron ki sair!", color = rgb(70, 70, 170), shape = "Wheel", extras = { "ears", "crown" }, float = true, questOnly = true },
} :: { Def }
-- stylua: ignore end

Brainrots.byId = {} :: { [string]: Def }
Brainrots.byRarity = {} :: { [string]: { Def } }

for _, rarity in Brainrots.BOOK_ORDER do
	Brainrots.byRarity[rarity] = {}
end

for _, def in Brainrots.list do
	assert(Brainrots.byId[def.id] == nil, "Duplicate brainrot id: " .. def.id)
	assert(Brainrots.byRarity[def.rarity], "Unknown rarity: " .. def.rarity)
	def.basePrice = def.price
	def.price = def.price * Config.PRICE_MULTIPLIER
	Brainrots.byId[def.id] = def
	table.insert(Brainrots.byRarity[def.rarity], def)
end

-- Cheapest first inside each rarity, which is also the order of the collection book.
for _, pool in Brainrots.byRarity do
	table.sort(pool, function(a, b)
		return a.price < b.price
	end)
end

return Brainrots
