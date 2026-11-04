local Format = {}

-- 1234567 -> "1,234,567"
function Format.commas(n: number): string
	local whole = tostring(math.floor(math.abs(n)))
	local out = whole:reverse():gsub("(%d%d%d)", "%1,"):reverse()
	if out:sub(1, 1) == "," then
		out = out:sub(2)
	end
	return if n < 0 then "-" .. out else out
end

-- "Rs 1,234"
function Format.rupees(n: number): string
	return "Rs " .. Format.commas(n)
end

-- Short form for small labels: 950 -> "950", 12500 -> "12.5K", 2000000 -> "2M"
function Format.short(n: number): string
	local abs = math.abs(n)
	local function trim(x: number, suffix: string): string
		local s = string.format("%.1f", x):gsub("%.0$", "")
		return s .. suffix
	end
	if abs >= 1e9 then
		return trim(n / 1e9, "B")
	elseif abs >= 1e6 then
		return trim(n / 1e6, "M")
	elseif abs >= 1e4 then
		return trim(n / 1e3, "K")
	end
	return Format.commas(n)
end

return Format
