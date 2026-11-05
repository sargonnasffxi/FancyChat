# The Chat Window

Fancychat replaces FFXI's native chat plate with its own in-game chat overlay. The legacy chat keeps running underneath unless you tell it not to (Settings → Extra → "Block legacy chat messages").

## Anatomy

- **Chat plate** — the dark area where messages render
- **Tab bar** — at the top, switches between message categories
- **Side icons** — GuideMe, Notepad, Settings cog, Compact-Tabs toggle
- **Optional second window** — independently configured second plate (Settings → Chat Window → "Enable second chat window")

Your settings, exported color palettes, and Notepad notes are per-character — switching characters loads your other character's preferences automatically. Combat-filter `.txt` files live in a shared `combatfilters/` folder and are available to every character on your account. See [Data Storage](Data-Storage.md) for the on-disk layout.

## Positioning

- **Drag** the plate by clicking and holding on the dark background area (not the tab bar or the side icons).
- **Lock** the position with Settings → Chat Window → "Lock Windows Positions (disables dragging)".
- **Resize** with the small grip in the plate's top-right corner. It is always faintly visible, stronger while the mouse is over the chat and brightest under the cursor, and its click area is a little larger than the mark. Drag right / left to change the width in characters and up / down to change the number of lines; an outline with a "width x lines" label previews the size, and it applies when you let go. The bottom-left corner stays where it is, so the newest line doesn't move. It works with the position locked, needs no restart and keeps your chat history; lines that already arrived keep their old wrap width, new ones wrap at the new width. Limits match the Chat Width (60–135) and Number of chat lines (8–16) settings.
- **Anti-obstruction** mode (Settings → Chat Window → "Prevent obstructing FFXI UI") slides the plate out of the way when an FFXI menu (inventory, magic, mog house, etc.) opens. A companion option does the same for the Auto-Translate menu.
- **Position offsets** (Settings → Chat Window) fine-tune each window's X/Y relative to its anchor.

## Info-icon hover button

The primary chat window has a small info-icon button in its top-left corner. Hover it to bring up a quick-reference panel listing every mouse and keyboard interaction available on chat lines (copy, save to Notepad, zone search, open links, jump to latest, drag, scroll, etc.). Move the mouse off the button to dismiss.

Disable the button from **Settings → Chat Window → "Show help (i) hover button on the first chat window"** if you don't want it on screen. It only appears on the primary window; the secondary window (if enabled) does not show it.

## Tabs

The tab bar shows up to 7 tabs: **All** (or **AllAlt**), **Combat**, **Linkshell**, **Party**, **Tell**, **Shout**, **Custom**. Click a tab heading or use a keyboard shortcut to cycle.

- **All** shows every message by default. Enable Settings → Extra → "Hide combat and custom logs from 'All' tab." to drop combat lines from it — the tab is renamed **AllAlt**.
- **Custom** is configurable. Pick which categories funnel into it from Settings → Chat Window → Custom Tab Modes (NPC, Tell, Party, Linkshell, Shout — any combination).
- **Compact tab mode** collapses the bar into a single button that cycles tabs on click. Toggle with `/fchat compact` or the side icon.

## Typing

With **Settings → Chat Window → "Built-in chat input box"** on (the default), opening the chat input keeps FancyChat on screen and shows what you type in a box docked under the first chat window. The game's own input line and the legacy log it would normally slide open are hidden for as long as you type, and come back as soon as you close the input or switch the option off.

- The text is coloured by the chat command you type (`/p`, `/l`, `/t`, ...), using the same colours as the chat lines, and auto-translate phrases show with their usual brackets.
- If the window is parked at the bottom of the screen it moves up while you type to make room for the box, then drops back.
- If the first chat window isn't on screen when you start typing (FancyChat hidden, Big Mode, or the legacy chat already open) the game's input line is used as usual.

## Scrolling chat history

- **Mouse wheel** while hovering the plate scrolls one line per tick.
- **Shift + mouse wheel** scrolls multiple lines per tick when **Settings → Extra → "Fast scroll chat history"** is enabled.
- **Right-click** while the plate is on screen jumps the scroll back to the bottom (most recent line).
- New messages keep arriving while you're scrolled back — they appear when you return to the bottom.

## Copying & saving lines

- **Click any chat line** to copy its full text to the system clipboard. Multi-line messages copy as one unit. A confirmation echo appears: *"Text successfully copied to clipboard!"*
- **Shift + click** saves the line to the [Notepad](Companion-Panels.md#notepad) instead of the clipboard.
- **Ctrl + click** a line that mentions one or more zone names opens the [Zone Search & Maps](Zone-Search-and-Maps.md) popup at the cursor — `/sea`, FFXIclopedia / bg-wiki shortcuts, and a browser for the bundled zone maps.
- **Click the `[link]` marker** next to a line that contains a URL — opens the URL in your default browser. (Clicking the message text itself still copies normally.)

## Hover previews

Hovering the in-game name of an item, ability, or spell in chat (an "auto-translate" phrase wrapped in special angle brackets, e.g. `❮Item Name❯`) brings up a tooltip showing the corresponding entry from FFXI's resource files: item description and stats, ability cost / type, spell properties.

- Up to **four** preview tooltips can stack horizontally above the chat window when a single line contains multiple recognised names.
- Disable previews from Settings → Extra → "Preview Items/Abilities/Spells on mouse hover".

## Auto-hide

Auto-hide makes Fancychat fade out after a configurable period of inactivity. Enable it in Settings → Chat Window → "Enable Auto-Hide window"; the slider sets the idle delay (5–60 seconds before fade starts).

The faded-out window still receives messages — it just isn't drawn until activity wakes it up. The fade resets to fully visible when:

- A new message arrives on the **currently selected** tab
- You **scroll** the chat with the mouse wheel
- You press one of Fancychat's configured **keyboard shortcuts**
- You **open the chat input box** (start typing `/`)
- An NPC dialog event begins
- You hover over the **GuideMe** or **Notepad** companion panels

> **Mouse hover over the chat plate does NOT wake the auto-hidden window.** Scrolling is the simplest "wake" gesture if you want to peek without typing.

## See also

- [Compact Combat Log](Compact-Combat-Log.md) — combat-message formatting
- [BigMode](BigMode.md) — full-screen chat history overlay
- [Settings Reference](Settings-Reference.md) — every Settings tab walkthrough
