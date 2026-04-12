#Requires AutoHotkey >= v2.0
#SingleInstance Force
SetWorkingDir(A_ScriptDir)
Persistent()

; Read the settings
x := IniRead('overlay_settings.ini', 'Gui', 'x')
y := IniRead('overlay_settings.ini', 'Gui', 'y')
scale := IniRead('overlay_settings.ini', 'Gui', 'scale')
transparency := IniRead('overlay_settings.ini', 'Gui', 'transparency')
color := IniRead('overlay_settings.ini', 'Gui', 'color')
font_size := Floor((35 * scale - 10) * 0.6)

; Set the tray
Tray := A_TrayMenu
Tray.Delete()
Tray.Add('PUBG RC Overlay - Exit', (*) => ExitApp())
Tray.Default := 'PUBG RC Overlay - Exit'

; Build the GUI
Overlay := Gui('+AlwaysOnTop -Caption +ToolWindow +E0x20 +E0x80000')
Overlay.BackColor := color
WinSetTransparent(transparency, Overlay.Hwnd)

Overlay.SetFont('c00DD00 bold s' . font_size)
state := Overlay.AddText('x5 y5 w' . scale * 50 . ' h' . scale * 25 . ' 0x200')

Overlay.SetFont('cFFFFFF norm s' . font_size - 1)
weapon := Overlay.AddText('x+5 yp w' . scale * 150 . ' h' . scale * 25 . ' 0x200')

Overlay.Show('x' . x . ' y' . y . ' w' . scale * 200 + 15 . ' h' . scale * 25 + 10)

while true {
	raw := FileRead('ghub_last_msg.txt')
	list := StrSplit(raw, '|')

	if list.Get(1) == 'omt' {
		is_on := list.Get(2) == '1'
		state.Opt('c' . (is_on ? '00DD00' : 'DD0000'))
		state.Value := is_on ? 'ON' : 'OFF'
	}

	if list.Get(1) == 'oms' {
		dmr_suffix := list.Get(3) == '1' ? ' [DMR]' : ''
		weapon.Value := list.Get(2) . dmr_suffix
	}

	Sleep(100)
}