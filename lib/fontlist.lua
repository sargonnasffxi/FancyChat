-- lib/fontlist.lua — the font families installed on this machine, for the
-- chat font picker (Settings -> Chat Window).
--
-- Enumerated straight from Windows with EnumFontFamiliesExW (the same
-- API the gdifonts DLL's GetFontAvailable uses), so every name listed is
-- one the DLL's Gdiplus::FontFamily(name) lookup can open.  Only
-- TrueType-outline families are kept (which includes TrueType-flavoured
-- OpenType such as Segoe UI): GDI+ cannot draw raster fonts or
-- PostScript-outline .otf files.  Vertical '@' variants are dropped.
-- Names are returned as UTF-8, which is what the DLL expects.
--
-- The scan runs once, on first use, and is cached; M.refresh() rescans
-- (for fonts installed while the game is running).

require('common')
local ffi = require('ffi')

local M = {}

-- Each declaration on its own so one that is already declared elsewhere
-- (gdifonts/encoding.lua declares WideCharToMultiByte) cannot block the
-- others.
for _, decl in ipairs({
	[[typedef struct {
		long lfHeight; long lfWidth; long lfEscapement; long lfOrientation; long lfWeight;
		unsigned char lfItalic; unsigned char lfUnderline; unsigned char lfStrikeOut;
		unsigned char lfCharSet; unsigned char lfOutPrecision; unsigned char lfClipPrecision;
		unsigned char lfQuality; unsigned char lfPitchAndFamily;
		wchar_t lfFaceName[32];
	} fc_LOGFONTW;]],
	'typedef int (__stdcall *fc_FONTENUMPROCW)(const fc_LOGFONTW*, const void*, unsigned long, intptr_t);',
	'int __stdcall EnumFontFamiliesExW(void* hdc, fc_LOGFONTW* lpLogfont, fc_FONTENUMPROCW proc, intptr_t lParam, unsigned long dwFlags);',
	'void* __stdcall GetDC(void* hWnd);',
	'int __stdcall ReleaseDC(void* hWnd, void* hDC);',
	'int WideCharToMultiByte(uint32_t CodePage, uint32_t dwFlags, wchar_t* lpWideCharStr, int32_t cchWideChar, char* lpMultiByteStr, int32_t cbMultiByte, const char* lpDefaultChar, bool* lpUsedDefaultChar);',
}) do
	pcall(ffi.cdef, decl)
end

local DEFAULT_CHARSET   = 1
local TRUETYPE_FONTTYPE = 4
local CP_UTF8           = 65001

local cache = nil

local function to_utf8(wbuf)
	local out = ffi.new('char[128]')
	local n = ffi.C.WideCharToMultiByte(CP_UTF8, 0, wbuf, -1, out, 128, nil, nil)
	if n <= 1 then return nil end
	return ffi.string(out, n - 1)
end

local function scan()
	local names, seen = {}, {}
	local ok, err = pcall(function()
		local lf = ffi.new('fc_LOGFONTW')
		lf.lfCharSet = DEFAULT_CHARSET     -- every family, once per charset
		local cb = ffi.cast('fc_FONTENUMPROCW', function(plf, _, ftype, _)
			if bit.band(ftype, TRUETYPE_FONTTYPE) ~= 0 then
				local name = to_utf8(plf.lfFaceName)
				if name ~= nil and name:sub(1, 1) ~= '@' then
					local key = name:lower()
					if not seen[key] then
						seen[key] = true
						names[#names + 1] = name
					end
				end
			end
			return 1
		end)
		local hdc = ffi.C.GetDC(nil)
		local ok2, err2 = pcall(ffi.C.EnumFontFamiliesExW, hdc, lf, cb, 0, 0)
		ffi.C.ReleaseDC(nil, hdc)
		cb:free()
		if not ok2 then error(err2, 0) end
	end)
	if not ok then
		print('[FancyChat] Could not list installed fonts: ' .. tostring(err))
	end
	table.sort(names, function(a, b) return a:lower() < b:lower() end)
	return names
end

-- Sorted list of installed font family names (UTF-8).
function M.get()
	if cache == nil then cache = scan() end
	return cache
end

function M.refresh()
	cache = nil
	return M.get()
end

-- True if `name` is an installed family (case-insensitive).
function M.has(name)
	if type(name) ~= 'string' or name == '' then return false end
	local key = name:lower()
	for _, n in ipairs(M.get()) do
		if n:lower() == key then return true end
	end
	return false
end

return M
