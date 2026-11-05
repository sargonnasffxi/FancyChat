-- lib/tabfont.lua — font and size for the chat window tab bars.
--
-- The tabs are ImGui buttons, so unlike the chat lines (gdifonts, which
-- takes a family NAME) they need a font FILE loaded into ImGui's atlas.
-- The family chosen in Settings is resolved to its file through the
-- Windows font registry (machine-wide and per-user installs), the same
-- table Windows itself uses, so any installed TrueType / OpenType font
-- works.  The file is loaded ONCE, from the addon's load event: adding a
-- font to the atlas mid-frame (inside d3d_present) can crash newer
-- Ashita builds, so a new choice applies on "Restart & apply".
--
-- Size is live: M.push() draws at the bar's automatic size (it follows
-- the chat font size) times allSettings.TabFontScale.

require('common')
local ffi       = require('ffi')
local imgui     = require('imgui')
local imguiWrap = require('imguiWrap')
local state     = require('lib.state')

local M = {}

-- Size the font is rasterised at on ImGui builds without dynamic font
-- sizes (pre-1.92), where it is then scaled; large enough to stay sharp
-- when scaled down.
local BAKE_PX = 32

for _, decl in ipairs({
	'long __stdcall RegOpenKeyExW(void* hKey, const wchar_t* lpSubKey, unsigned long ulOptions, unsigned long samDesired, void** phkResult);',
	'long __stdcall RegEnumValueW(void* hKey, unsigned long dwIndex, wchar_t* lpValueName, unsigned long* lpcchValueName, unsigned long* lpReserved, unsigned long* lpType, unsigned char* lpData, unsigned long* lpcbData);',
	'long __stdcall RegCloseKey(void* hKey);',
	'int MultiByteToWideChar(uint32_t CodePage, uint32_t dwFlags, char* lpMultiByteStr, int cbMultiByte, wchar_t* lpMultiByteStr, int32_t cchWideChar);',
	'int WideCharToMultiByte(uint32_t CodePage, uint32_t dwFlags, wchar_t* lpWideCharStr, int32_t cchWideChar, char* lpMultiByteStr, int32_t cbMultiByte, const char* lpDefaultChar, bool* lpUsedDefaultChar);',
}) do
	pcall(ffi.cdef, decl)
end

local CP_UTF8  = 65001
local KEY_READ = 0x20019
local REG_SZ, REG_EXPAND_SZ = 1, 2
local FONTS_KEY = 'SOFTWARE\\Microsoft\\Windows NT\\CurrentVersion\\Fonts'

-- Predefined HKEYs are sign-extended 32-bit values.
local function hkey(v)
	return ffi.cast('void*', ffi.cast('intptr_t', ffi.cast('int32_t', v)))
end

local function to_utf8(wptr)
	local need = ffi.C.WideCharToMultiByte(CP_UTF8, 0, wptr, -1, nil, 0, nil, nil)
	if need <= 1 then return '' end
	local out = ffi.new('char[?]', need)
	ffi.C.WideCharToMultiByte(CP_UTF8, 0, wptr, -1, out, need, nil, nil)
	return ffi.string(out, need - 1)
end

local function to_wide(s)
	local src = ffi.new('char[?]', #s + 1, s)
	local n = ffi.C.MultiByteToWideChar(CP_UTF8, 0, src, -1, nil, 0)
	local out = ffi.new('wchar_t[?]', n)
	ffi.C.MultiByteToWideChar(CP_UTF8, 0, src, -1, out, n)
	return out
end

-- face name (lower case) -> font file path
local faces = nil

local function scan_key(root, fonts_dir)
	local advapi = ffi.load('advapi32')
	local out = ffi.new('void*[1]')
	if advapi.RegOpenKeyExW(root, to_wide(FONTS_KEY), 0, KEY_READ, out) ~= 0 then return end
	local key = out[0]
	local name = ffi.new('wchar_t[512]')
	local data = ffi.new('unsigned char[4096]')
	local cch  = ffi.new('unsigned long[1]')
	local cb   = ffi.new('unsigned long[1]')
	local typ  = ffi.new('unsigned long[1]')
	local idx = 0
	while true do
		cch[0], cb[0] = 512, 4094
		ffi.fill(data, 4096)
		if advapi.RegEnumValueW(key, idx, name, cch, nil, typ, data, cb) ~= 0 then break end
		idx = idx + 1
		if typ[0] == REG_SZ or typ[0] == REG_EXPAND_SZ then
			local vname = to_utf8(name)
			local file  = to_utf8(ffi.cast('wchar_t*', data))
			-- Machine-wide entries are bare file names under Windows\Fonts;
			-- per-user ones are full paths.
			if not file:find(':', 1, true) and file:sub(1, 2) ~= '\\\\' then
				file = fonts_dir .. '\\' .. file
			end
			local ext = file:lower():match('%.(%a+)$')
			if ext == 'ttf' or ext == 'ttc' or ext == 'otf' then
				-- "Segoe UI (TrueType)", "Cambria & Cambria Math (TrueType)"
				local label = vname:gsub('%s*%b()%s*$', '')
				for face in (label .. ' & '):gmatch('(.-) & ') do
					local k = face:lower()
					-- First registration wins; a plain "X" beats "X Regular".
					if faces[k] == nil then faces[k] = file end
					local base = k:match('^(.-) regular$')
					if base ~= nil and faces[base] == nil then faces[base] = file end
				end
			end
		end
	end
	advapi.RegCloseKey(key)
end

local function build()
	faces = {}
	local fonts_dir = (os.getenv('WINDIR') or 'C:\\Windows') .. '\\Fonts'
	local ok, err = pcall(function()
		scan_key(hkey(0x80000002), fonts_dir)   -- HKEY_LOCAL_MACHINE
		scan_key(hkey(0x80000001), fonts_dir)   -- HKEY_CURRENT_USER (per-user installs)
	end)
	if not ok then print('[FancyChat] Could not read the font registry: ' .. tostring(err)) end
end

-- Font file for an installed family name, or nil.
function M.resolve(family)
	if type(family) ~= 'string' or family == '' then return nil end
	if faces == nil then build() end
	return faces[family:lower()]
end

M.font = nil        -- loaded ImFont, nil = ImGui's default font
M.loaded_for = ''

-- Load the configured tab font.  Call from the addon load event only.
function M.load()
	M.font, M.loaded_for = nil, ''
	local family = state.allSettings.TabFont or ''
	if family == '' then return end
	local path = M.resolve(family)
	if path == nil then
		print('[FancyChat] Tab font "' .. family .. '" is not installed; using the default font.')
		return
	end
	if imgui.AddFontFromFileTTF == nil then
		print('[FancyChat] This Ashita version cannot load fonts; tab font left at the default.')
		return
	end
	local ok, font = pcall(imgui.AddFontFromFileTTF, path, BAKE_PX)
	if ok and font ~= nil then
		M.font, M.loaded_for = font, family
	else
		print('[FancyChat] Could not load tab font "' .. family .. '" (' .. path .. ').')
	end
end

-- Push the tab font for a tab-bar window.  base_scale is the bar's
-- automatic scale (chat font size / 25).  Returns true when the caller
-- must imgui.PopFont() after the bar - same contract as
-- imguiWrap.SetWindowFontScale, which this replaces for the tab bars.
function M.push(base_scale)
	local user = tonumber(state.allSettings.TabFontScale) or 1.0
	local scale = base_scale * user
	if imguiWrap.isNewVer then
		imgui.PushFont(M.font or imgui.GetFont(), imgui.GetFontSize() * scale)
		return true
	end
	if M.font ~= nil then
		-- Legacy ImGui: the font is baked at BAKE_PX; scale it to the size
		-- the default font would have at this window scale.
		M.font.Scale = (imgui.GetFontSize() * scale) / BAKE_PX
		imgui.PushFont(M.font)
		return true
	end
	if imgui.SetWindowFontScale then imgui.SetWindowFontScale(scale) end
	return false
end

return M
