# Settings Reference

Open the Settings panel with `/fchat settings`. It has six tabs:

1. [Chat Window](#chat-window) — visual layout, plate dimensions, second chat
2. [Font Colors](#font-colors) — per-message-mode colors, import / export
3. [Shortcuts](#shortcuts) — keyboard combos
4. [Extra](#extra) — block legacy chat, filtering toggles, timestamps, alerts, hover preview, etc.
5. [CL Filters](#cl-filters) — combat-log filter file picker
6. [Tools](#tools) — save logs, open folders, restore legacy chat

## Chat Window

Visual appearance and behaviour of the chat plate.

### Appearance

These apply immediately, with no restart.

- **Interface theme** — colour scheme for every FancyChat window (Settings, Manual, GuideMe, Notes, item previews, the zone search popup, map viewers) and the chat tab bar. **Gilded bronze** (the default) matches the ZenithMap addon's settings window; **Mythril silver** and **Obsidian** match its other frame styles.
- **Window opacity** — background opacity of those windows (0.50–1.00, default 0.95).
- **Chat window edges** — **Metal frame** draws a bezel in the theme's metal around each chat plate, the Big Mode plate and the input box, like the ZenithMap frame (the default). **No border** shows the plates only. **No border, faded edges** also fades each chat plate — its colour or its background image — to transparent towards its edges; **Edge fade width** (4–120 px, default 24) sets how far in the fade reaches, capped at half the plate's height. The docked chat input box fades too, more gently. All apply immediately.

### Layout

- **Font Size**, **Chat Width**, **Plate BG Alpha**, **Number of chat lines** — basic dimensions and dark-background opacity. Changes require **Restart & apply** to take effect.
- **Chat Font** — the font for the chat lines, Big Mode and the chat input box. The list shows every TrueType / OpenType font installed on your PC (for example Segoe UI); type in the box at the top of the list to filter it, and use **Rescan** after installing a new font. Applies on **Restart & apply**. Consolas, the default, is fixed-width, and line wrapping is tuned for it: with a proportional font lines wrap a little before the plate edge, and a line of mostly wide capitals can run slightly past it. If the chosen font is later uninstalled, it shows as "(not installed)" and the chat falls back to Arial.
- **Tab Font** — the font for the tab buttons along the chat windows (All, Combat, Party, ...): **Default (Ashita font)** or any installed font. Applies on **Restart & apply**.
- **Tab Text Size** — size of the tab text, 50–200% of the automatic size (which follows **Font Size**). Applies immediately.
- **Enable second chat window** — adds a separate plate (independently configurable).
- **Custom Tab Modes** — pick which message types funnel into the **Custom** tab (NPC, Tell, Party, Linkshell, Shout — any combination).
- **Position Offsets** — fine-tune each plate's X/Y offset relative to its anchor. Save / Reset buttons provided.
- **Lock Windows Positions (disables dragging)** — prevents accidental drag.
- **Show help (i) hover button on the first chat window** — toggles the small info-icon button in the top-left corner of the primary chat. Hovering it pops up a quick-reference panel listing the built-in mouse / keyboard interactions. Enabled by default.
- **Compact tabs in the bottom-left corner** — relocates the tab buttons to a small corner cluster.
- **Gampad Chat Navigation** — controller-friendly tab switching and history scroll.
- **Enable Auto-Hide window** — fade the chat out after idle. Slider sets the delay (5–60 s). See [The Chat Window → Auto-hide](The-Chat-Window.md#auto-hide).
- **Use half window length for docked UI elements** — companion panels (GuideMe, Notepad) use half the chat width when docked.
- **Prevent obstructing FFXI UI** — auto-slide when an FFXI menu opens.
- **Prevent obstructing Auto-Translate menu as well** — same thing for that specific UI.

### Chat input

These apply immediately, with no restart.

- **Built-in chat input box (replaces the game's input line)** — while you type, the game's own input line and the legacy log it opens are hidden, FancyChat stays on screen, and your text appears in a box docked under the first chat window, at the plate's width, in the chat font and plate colour. Typing, auto-translate, Tab name completion and history work exactly as before, because the game still handles the input. If the window sits at the bottom of the screen it is lifted while you type so the box fits. When the first chat window isn't on screen (FancyChat hidden, Big Mode, or legacy chat already open) the game's input line is used instead. On by default. See [The Chat Window → Typing](The-Chat-Window.md#typing).
- **Enable input chat bar** — a separate, movable bar that mirrors the input line, with its own width, font size, padding, colour, opacity and background image. Used only when the built-in box is off or the first chat window isn't shown.
- **Test mode** — shows the built-in box (or the floating bar) without opening the chat input, so you can preview it. Not saved.
- **Lock bar position** — stops the floating bar from being dragged.

## Font Colors

Per-mode color editor. See [Color Palettes](Color-Palettes.md) for the full walkthrough including palette sharing.

- Each editable color is a small swatch labeled with the category. Click the swatch to bring up the picker; the arrow button next to it applies the picker's current color.
- Hover the **(i)** icon next to a label for a description of which messages use that color.
- **Reset Colors** restores the entire palette to the addon defaults.
- **Export Colors** opens a dialog so you can name the file before saving. The default suggestion is `colorset_<your character>_<N>` (auto-incrementing). Files are written to `addons/fancychat/chatcolors/` and can be edited as plain text.
- **Import Colors** opens a dialog listing every colorset file in `chatcolors/` — pick one and Load it to replace the current palette. Any file someone hands you can simply be dropped into the folder and imported, no renaming required.

## Shortcuts

Configure keyboard combos for four actions. **All four shortcuts default to disabled** — tick the **Enabled** checkbox per row to activate one.

| Action (UI label) | Default key combo (when enabled) |
|---|---|
| Hide FancyChat Addon | Shift + C |
| Big Window Mode | Shift + G |
| Scroll Chat Tabs (window 1) | Shift + X |
| Scroll Chat Tabs (window 2) | Shift + B |

Each row offers a modifier dropdown (Shift / Alt / Ctrl) and a main-key dropdown (A–Z, `.`, `,`, `Tab`, `~`). The **Reset default keys** button restores the original key assignments without changing the **Enabled** flags.

Below the shortcuts a **Commands to manually macro features** reference panel lists slash commands — useful if you prefer to bind FFXI macros instead of keyboard shortcuts. See [Commands & Shortcuts](Commands-and-Shortcuts.md).

## Extra

Behaviour toggles that don't fit elsewhere.

### Block legacy chat messages

Suppress messages from being drawn in FFXI's native chat window (Fancychat shows them anyway).

- **All** — blocks every category. Required if you want Fancychat to be the *only* visible chat. Triggers a warning the first time you enable it because it can interfere with NPC dialogues in untested edge cases.
- **Combat (recommended)** — blocks only combat messages, leaving the legacy chat available for everything else.

### Chat message filtering (experimental)

- **Hide combat and custom logs from 'All' tab.** — routes combat / custom lines only to their dedicated tabs. The All tab is renamed AllAlt.
- **Hide alliance combat log** — drops alliance-member combat lines.
- **Hide non-party combat log** — drops non-party combat lines.
- **Only show you and your pet logs.** — narrowest filter; implies the two above.

### Other settings

- **Compact Combat Log** — see [Compact Combat Log](Compact-Combat-Log.md).
- **Timestamp** + **Format** — prepend `[HH:MM:SS]` (long) or `[HH:MM]` (short) to every line.
- **Timestamp as a line** + **Every** — periodic horizontal banner with dashes around the time. Mutually exclusive with the per-line Timestamp.
- **Warning messages on R0s** — chat warning when an R0 connection error occurs.
- **Precise TOD Timestamps** — appends a precise time-of-death stamp to enemy-killed lines.
- **Incoming /tell notifications** — sound on incoming tell. Notification dropdown + volume boost.
- **Chat word alert** — sound when a configurable word appears in chat. Per-channel toggles.
- **Preview Items/Abilities/Spells on mouse hover** — toggles hover tooltips.
- **Auto-restore logs when opening Legacy Chat** — re-injects buffered messages into legacy chat each time you open it.
- **Colorblind mode for damage done/taken text** — see [Compact Combat Log](Compact-Combat-Log.md#colorblind-mode).
- **Fast scroll chat history** — enables Shift + mouse-wheel for multi-line scroll.
- **Dock GuideMe/Notes on the second chat window** — see [Companion Panels](Companion-Panels.md#docking).

## CL Filters

Combat-log filter file picker. See [Combat Filters](Combat-Filters.md) for the full walkthrough.

- **Active filter file** dropdown — lists every `.txt` in the `combatfilters/` folder. Selection persists between sessions.
- **Refresh** button — re-scans the folder for newly added / renamed files.
- **Edit Selected Filter** — opens the picked file in your default text editor.
- **Reload Selected Filter** — re-reads the file without restart.
- **Open Folder** — opens `combatfilters/` in Explorer.
- **Enable Combat Log chat filters** — master switch.
- A live table shows every active filter and its scope (All / All but you / All but party).

## Tools

One-click utilities.

- **Save Chat Logs** — writes every tab's current contents to `config/addons/fancychat/logs/<character>/ChatLogs_<timestamp>/`. See [Data Storage → Logs](Data-Storage.md#saved-chat-logs).
- **Open Logs Folder** — opens the logs folder in Explorer.
- **Open Manual** — opens the in-game manual.
- **Restore Legacy Chat Logs** — re-injects Fancychat's buffered chat history back into the FFXI legacy chat. Use this for bug-report screenshots that need the legacy chat layout.

## See also

- [Color Palettes](Color-Palettes.md)
- [Combat Filters](Combat-Filters.md)
- [Commands & Shortcuts](Commands-and-Shortcuts.md)
- [Data Storage](Data-Storage.md)
