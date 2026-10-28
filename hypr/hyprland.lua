---@module 'hl'

-------------------
----- IMPORTS -----
-------------------

local colors = require("colors")

require("monitors")
require("workspaces")

-------------------
---- AUTOSTART ----
-------------------
-- See https://wiki.hypr.land/Configuring/Basics/Autostart/

-- Autostart necessary processes (like notifications daemons, status bars, etc.)
-- Or execute your favorite apps at launch like this:
--
-- hl.on("hyprland.start", function ()
--   hl.exec_cmd(terminal)
--   hl.exec_cmd("nm-applet")
--   hl.exec_cmd("waybar & hyprpaper & firefox")
-- end)

hl.on("hyprland.start", function()
	-- hl.exec_cmd("~/.config/hypr/portal.sh") -- desativado: portais já sobem pelo systemd
	hl.exec_cmd("dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP")
	hl.exec_cmd("systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP")
	hl.exec_cmd("waybar")
	hl.exec_cmd("kbuildsycoca6")
	hl.exec_cmd("/usr/lib/polkit-kde-authentication-agent-1")
	hl.exec_cmd("wl-paste --type text --watch cliphist store")
	hl.exec_cmd("wl-paste --type image --watch cliphist store")
	hl.exec_cmd("hyprpaper")
	hl.exec_cmd("matugen image " .. colors.image)
	hl.exec_cmd("~/.config/hypr/scripts/battery_notify.sh")
	hl.exec_cmd("~/.config/hypr/scripts/modo-energia.sh monitor")
	hl.exec_cmd("~/.config/hypr/scripts/montar-drive.sh")
	hl.exec_cmd("systemctl --user start hyprpolkitagent")
	hl.exec_cmd("otd-daemon")
	hl.exec_cmd(
		"scrcpy --video-source=camera --camera-size=1920x1080 --max-fps=60 --v4l2-sink=/dev/video0 --no-playback --audio-source=mic --no-audio-playback"
	)
end)

---------------------
---- MY PROGRAMS ----
---------------------
-- See https://wiki.hypr.land/Configuring/Keywords/
-- Set programs that you use

local terminal = "kitty"
local fileManager = "dolphin"
local menu = "pkill rofi ||/home/thales/.config/rofi/scripts/launcher_t1"
local browser = "firefox"

------------------------------
---- ENVIRONMENT VARIABLES ---
------------------------------

-- See https://wiki.hypr.land/Configuring/Environment-variables/

hl.env("XCURSOR_SIZE", 18)

hl.env("HYPRCURSOR_SIZE", 18)

hl.env("XDG_CURRENT_DESKTOP", "Hyprland")

hl.env("XDG_SESSION_TYPE", "wayland")

hl.env("XDG_SESSION_DESKTOP", "Hyprland")

hl.env("GDK_BACKEND", "wayland,x11,*")

hl.env("QT_QPA_PLATFORM", "wayland;xcb")

hl.env("QT_QPA_PLATFORMTHEME", "qt6ct")

hl.env("QT_AUTO_SCREEN_SCALE_FACTOR", 1)

hl.env("QT_WAYLAND_DISABLE_WINDOWDECORATION", 1)

hl.env("QT_QPA_PLATFORM", "wayland")

hl.env("QT_QPA_PLATFORMTHEME", "qt6ct")

hl.env("XDG_MENU_PREFIX", "arch-")

--------------------
---- PERMISSIONS ---
--------------------
-- See https://wiki.hypr.land/Configuring/Permissions/
-- Please note permission changes here require a Hyprland restart and are not applied on-the-fly
-- for security reasons

hl.config({
	ecosystem = {
		no_update_news = true,
	},
})

-- permission = /usr/(bin|local/bin)/grim, screencopy, allow
-- permission = /usr/(lib|libexec|lib64)/xdg-desktop-portal-hyprland, screencopy, allow
-- permission = /usr/(bin|local/bin)/hyprpm, plugin, allow

----------------------
---- LOOK AND FEEL ---
----------------------
-- Refer to https://wiki.hypr.land/Configuring/Basics/Variables/
-- https://wiki.hypr.land/Configuring/Variables/-general

hl.config({
	general = {
		gaps_in = 5,
		gaps_out = 8,
		border_size = 2,
		-- https://wiki.hypr.land/Configuring/Variables/-variable-types for info about colors
		-- Set to true enable resizing windows by clicking and dragging on borders and gaps
		resize_on_border = false,
		-- Please see https://wiki.hypr.land/Configuring/Tearing/ before you turn this on
		allow_tearing = false,
		layout = "dwindle",
		col = {
			active_border = colors.primary,
			inactive_border = colors.inverse_primary,
		},
	},
})

-- https://wiki.hypr.land/Configuring/Variables/-decoration

hl.config({
	decoration = {
		rounding = 8,
		rounding_power = 2,
		-- Change transparency of focused and unfocused windows
		active_opacity = 1.0,
		inactive_opacity = 1.0,
		shadow = {
			enabled = true,
			range = 4,
			render_power = 3,
			color = colors.shadow,
		},
		-- https://wiki.hypr.land/Configuring/Variables/-blur
		blur = {
			enabled = true,
			size = 10,
			passes = 3,
			vibrancy = 0.1696,
		},
	},
})

-- https://wiki.hypr.land/Configuring/Variables/-animations

hl.animations = {
	enabled = true,
}

-- Default curves and animations, see https://wiki.hypr.land/Configuring/Advanced-and-Cool/Animations/
hl.curve("easeOutQuint", { type = "bezier", points = { { 0.23, 1 }, { 0.32, 1 } } })
hl.curve("easeInOutCubic", { type = "bezier", points = { { 0.65, 0.05 }, { 0.36, 1 } } })
hl.curve("linear", { type = "bezier", points = { { 0, 0 }, { 1, 1 } } })
hl.curve("almostLinear", { type = "bezier", points = { { 0.5, 0.5 }, { 0.75, 1 } } })
hl.curve("quick", { type = "bezier", points = { { 0.15, 0 }, { 0.1, 1 } } })

-- Default springs
hl.curve("easy", { type = "spring", mass = 1, stiffness = 238.1191, dampening = 24.21279333 })

hl.animation({ leaf = "global", enabled = true, speed = 10, bezier = "default" })
hl.animation({ leaf = "border", enabled = true, speed = 5.39, bezier = "easeOutQuint" })
hl.animation({ leaf = "windows", enabled = true, speed = 4.79, spring = "easy" })
hl.animation({ leaf = "windowsIn", enabled = true, speed = 4.1, spring = "easy", style = "popin 87%" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 1.49, bezier = "linear", style = "popin 87%" })
hl.animation({ leaf = "fadeIn", enabled = true, speed = 1.73, bezier = "almostLinear" })
hl.animation({ leaf = "fadeOut", enabled = true, speed = 1.46, bezier = "almostLinear" })
hl.animation({ leaf = "fade", enabled = true, speed = 3.03, bezier = "quick" })
hl.animation({ leaf = "layers", enabled = true, speed = 3.81, bezier = "easeOutQuint" })
hl.animation({ leaf = "layersIn", enabled = true, speed = 4, bezier = "easeOutQuint", style = "fade" })
hl.animation({ leaf = "layersOut", enabled = true, speed = 1.5, bezier = "linear", style = "fade" })
hl.animation({ leaf = "fadeLayersIn", enabled = true, speed = 1.79, bezier = "almostLinear" })
hl.animation({ leaf = "fadeLayersOut", enabled = true, speed = 1.39, bezier = "almostLinear" })
hl.animation({ leaf = "workspaces", enabled = true, speed = 1.94, bezier = "almostLinear", style = "fade" })
hl.animation({ leaf = "workspacesIn", enabled = true, speed = 1.21, bezier = "almostLinear", style = "fade" })
hl.animation({ leaf = "workspacesOut", enabled = true, speed = 1.94, bezier = "almostLinear", style = "fade" })
hl.animation({ leaf = "zoomFactor", enabled = true, speed = 7, bezier = "quick" })

-- Ref https://wiki.hypr.land/Configuring/Basics/Workspace-Rules/
-- "Smart gaps" / "No gaps when only"
-- uncomment all if you wish to use that.
-- hl.workspace_rule({ workspace = "w[tv1]", gaps_out = 0, gaps_in = 0 })
-- hl.workspace_rule({ workspace = "f[1]",   gaps_out = 0, gaps_in = 0 })
-- hl.window_rule({
--     name  = "no-gaps-wtv1",
--     match = { float = false, workspace = "w[tv1]" },
--     border_size = 0,
--     rounding    = 0,
-- })
-- hl.window_rule({
--     name  = "no-gaps-f1",
--     match = { float = false, workspace = "f[1]" },
--     border_size = 0,
--     rounding    = 0,
-- })

-- See https://wiki.hypr.land/Configuring/Master-Layout/ for more

hl.config({
	master = {
		new_status = "master",
	},
})

----------------
----  MISC  ----
----------------
-- See https://wiki.hypr.land/Configuring/Layouts/Scrolling-Layout/ for more

hl.config({
	scrolling = {
		fullscreen_on_one_column = true,
	},
})

-- https://wiki.hypr.land/Configuring/Variables/-misc

hl.config({
	misc = {
		force_default_wallpaper = 0, -- Set to 0 or 1 to disable the anime mascot wallpapers
		disable_hyprland_logo = true, -- If true disables the random hyprland logo / anime girl background. :(
	},
})

--------------
---- INPUT ---
--------------

-- https://wiki.hypr.land/Configuring/Variables/-input

hl.config({
	input = {
		kb_layout = "br",
		follow_mouse = 1,
		sensitivity = 0.25, -- -1.0 - 1.0, 0 means no modification.
		touchpad = {
			natural_scroll = true,
		},
	},
})

-- See https://wiki.hypr.land/Configuring/Advanced-and-Cool/Gestures/

hl.gesture({
	fingers = 3,
	direction = "horizontal",
	action = "workspace",
})

-- Example per-device config

-- See https://wiki.hypr.land/Configuring/Keywords/-per-device-input-configs for more

hl.device({
	name = "epic-mouse-v1",
	sensitivity = -0.5,
})

-- hl.device({
--     name = "wacom-one-by-wacom-s-pen",
--     output = "eDP-1",
-- })

hl.device({
	name = "opentabletdriver-virtual-artist-tablet",
	output = "eDP-1",
})

--------------------
---- KEYBINDINGS ---
--------------------

-- See https://wiki.hypr.land/Configuring/Keywords/

local mainMod = "SUPER"

-- Sets "Windows" key as main modifier
-- Example binds, see https://wiki.hypr.land/Configuring/Binds/ for more

hl.bind(mainMod .. " + RETURN", hl.dsp.exec_cmd("kitty"))
hl.bind(mainMod .. " + B", hl.dsp.exec_cmd("firefox"))
hl.bind(mainMod .. " + E", hl.dsp.exec_cmd("dolphin"))
hl.bind(mainMod .. " + R", hl.dsp.exec_cmd("pkill rofi ||/home/thales/.config/rofi/scripts/launcher_t1"))
hl.bind(mainMod .. " + SHIFT" .. " + Q", hl.dsp.window.close())
hl.bind(
	mainMod .. "+ SHIFT" .. " + M",
	hl.dsp.exec_cmd("command -v hyprshutdown >/dev/null 2>&1 && hyprshutdown || hyprctl dispatch 'hl.dsp.exit()'")
)
hl.bind(mainMod .. " + V", hl.dsp.window.float())
hl.bind(mainMod .. " + P", hl.dsp.window.pseudo())
hl.bind(mainMod .. " + J", hl.dsp.layout("togglesplit")) -- dwindle only
hl.bind(mainMod .. " + F", hl.dsp.window.fullscreen({ action = "toggle", mode = "maximized" }))
hl.bind(mainMod .. " + SHIFT" .. " + F", hl.dsp.window.fullscreen({ action = "toggle", mode = "fullscreen" }))

-- Move focus with mainMod + arrow keys
hl.bind(mainMod .. " + " .. "left", hl.dsp.focus({ direction = "left" }))
hl.bind(mainMod .. " + " .. "right", hl.dsp.focus({ direction = "right" }))
hl.bind(mainMod .. " + " .. "up", hl.dsp.focus({ direction = "up" }))
hl.bind(mainMod .. " + " .. "down", hl.dsp.focus({ direction = "down" }))

-- Cliphist
hl.bind(mainMod .. " + " .. "C", hl.dsp.exec_cmd("pkill rofi ||/home/thales/.config/rofi/scripts/cliphist.sh"))

-- Screenshot a window
hl.bind(mainMod .. " + " .. "PRINT", hl.dsp.exec_cmd("hyprshot -z -m window -o ~/pictures/screenshots"))

-- Screenshot a monitor
hl.bind("PRINT", hl.dsp.exec_cmd("hyprshot -z -m output -o ~/pictures/screenshots"))

-- Screenshot a region
hl.bind(
	mainMod .. " + " .. "SHIFT" .. " + " .. "PRINT",
	hl.dsp.exec_cmd("hyprshot -z -m region -o ~/pictures/screenshots")
)

-- Lock the screen
hl.bind(mainMod .. " + " .. "l", hl.dsp.exec_cmd("hyprlock"))

-- Open wlogout
hl.bind(mainMod .. " + " .. "SHIFT" .. " + " .. "l", hl.dsp.exec_cmd("wlogout"))

-- Waybar reload
hl.bind(mainMod .. " + " .. "W", hl.dsp.exec_cmd("~/.config/waybar/scripts/launch.sh"))

local step = 30

-- Resize windows
local resizeUnit = 100
hl.bind(mainMod .. " + SHIFT + right", hl.dsp.window.resize({ x = resizeUnit, y = 0, relative = true }))
hl.bind(mainMod .. " + SHIFT + left", hl.dsp.window.resize({ x = -resizeUnit, y = 0, relative = true }))
hl.bind(mainMod .. " + SHIFT + up", hl.dsp.window.resize({ x = 0, y = -resizeUnit, relative = true }))
hl.bind(mainMod .. " + SHIFT + down", hl.dsp.window.resize({ x = 0, y = resizeUnit, relative = true }))

-- Move window
hl.bind(mainMod .. " + " .. "ALT" .. " + " .. "left", hl.dsp.window.swap({ direction = "l" }))
hl.bind(mainMod .. " + " .. "ALT" .. " + " .. "right", hl.dsp.window.swap({ direction = "r" }))
hl.bind(mainMod .. " + " .. "ALT" .. " + " .. "up", hl.dsp.window.swap({ direction = "u" }))
hl.bind(mainMod .. " + " .. "ALT" .. " + " .. "down", hl.dsp.window.swap({ direction = "d" }))

-- Switch workspaces with mainMod + [0-9]
-- Move active window to a workspace with mainMod + SHIFT + [0-9]
for i = 1, 10 do
	local key = i % 10 -- 10 maps to key 0
	hl.bind(mainMod .. " + " .. key, hl.dsp.focus({ workspace = i }))
	hl.bind(mainMod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = i }))
end

-- Example special workspace (scratchpad)
hl.bind(mainMod .. " + " .. "S", hl.dsp.workspace.toggle_special("magic"))
hl.bind(mainMod .. " + " .. "SHIFT" .. " + " .. "S", hl.dsp.window.move({ workspace = "special:magic" }))

-- Scroll through existing workspaces with mainMod + scroll
hl.bind(mainMod .. " + " .. "mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mainMod .. " + " .. "mouse_up", hl.dsp.focus({ workspace = "e-1" }))

-- Move/resize windows with mainMod + LMB/RMB and dragging
hl.bind(mainMod .. " + " .. "mouse:272", hl.dsp.window.drag(), { mouse = true })
hl.bind(mainMod .. " + " .. "mouse:273", hl.dsp.window.resize(), { mouse = true })

-- Laptop multimedia keys for volume and LCD brightness
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"), { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"), { locked = true, repeating = true })
hl.bind("XF86AudioMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"), { locked = true })
hl.bind("XF86AudioMicMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"), { locked = true })
hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd("~/.config/hypr/scripts/modo-energia.sh brilho up"), { locked = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("~/.config/hypr/scripts/modo-energia.sh brilho down"), { locked = true })

-- Requires playerctl
hl.bind("XF86AudioNext", hl.dsp.exec_cmd("playerctl next"), { locked = true })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPlay", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPrev", hl.dsp.exec_cmd("playerctl previous"), { locked = true })

--------------------------------
---- WINDOWS AND WORKSPACES ----
--------------------------------
hl.window_rule({
	match = {
		class = "Terraria.bin.x86_64",
	},
	float = true,
	center = true,
})
-- See https://wiki.hypr.land/Configuring/Basics/Window-Rules/
-- and https://wiki.hypr.land/Configuring/Basics/Workspace-Rules/

-- Example window rules that are useful

local suppressMaximizeRule = hl.window_rule({
	-- Ignore maximize requests from all apps. You'll probably like this.
	name = "suppress-maximize-events",
	match = { class = ".*" },

	suppress_event = "maximize",
})
-- suppressMaximizeRule:set_enabled(false)

-- Fix some dragging issues with XWayland
hl.window_rule({
	name = "fix-xwayland-drags",
	match = {
		class = "^$",
		title = "^$",
		xwayland = true,
		float = true,
		fullscreen = false,
		pin = false,
	},
	no_focus = true,
})

-- Layer rules also return a handle.
-- local overlayLayerRule = hl.layer_rule({
--     name  = "no-anim-overlay",
--     match = { namespace = "^my-overlay$" },
--     no_anim = true,
-- })
-- overlayLayerRule:set_enabled(false)

-- Hyprland-run windowrule

hl.window_rule({
	name = "move-hyprland-run",
	match = {
		class = "hyprland-run",
	},
	move = { 20, "monitor_h-120" },
	float = true,
})
