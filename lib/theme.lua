-- lib/theme.lua — FancyChat's interface theme, shared with ZenithMap.
--
-- Every FancyChat ImGui window (Settings, Manual, GuideMe, Notes, the
-- item preview cards, popups, map viewers) and the chat tab bar draw
-- from one palette, derived from a "metal" style - the same three
-- styles ZenithMap's bezel uses:
--
--   gold     - Gilded bronze  (default; matches ZenithMap's settings UI)
--   silver   - Mythril silver
--   obsidian - Obsidian
--
-- The metal also frames the chat plates and the input bar (see
-- M.draw_plate_frame), echoing ZenithMap's bezel.
--
-- Style colours / vars are looked up by NAME through rawget(_G, ...)
-- so a build of Ashita's ImGui binding that lacks one (older 4.1x
-- builds have no ImGuiCol_TabSelected, for example) is skipped rather
-- than raising.  Every push returns a token holding the exact counts
-- pushed, so the matching pop always balances.

require('common')
local imgui = require('imgui')
local state = require('lib.state')

local M = {}

-- ===================================================================
-- Metal styles.  base = bezel band, hi = highlight, lo = dark edge,
-- text = letter colour.  Values copied from ZenithMap (lib/defaults.lua
-- D.frames) so the two addons sit side by side without clashing.
-- ===================================================================
M.frames = {
	gold = {
		label = 'Gilded bronze',
		base  = { 0.420, 0.320, 0.180, 1.0 },
		hi    = { 0.950, 0.820, 0.540, 1.0 },
		lo    = { 0.150, 0.105, 0.050, 1.0 },
		text  = { 0.980, 0.910, 0.680, 1.0 },
	},
	silver = {
		label = 'Mythril silver',
		base  = { 0.400, 0.420, 0.450, 1.0 },
		hi    = { 0.900, 0.930, 0.970, 1.0 },
		lo    = { 0.110, 0.120, 0.140, 1.0 },
		text  = { 0.930, 0.950, 0.990, 1.0 },
	},
	obsidian = {
		label = 'Obsidian',
		base  = { 0.130, 0.130, 0.150, 1.0 },
		hi    = { 0.520, 0.500, 0.560, 1.0 },
		lo    = { 0.030, 0.030, 0.040, 1.0 },
		text  = { 0.880, 0.860, 0.920, 1.0 },
	},
}
M.frame_order = { 'gold', 'silver', 'obsidian' }

local BLACK = { 0, 0, 0, 1 }

local function clamp01(v)
	if v < 0 then return 0 end
	if v > 1 then return 1 end
	return v
end

-- c scaled by k (rgb only), with alpha a.
local function sc(c, k, a)
	return { clamp01(c[1] * k), clamp01(c[2] * k), clamp01(c[3] * k), a or 1.0 }
end

-- Linear mix of a and b (rgb), alpha al.
local function mix(a, b, t, al)
	return {
		a[1] + (b[1] - a[1]) * t,
		a[2] + (b[2] - a[2]) * t,
		a[3] + (b[3] - a[3]) * t,
		al or 1.0,
	}
end

function M.lighten(c, t)
	return mix(c, { 1, 1, 1 }, t, c[4] or 1.0)
end

function M.with_alpha(c, a)
	return { c[1], c[2], c[3], a }
end

-- ===================================================================
-- Palette
-- ===================================================================

-- The ZenithMap settings window, verbatim (lib/configui.lua THEME).
-- Used as-is for the gold style so the two settings windows are
-- indistinguishable; the other metals derive the same roles below.
local GOLD_PALETTE = {
	window_bg      = { 0.075, 0.072, 0.080 },
	popup_bg       = { 0.090, 0.085, 0.095 },
	border         = { 0.550, 0.430, 0.240, 0.55 },
	title_bg       = { 0.140, 0.110, 0.070, 1.00 },
	title_active   = { 0.300, 0.230, 0.120, 1.00 },
	frame_bg       = { 0.160, 0.150, 0.140, 1.00 },
	frame_hover    = { 0.260, 0.220, 0.160, 1.00 },
	frame_active   = { 0.340, 0.270, 0.170, 1.00 },
	button         = { 0.300, 0.230, 0.120, 1.00 },
	button_hover   = { 0.450, 0.350, 0.180, 1.00 },
	button_active  = { 0.580, 0.450, 0.220, 1.00 },
	tab            = { 0.180, 0.140, 0.090, 1.00 },
	tab_selected   = { 0.360, 0.280, 0.150, 1.00 },
	check          = { 0.980, 0.850, 0.500, 1.00 },
	grab           = { 0.800, 0.640, 0.340, 1.00 },
	grab_active    = { 0.980, 0.850, 0.500, 1.00 },
	separator      = { 0.550, 0.430, 0.240, 0.50 },
	table_header   = { 0.200, 0.160, 0.100, 1.00 },
	text           = { 0.930, 0.900, 0.840, 1.00 },
	text_disabled  = { 0.580, 0.560, 0.520, 1.00 },
	accent         = { 0.980, 0.860, 0.550, 1.00 },  -- section headers
	muted          = { 0.700, 0.680, 0.640, 1.00 },
}

local function derive(fr)
	local b, hi, lo, tx = fr.base, fr.hi, fr.lo, fr.text
	local neutral = mix(lo, { 0.16, 0.16, 0.16 }, 0.75)
	return {
		window_bg      = mix(lo, { 0.075, 0.075, 0.080 }, 0.70),
		popup_bg       = mix(lo, { 0.090, 0.090, 0.095 }, 0.65),
		border         = sc(b, 1.31, 0.55),
		title_bg       = sc(b, 0.34, 1.0),
		title_active   = sc(b, 0.72, 1.0),
		frame_bg       = neutral,
		frame_hover    = mix(neutral, b, 0.40),
		frame_active   = mix(neutral, b, 0.65),
		button         = sc(b, 0.72, 1.0),
		button_hover   = sc(b, 1.07, 1.0),
		button_active  = sc(b, 1.38, 1.0),
		tab            = sc(b, 0.43, 1.0),
		tab_selected   = sc(b, 0.86, 1.0),
		check          = M.with_alpha(hi, 1.0),
		grab           = sc(hi, 0.84, 1.0),
		grab_active    = M.with_alpha(hi, 1.0),
		separator      = sc(b, 1.31, 0.50),
		table_header   = sc(b, 0.48, 1.0),
		text           = mix(tx, { 0.93, 0.93, 0.93 }, 0.55),
		text_disabled  = mix(tx, { 0.56, 0.56, 0.56 }, 0.80),
		accent         = M.with_alpha(hi, 1.0),
		muted          = mix(tx, { 0.68, 0.68, 0.68 }, 0.75),
	}
end

-- Obsidian's base is nearly black, so buttons scaled from it vanish
-- into the window; lift it to a readable slate.
local function derive_obsidian(fr)
	local p = derive({ base = { 0.300, 0.290, 0.340, 1.0 }, hi = fr.hi, lo = fr.lo, text = fr.text })
	p.accent = { 0.780, 0.740, 0.880, 1.0 }
	p.check  = { 0.780, 0.740, 0.880, 1.0 }
	p.grab   = { 0.620, 0.590, 0.720, 1.0 }
	p.grab_active = { 0.800, 0.770, 0.900, 1.0 }
	return p
end

local palettes = {}

function M.key()
	local k = state.allSettings and state.allSettings.UITheme
	if (k == nil) or (M.frames[k] == nil) then return 'gold' end
	return k
end

function M.frame()
	return M.frames[M.key()]
end

function M.palette()
	local k = M.key()
	local p = palettes[k]
	if p == nil then
		if k == 'gold' then
			p = GOLD_PALETTE
		elseif k == 'obsidian' then
			p = derive_obsidian(M.frames[k])
		else
			p = derive(M.frames[k])
		end
		palettes[k] = p
	end
	return p
end

-- Window background opacity (Settings -> Chat Window -> Appearance).
function M.window_alpha()
	local a = tonumber(state.allSettings and state.allSettings.UIWindowAlpha) or 0.95
	return clamp01(a)
end

function M.accent()  return M.palette().accent end
function M.muted()   return M.palette().muted end
function M.text()    return M.palette().text end

function M.col(c, a)
	return imgui.GetColorU32({ c[1], c[2], c[3], (a or 1.0) * (c[4] or 1.0) })
end

-- ===================================================================
-- Push / pop
-- ===================================================================

local function push(vars, cols)
	local nv, nc = 0, 0
	for _, v in ipairs(vars) do
		local id = rawget(_G, v[1])
		if id ~= nil then imgui.PushStyleVar(id, v[2]); nv = nv + 1 end
	end
	for _, c in ipairs(cols) do
		local id = rawget(_G, c[1])
		if id ~= nil then imgui.PushStyleColor(id, c[2]); nc = nc + 1 end
	end
	return { nv, nc }
end

function M.pop(token)
	if token == nil then return end
	if token[2] > 0 then imgui.PopStyleColor(token[2]) end
	if token[1] > 0 then imgui.PopStyleVar(token[1]) end
end

-- Rounding / border only: these never move content, so pixel-placed
-- layouts (the Settings tabs, the item preview cards) are unaffected.
local function shape_vars()
	return {
		{ 'ImGuiStyleVar_WindowRounding',    6 },
		{ 'ImGuiStyleVar_ChildRounding',     4 },
		{ 'ImGuiStyleVar_FrameRounding',     3 },
		{ 'ImGuiStyleVar_PopupRounding',     5 },
		{ 'ImGuiStyleVar_GrabRounding',      3 },
		{ 'ImGuiStyleVar_TabRounding',       3 },
		{ 'ImGuiStyleVar_ScrollbarRounding', 6 },
		{ 'ImGuiStyleVar_WindowBorderSize',  1 },
		{ 'ImGuiStyleVar_PopupBorderSize',   1 },
	}
end

local function window_cols(p, alpha)
	local wa = alpha or M.window_alpha()
	local wb = p.window_bg
	local pb = p.popup_bg
	return {
		{ 'ImGuiCol_WindowBg',             { wb[1], wb[2], wb[3], wa } },
		{ 'ImGuiCol_ChildBg',              { 0, 0, 0, 0.18 } },
		{ 'ImGuiCol_PopupBg',              { pb[1], pb[2], pb[3], math.max(wa, 0.96) } },
		{ 'ImGuiCol_Border',               p.border },
		{ 'ImGuiCol_BorderShadow',         { 0, 0, 0, 0 } },
		{ 'ImGuiCol_TitleBg',              p.title_bg },
		{ 'ImGuiCol_TitleBgActive',        p.title_active },
		{ 'ImGuiCol_TitleBgCollapsed',     p.title_bg },
		{ 'ImGuiCol_MenuBarBg',            p.title_bg },
		{ 'ImGuiCol_FrameBg',              p.frame_bg },
		{ 'ImGuiCol_FrameBgHovered',       p.frame_hover },
		{ 'ImGuiCol_FrameBgActive',        p.frame_active },
		{ 'ImGuiCol_Button',               p.button },
		{ 'ImGuiCol_ButtonHovered',        p.button_hover },
		{ 'ImGuiCol_ButtonActive',         p.button_active },
		{ 'ImGuiCol_Header',               M.with_alpha(p.button, 0.80) },
		{ 'ImGuiCol_HeaderHovered',        M.with_alpha(p.button_hover, 0.90) },
		{ 'ImGuiCol_HeaderActive',         p.button_active },
		{ 'ImGuiCol_Tab',                  p.tab },
		{ 'ImGuiCol_TabHovered',           p.button_hover },
		{ 'ImGuiCol_TabSelected',          p.tab_selected },
		{ 'ImGuiCol_TabActive',            p.tab_selected },
		{ 'ImGuiCol_TabDimmed',            p.tab },
		{ 'ImGuiCol_TabUnfocused',         p.tab },
		{ 'ImGuiCol_TabDimmedSelected',    p.tab_selected },
		{ 'ImGuiCol_TabUnfocusedActive',   p.tab_selected },
		{ 'ImGuiCol_CheckMark',            p.check },
		{ 'ImGuiCol_SliderGrab',           p.grab },
		{ 'ImGuiCol_SliderGrabActive',     p.grab_active },
		{ 'ImGuiCol_Separator',            p.separator },
		{ 'ImGuiCol_SeparatorHovered',     M.with_alpha(p.grab, 0.78) },
		{ 'ImGuiCol_SeparatorActive',      p.grab_active },
		{ 'ImGuiCol_ResizeGrip',           M.with_alpha(p.button, 0.45) },
		{ 'ImGuiCol_ResizeGripHovered',    M.with_alpha(p.button_hover, 0.80) },
		{ 'ImGuiCol_ResizeGripActive',     p.button_active },
		{ 'ImGuiCol_ScrollbarBg',          { 0, 0, 0, 0.25 } },
		{ 'ImGuiCol_ScrollbarGrab',        M.with_alpha(p.button, 0.85) },
		{ 'ImGuiCol_ScrollbarGrabHovered', p.button_hover },
		{ 'ImGuiCol_ScrollbarGrabActive',  p.button_active },
		{ 'ImGuiCol_TableHeaderBg',        p.table_header },
		{ 'ImGuiCol_TableBorderStrong',    p.border },
		{ 'ImGuiCol_TableBorderLight',     M.with_alpha(p.border, 0.30) },
		{ 'ImGuiCol_TableRowBgAlt',        { 1, 1, 1, 0.03 } },
		{ 'ImGuiCol_TextSelectedBg',       M.with_alpha(p.button_hover, 0.60) },
		{ 'ImGuiCol_PlotHistogram',        p.grab },
		{ 'ImGuiCol_TextLink',             p.accent },
		{ 'ImGuiCol_Text',                 p.text },
		{ 'ImGuiCol_TextDisabled',         p.text_disabled },
	}
end

-- Full theme for a regular FancyChat window.  `alpha` overrides the
-- window-background opacity (nil = the user's setting).
function M.push_window(alpha)
	return push(shape_vars(), window_cols(M.palette(), alpha))
end

-- Stack used by the parameterless PushWindowStyle / PopWindowStyle
-- globals (lib/ui_helpers.lua), so existing call sites stay simple.
local stack = {}

-- Called once at the top of each present frame.  If a Lua error ever
-- skipped a pop, ImGui recovers its own style stack at frame end; this
-- keeps ours from carrying the stale tokens into the next frame.
function M.begin_frame()
	for i = #stack, 1, -1 do stack[i] = nil end
end

function M.push_window_stacked(alpha)
	stack[#stack + 1] = M.push_window(alpha)
end

function M.pop_window_stacked()
	local t = stack[#stack]
	stack[#stack] = nil
	M.pop(t)
end

-- Gold section header with a rule under it (ZenithMap's section()).
function M.section(text)
	imgui.Spacing()
	imgui.TextColored(M.accent(), text)
	imgui.Separator()
end

-- ===================================================================
-- Chat tab bar
-- ===================================================================

-- Colours for the chat tab buttons, keeping the caller's plate alpha
-- so the bar still reads as part of the chat.
--   plate = {r, g, b, a} of the chat plate fill.
function M.tab_colors(plate)
	local p  = M.palette()
	local fr = M.frame()
	local a  = plate[4]
	-- Selected / hovered never fall below these so the active tab
	-- stays legible on a nearly transparent plate.
	local sa = math.max(a, 0.70)
	local ha = math.max(a, 0.55)
	return {
		normal        = { plate[1], plate[2], plate[3], a },
		hover         = M.with_alpha(p.button_hover, ha),
		active        = M.with_alpha(p.button_active, sa),
		selected      = M.with_alpha(p.tab_selected, sa),
		selected_hov  = M.with_alpha(p.button_hover, sa),
		selected_act  = M.with_alpha(p.button_active, sa),
		text          = M.with_alpha(p.text, 0.85),
		selected_text = M.with_alpha(fr.text, 1.0),
		underline     = M.col(fr.hi, 0.90),
	}
end

-- Gold rule along the bottom of the last item (the selected tab).
function M.underline_last_item(color_u32)
	local ok = pcall(function()
		local x0, y0 = imgui.GetItemRectMin()
		local x1, y1 = imgui.GetItemRectMax()
		if (type(x0) ~= 'number') or (type(x1) ~= 'number') then return end
		local dl = imgui.GetWindowDrawList()
		local inset = math.min(6, (x1 - x0) * 0.15)
		dl:AddLine({ x0 + inset, y1 - 1.5 }, { x1 - inset, y1 - 1.5 }, color_u32, 2.0)
	end)
	return ok
end

-- ===================================================================
-- Plate frame (ZenithMap bezel, square variant)
-- ===================================================================

-- Frame styles the user can pick for the chat plate; 'none' turns it
-- off.  Kept separate from UITheme so a user can run silver windows
-- with no plate frame, and so on.
-- Chat window edge style (Settings -> Appearance -> Chat window edges):
--   'frame' - metal bezel (ChatFrame on)
--   'none'  - no border at all
--   'fade'  - no border, plate edges fade to transparent (ChatEdgeFade)
local function edge_fade_on()
	local f = state.allSettings and state.allSettings.ChatEdgeFade
	return (type(f) == 'table') and (f[1] == true)
end

function M.plate_frame_enabled()
	if edge_fade_on() then return false end
	local f = state.allSettings and state.allSettings.ChatFrame
	return (type(f) == 'table') and (f[1] == true)
end

function M.edge_style()
	if edge_fade_on() then return 'fade' end
	return M.plate_frame_enabled() and 'frame' or 'none'
end

-- Edge fade distance in pixels for the chat plates; 0 when off.
function M.plate_fade_px()
	if not edge_fade_on() then return 0 end
	local px = tonumber(state.allSettings.ChatEdgeFadePx) or 24
	if px < 1 then px = 1 end
	return px
end

-- Draws a metal bezel AROUND (outside) the rect x0,y0 - x1,y1, so it
-- never covers chat text.  The window's own clip rect is lifted for
-- the duration because the bezel lies in the window padding.
-- `alpha` fades the whole frame (auto-hide), `bezel` is the band
-- thickness in pixels.
function M.draw_plate_frame(dl, x0, y0, x1, y1, alpha, bezel)
	if (dl == nil) or (x0 == nil) or (x1 == nil) or (x1 - x0 < 4) or (y1 - y0 < 4) then return end
	local op = clamp01(alpha or 1.0)
	if op <= 0.01 then return end
	local fr = M.frame()
	local bz = bezel or 3
	pcall(function()
		dl:PushClipRectFullScreen()
		local ok, err = pcall(function()
			local half = bz * 0.5
			-- Soft outer shadow.
			dl:AddRect({ x0 - bz - 1.5, y0 - bz - 1.5 }, { x1 + bz + 1.5, y1 + bz + 1.5 },
				M.col(BLACK, 0.40 * op), 5, 0, 2.0)
			-- Bezel band.
			dl:AddRect({ x0 - half, y0 - half }, { x1 + half, y1 + half },
				M.col(fr.base, op), 4, 0, bz)
			-- Dark outer edge.
			dl:AddRect({ x0 - bz, y0 - bz }, { x1 + bz, y1 + bz },
				M.col(fr.lo, op), 4, 0, 1.2)
			-- Highlight line along the band.
			local hh = bz * 0.30
			dl:AddRect({ x0 - hh, y0 - hh }, { x1 + hh, y1 + hh },
				M.col(fr.hi, 0.55 * op), 3, 0, 1.0)
			-- Dark inner edge against the plate.
			dl:AddRect({ x0, y0 }, { x1, y1 }, M.col(fr.lo, 0.85 * op), 2, 0, 1.0)
			-- Corner studs, as on the bezel badges.
			local r = math.max(2.0, bz * 0.75)
			for _, c in ipairs({ { x0, y0 }, { x1, y0 }, { x0, y1 }, { x1, y1 } }) do
				dl:AddCircleFilled({ c[1], c[2] }, r + 1.0, M.col(fr.lo, op), 12)
				dl:AddCircleFilled({ c[1], c[2] }, r, M.col(fr.base, op), 12)
				dl:AddCircleFilled({ c[1] - r * 0.3, c[2] - r * 0.3 }, r * 0.40, M.col(fr.hi, 0.80 * op), 8)
			end
		end)
		dl:PopClipRect()
		if not ok then error(err, 0) end
	end)
end

-- Convenience for a gdifonts rect object (ro.RectBG[n], ro.InputBarBG).
function M.draw_rect_object_frame(dl, rect_obj, alpha, bezel)
	if (rect_obj == nil) or (rect_obj.settings == nil) then return end
	local s = rect_obj.settings
	local x, y = tonumber(s.position_x), tonumber(s.position_y)
	local w, h = tonumber(s.width), tonumber(s.height)
	if (x == nil) or (y == nil) or (w == nil) or (h == nil) then return end
	M.draw_plate_frame(dl, x, y, x + w, y + h, alpha, bezel)
end

return M
