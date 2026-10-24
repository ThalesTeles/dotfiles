---@module 'hl'

-- Modo estendido: workspaces 1-5 na tela principal (eDP-1) e 6-10 na secundária (HDMI-A-1).
-- No modo espelhado o HDMI-A-1 não recebe workspaces, então todos ficam no eDP-1.

for ws = 1, 5 do
	hl.workspace_rule({ workspace = tostring(ws), monitor = "eDP-1", default = ws == 1 })
end

for ws = 6, 10 do
	hl.workspace_rule({ workspace = tostring(ws), monitor = "HDMI-A-1", default = ws == 6 })
end
