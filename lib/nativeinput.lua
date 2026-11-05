-- lib/nativeinput.lua — hides the game's own chat input line (and the
-- legacy log windows) while FancyChat's built-in input box is in use.
--
-- Technique: every FFXI menu window is driven by a CTkMenuCtrlData
-- ("MCD") object, and two bytes in it, +0x69 and +0x6A, decide whether
-- the window is drawn.  This is exactly what Ashita's own hideparty
-- addon writes to hide the party frames.  The text input line is the
-- menu named 'menu    inline'; FancyChat already resolves the focused
-- menu's MCD every frame to read its name (render.lua: MenuID is the
-- MCD, [MenuID + 4] its definition entry with the name), so render.lua
-- hands MenuID to capture_inline() while typing.
-- The log windows' MCDs hang off their CTkMenuPrimitive objects at
-- +0x08 (m_pParentMCD), the same link hideparty follows.
--
-- Only the DRAWING is switched off: the game still owns the input, so
-- typing, auto-translate, Tab name completion, history and the caret
-- all keep working, and FancyChat mirrors the text into its own box.
--
-- Safety:
--   * Every write is preceded by a name check (the MCD's name at +0x46
--     must still read 'menu...'), so a stale pointer is never written.
--   * The original byte values are remembered per MCD and written back
--     when hiding stops, on addon unload, and whenever the feature is
--     switched off - FancyChat never leaves the game's input invisible.

require('common')

local M = {}

local NAME_OFF = 0x46
local VIS_A    = 0x69
local VIS_B    = 0x6A

-- mcd address -> { name = <menu name at hide time>, a = <orig>, b = <orig> }
local hidden = {}

local inline_mcd = 0
local inline_menu_name, inline_menu_id = '', 0

-- /fchat inputdiag state (one-shot snapshot, see M.diag_tick).
local diag = { armed = false, open_at = nil, pre = nil }

local function dump(addr, len)
	if addr == nil or addr == 0 then return '  (null)\n' end
	local out = {}
	for row = 0, len - 1, 16 do
		local hex, asc = {}, {}
		for i = 0, 15 do
			local v = ashita.memory.read_uint8(addr + row + i)
			hex[#hex + 1] = string.format('%02X', v)
			asc[#asc + 1] = (v >= 32 and v < 127) and string.char(v) or '.'
		end
		out[#out + 1] = string.format('  +%03X  %s  %s\n', row, table.concat(hex, ' '), table.concat(asc))
	end
	return table.concat(out)
end

-- The MCD itself does not hold the name: its +0x04 points at the menu's
-- entry in the client's static menu-definition table, and the name sits
-- at +0x46 of that entry (confirmed with /fchat inputdiag: the party
-- frame's MCD, the log window's MCD and the focused-menu object all share
-- this layout, and all three read 01 01 at +0x69/+0x6A).
local function mcd_name(mcd)
	if mcd == nil or mcd == 0 then return nil end
	local hdr = ashita.memory.read_uint32(mcd + 0x04)
	if hdr == 0 then return nil end
	local ok, s = pcall(ashita.memory.read_string, hdr + NAME_OFF, 16)
	if not ok or type(s) ~= 'string' then return nil end
	s = s:gsub('%z', '')
	if s:sub(1, 4) ~= 'menu' then return nil end
	return s
end

local function hide(mcd)
	local name = mcd_name(mcd)
	if name == nil then return false end
	local rec = hidden[mcd]
	if rec == nil or rec.name ~= name then
		-- Restore exactly what was there; never invent a value.
		rec = { name = name,
			a = ashita.memory.read_uint8(mcd + VIS_A),
			b = ashita.memory.read_uint8(mcd + VIS_B) }
		hidden[mcd] = rec
	end
	ashita.memory.write_uint8(mcd + VIS_A, 0)
	ashita.memory.write_uint8(mcd + VIS_B, 0)
	return true
end

local function restore(mcd)
	local rec = hidden[mcd]
	hidden[mcd] = nil
	if rec == nil then return end
	-- Only write back if the pointer still names the same window; a
	-- freed menu (the inline line can be torn down on close) is skipped.
	if mcd_name(mcd) == rec.name then
		ashita.memory.write_uint8(mcd + VIS_A, rec.a)
		ashita.memory.write_uint8(mcd + VIS_B, rec.b)
	end
end

-- Called by render.lua with the focused menu's MCD whenever that menu is
-- the chat input line.  0 / nil clears it.
function M.capture_inline(mcd, menu_name, menu_id)
	inline_mcd = mcd or 0
	inline_menu_name = menu_name or ''
	inline_menu_id = menu_id or 0
end

-- Log window MCD from the static slot that render.lua already resolves
-- (uiw.WinPtr1 / uiw.WinPtr2 hold the slot address).
local function log_mcd(slot)
	if slot == nil or slot == 0 then return 0 end
	local win = ashita.memory.read_uint32(slot)
	if win == 0 then return 0 end
	return ashita.memory.read_uint32(win + 0x08)
end

-- Per-frame driver.
--   hide_input: hide the native input line (built-in box is showing it).
--   hide_logs : also hide the legacy log windows that open while typing.
--   slots     : { uiw.WinPtr1, uiw.WinPtr2 }
function M.update(hide_input, hide_logs, slots)
	-- Diagnostics: what the GAME left in the input line's object since
	-- our previous frame's write (tells "flags ignored" from "flags reset
	-- by the game every frame").
	if diag.armed and inline_mcd ~= 0 then
		diag.pre = { mcd = inline_mcd, text = dump(inline_mcd, 0x100),
			a = ashita.memory.read_uint8(inline_mcd + VIS_A),
			b = ashita.memory.read_uint8(inline_mcd + VIS_B) }
	end
	local keep = {}
	if hide_input and inline_mcd ~= 0 and hide(inline_mcd) then
		keep[inline_mcd] = true
	end
	if hide_logs and slots ~= nil then
		for i = 1, #slots do
			local mcd = log_mcd(slots[i])
			if mcd ~= 0 and hide(mcd) then keep[mcd] = true end
		end
	end
	for mcd in pairs(hidden) do
		if not keep[mcd] then restore(mcd) end
	end
end

function M.restore_all()
	for mcd in pairs(hidden) do restore(mcd) end
	inline_mcd = 0
end

function M.active()
	return next(hidden) ~= nil
end

-- ---------------------------------------------------------------------
-- /fchat inputdiag
-- ---------------------------------------------------------------------
function M.diag_arm()
	diag.armed, diag.open_at, diag.pre = true, nil, nil
end

function M.diag_armed()
	return diag.armed
end

-- Called by render.lua every frame while armed, after update().
-- ctx: { input_open, dock_active, docked_shown, chat_input_box, slots }
function M.diag_tick(ctx, now)
	if not diag.armed then return end
	if not ctx.input_open then diag.open_at = nil return end
	diag.open_at = diag.open_at or now
	if now - diag.open_at < 1.0 then return end
	diag.armed = false

	local L = {}
	local function w(fmt, ...) L[#L + 1] = string.format(fmt, ...) end
	w('FancyChat input diagnostics  %s\n\n', os.date('%Y-%m-%d %H:%M:%S'))
	w('ChatInputBox=%s  DockActive=%s  DockedShown=%s  hiding=%s\n',
		tostring(ctx.chat_input_box), tostring(ctx.dock_active), tostring(ctx.docked_shown), tostring(M.active()))
	w('Focused menu name=%q  MenuID=0x%08X  inline MCD=0x%08X  definition [+4]=0x%08X\n',
		inline_menu_name, inline_menu_id, inline_mcd,
		(inline_mcd ~= 0) and ashita.memory.read_uint32(inline_mcd + 4) or 0)
	for mcd, rec in pairs(hidden) do
		w('  hidden 0x%08X %q  orig %d/%d\n', mcd, rec.name, rec.a, rec.b)
	end
	-- The text buffers the box mirrors, as hex (they carry control codes).
	local cmgr = AshitaCore:GetChatManager()
	local function hexs(s)
		if type(s) ~= 'string' then return tostring(s) end
		return (s:gsub('.', function(c) return string.format('%02X ', c:byte()) end))
	end
	local function q(fn)
		local ok, v = pcall(fn)
		return ok and v or ('error: ' .. tostring(v))
	end
	w('\nIsInputOpen=0x%02X  raw len=%s  caret=%s\n', cmgr:IsInputOpen(),
		tostring(q(function() return cmgr:GetInputTextRawLength() end)),
		tostring(q(function() return cmgr:GetInputTextRawCaretPosition() end)))
	w('raw     : %s\n', hexs(q(function() return cmgr:GetInputTextRaw() end)))
	w('display : %s\n', hexs(q(function() return cmgr:GetInputTextDisplay() end)))
	w('parsed  : %s\n', hexs(q(function() return cmgr:GetInputTextParsed() end)))
	w('box text: %q\n', tostring(ctx.box_text))
	if diag.pre ~= nil then
		w('\nInline MCD 0x%08X as the game left it (before this frame\'s write): +69=%d +6A=%d\n',
			diag.pre.mcd, diag.pre.a, diag.pre.b)
		L[#L + 1] = diag.pre.text
	end
	if inline_mcd ~= 0 then
		w('\nInline MCD 0x%08X after this frame\'s write:\n', inline_mcd)
		L[#L + 1] = dump(inline_mcd, 0x100)
		local hdr = ashita.memory.read_uint32(inline_mcd + 4)
		if hdr ~= 0 then
			w('\nIts definition entry 0x%08X:\n', hdr)
			L[#L + 1] = dump(hdr, 0x80)
		end
	end
	if inline_menu_id ~= 0 then
		w('\nFocused menu object [MenuID] 0x%08X:\n', inline_menu_id)
		L[#L + 1] = dump(inline_menu_id, 0x40)
	end
	for i, slot in ipairs(ctx.slots or {}) do
		local win = (slot ~= nil and slot ~= 0) and ashita.memory.read_uint32(slot) or 0
		local mcd = (win ~= 0) and ashita.memory.read_uint32(win + 0x08) or 0
		w('\nLog window %d: slot 0x%08X  obj 0x%08X  MCD(+08) 0x%08X  name=%q\n',
			i, slot or 0, win, mcd, tostring(mcd_name(mcd)))
		L[#L + 1] = dump(win, 0x60)
		if mcd ~= 0 then L[#L + 1] = dump(mcd, 0x80) end
	end
	-- Reference: the party frame, which hideparty hides through the very
	-- same +0x69/+0x6A bytes, to confirm the layout on this client.
	local ok, err = pcall(function()
		local p = ashita.memory.find(0, 0, '66C78182000000????C7818C000000????????C781900000', 0, 0)
		if p == 0 then w('\nParty frame pattern not found.\n') return end
		local slot = ashita.memory.read_uint32(p + 0x19)
		local prim = (slot ~= 0) and ashita.memory.read_uint32(slot) or 0
		local mcd  = (prim ~= 0) and ashita.memory.read_uint32(prim + 0x08) or 0
		w('\nParty frame (hideparty reference): prim 0x%08X  MCD 0x%08X  name=%q\n',
			prim, mcd, tostring(mcd_name(mcd)))
		if mcd ~= 0 then L[#L + 1] = dump(mcd, 0x80) end
	end)
	if not ok then w('\nParty frame probe failed: %s\n', tostring(err)) end

	local path = addon.path .. '/inputdiag.txt'
	local f = io.open(path, 'w')
	if f then
		f:write(table.concat(L))
		f:close()
		print('[FancyChat] Input diagnostics written to ' .. path)
	else
		print('[FancyChat] Could not write ' .. path)
	end
end

return M
