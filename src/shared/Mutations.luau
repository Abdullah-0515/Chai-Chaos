-- Mutations: rare Golden, Diamond and Rainbow versions of any brainrot.
-- They earn more and are worth more. The chances are shown in the Kismat panel.
--
-- income : income multiplier
-- value  : value multiplier (for selling and Lockers)
-- egg    : chance when an egg hatches
-- golden : chance when a golden egg hatches (golden eggs always give a mutation)
-- roll   : chance in a Kismat Roll

local Mutations = {}

export type Mutation = {
	id: string,
	name: string,
	income: number,
	value: number,
	color: Color3,
	egg: number,
	golden: number,
	roll: number,
}

Mutations.list = {
	{
		id = "Golden",
		name = "Golden",
		income = 2,
		value = 1.5,
		color = Color3.fromRGB(255, 205, 50),
		egg = 0.04,
		golden = 0.75,
		roll = 0.08,
	},
	{
		id = "Diamond",
		name = "Diamond",
		income = 4,
		value = 2.5,
		color = Color3.fromRGB(120, 235, 255),
		egg = 0.01,
		golden = 0.2,
		roll = 0.02,
	},
	{
		id = "Rainbow",
		name = "Rainbow",
		income = 8,
		value = 4.5,
		color = Color3.fromRGB(255, 110, 210),
		egg = 0.0025,
		golden = 0.05,
		roll = 0.005,
	},
} :: { Mutation }

Mutations.byId = {} :: { [string]: Mutation }
for _, m in Mutations.list do
	Mutations.byId[m.id] = m
end

-- Picks a mutation (or nil for a normal brainrot). `source` is "egg", "golden"
-- or "roll"; `boost` multiplies every chance (luck from events and theme perks).
function Mutations.roll(source: string, boost: number?): string?
	local r = math.random()
	for i = #Mutations.list, 1, -1 do
		local m = Mutations.list[i]
		local chance = (m :: any)[source] * (boost or 1)
		if r < chance then
			return m.id
		end
		r -= chance
	end
	return nil
end

function Mutations.incomeMultiplier(id: string?): number
	local m = id and Mutations.byId[id]
	return if m then m.income else 1
end

function Mutations.valueMultiplier(id: string?): number
	local m = id and Mutations.byId[id]
	return if m then m.value else 1
end

-- What a brainrot is worth (its price with the mutation).
function Mutations.value(def, id: string?): number
	return math.floor(def.price * Mutations.valueMultiplier(id))
end

function Mutations.income(def, id: string?): number
	return def.income * Mutations.incomeMultiplier(id)
end

-- "Golden Samosa Supremo"
function Mutations.displayName(def, id: string?): string
	local m = id and Mutations.byId[id]
	return if m then m.name .. " " .. def.name else def.name
end

-- Saved brainrots are strings: "SamosaSupremo" or "SamosaSupremo:Golden".
function Mutations.key(defId: string, id: string?): string
	return if id then defId .. ":" .. id else defId
end

function Mutations.parse(key: string): (string, string?)
	local defId, id = key:match("^([^:]+):(.+)$")
	if defId then
		return defId, if Mutations.byId[id] then id else nil
	end
	return key, nil
end

return Mutations
