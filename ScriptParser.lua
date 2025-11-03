-- Lib/ScriptParser.lua
-- Modul untuk menganalisis kode sumber skrip yang dihasilkan
-- dan mengekstrak informasi penting untuk sinkronisasi balik.

local ScriptParser = {}

-- Menganalisis kode sumber dan mengekstrak:
-- 1. Path sumber asli dari komentar.
-- 2. Peta dari nama variabel ke path relatifnya (membutuhkan Trace Comments).
-- 3. Properti yang ditetapkan untuk setiap variabel.
function ScriptParser.parse(sourceCode)
	local result = {
		sourcePath = nil,
		varPathMap = {}, -- { varName = relativePath }
		properties = {},  -- { varName = { PropName = "Value string" } }
	}

	-- 1. Ekstrak path sumber utama
	-- Mencocokkan baris yang mengandung "-- Sumber: ..."
	local sourcePathMatch = sourceCode:match("--%s*Sumber:%s*(.+)")
	if sourcePathMatch then
		result.sourcePath = sourcePathMatch:match("^%s*(.-)%s*$") -- Trim whitespace
	end

	-- Jika tidak ada path sumber, tidak ada gunanya melanjutkan
	if not result.sourcePath then
		return nil, "Komentar '-- Sumber:' tidak ditemukan di skrip."
	end

	for line in sourceCode:gmatch("([^\n]+)") do
		-- 2. Cari pembuatan instance dengan komentar jejak (trace comment)
		-- Contoh: local Frame = Instance.new("Frame") -- Original: MainFrame.Frame
		local varName, relPath = line:match("^%s*local%s+([%w_]+)%s*=%s*Instance%.new.+%-%-%s*Original:%s*(.+)$")

		if varName and relPath then
			local trimmedPath = relPath:match("^%s*(.-)%s*$")
			result.varPathMap[varName] = trimmedPath
			-- Inisialisasi tabel properti untuk variabel ini
			if not result.properties[varName] then
				result.properties[varName] = {}
			end
		end

		-- 3. Cari penetapan properti
		-- Contoh: Frame.Size = UDim2.new(0, 100, 0, 100)
		local propVar, propName, propValue = line:match("^%s*([%w_]+)%.([%w_]+)%s*=%s*(.+)$")
		if propVar and propName and propValue then
			-- Pastikan ini adalah variabel yang telah kita lacak
			if result.varPathMap[propVar] then
				result.properties[propVar][propName] = propValue:match("^%s*(.-)%s*$") -- Trim whitespace
			end
		end
	end

	if next(result.varPathMap) == nil then
		return result, "Tidak ada variabel instance yang dapat dilacak. Pastikan 'Trace Comments' diaktifkan saat membuat skrip."
	end

	return result, nil
end

return ScriptParser
