-- Lib/SyntaxHighlighter.lua
-- Modul untuk menambahkan pewarnaan sintaks RichText ke string kode Luau.

local SyntaxHighlighter = {}

-- Palet warna yang terinspirasi dari tema 'Default' Roblox Studio
local COLORS = {
	background = "#2E2E2E",
	text = "#DCDCDC",
	keyword = "#569CD6",
	string = "#D69D85",
	number = "#B5CEA8",
	comment = "#6A9955",
	-- 'nil', 'true', 'false'
	special = "#4EC9B0",
	-- 'self'
	variable = "#9CDCFE"
}

-- Kata kunci dan kata kunci bawaan Lua/Luau
local KEYWORDS = {
	"and", "break", "do", "else", "elseif", "end", "for", "function",
	"if", "in", "local", "not", "or", "repeat", "return", "then",
	"until", "while", "continue"
}

local SPECIALS = { "true", "false", "nil" }
local VARIABLE = { "self" }

local function colorize(text, color)
	return string.format("<font color='%s'>%s</font>", color, text)
end

-- Fungsi utama untuk menyorot kode
function SyntaxHighlighter.highlight(source)
	-- Escape karakter XML dasar untuk mencegah masalah RichText
	source = source:gsub("&", "&amp;"):gsub("<", "&lt;"):gsub(">", "&gt;"):gsub("'", "&apos;"):gsub("\"", "&quot;")

	-- 1. Sorot Komentar
	source = source:gsub("(--.-)\n", function(c) return colorize(c, COLORS.comment) .. "\n" end)
	source = source:gsub("(--.-)$", function(c) return colorize(c, COLORS.comment) end)

	-- 2. Sorot String
	source = source:gsub("(&quot;.-&quot;)", colorize("%1", COLORS.string))
	source = source:gsub("(&apos;.-&apos;)", colorize("%1", COLORS.string))

	-- 3. Sorot Angka
	source = source:gsub("(%f[%w_%.])", function(number)
        if tonumber(number) then
            return colorize(number, COLORS.number)
        else
            return number
        end
    end)

	-- 4. Sorot Kata Kunci, Spesial, dan Variabel
	local keywordSet = {}
	for _, k in ipairs(KEYWORDS) do keywordSet[k] = COLORS.keyword end
	for _, s in ipairs(SPECIALS) do keywordSet[s] = COLORS.special end
	for _, v in ipairs(VARIABLE) do keywordSet[v] = COLORS.variable end

	source = source:gsub("(%w+)", function(word)
		if keywordSet[word] then
			return colorize(word, keywordSet[word])
		else
			return word
		end
	end)

	return source
end

return SyntaxHighlighter
