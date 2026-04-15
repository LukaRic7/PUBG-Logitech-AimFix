#Requires AutoHotkey >= v2.0
#SingleInstance Force
SetWorkingDir(A_ScriptDir)
Persistent()

; Read the settings
x := IniRead('overlay_settings.ini', 'Gui', 'x')
y := IniRead('overlay_settings.ini', 'Gui', 'y')
scale := IniRead('overlay_settings.ini', 'Gui', 'scale')
width := IniRead('overlay_settings.ini', 'Gui', 'width') * scale
transparency := IniRead('overlay_settings.ini', 'Gui', 'transparency')
color := IniRead('overlay_settings.ini', 'Gui', 'color')
font_size := Floor((35 * scale - 10) * 0.55)

; Set the tray
Tray := A_TrayMenu
Tray.Delete()
Tray.Add('PUBG RC Overlay - Exit', (*) => ExitApp())
Tray.Default := 'PUBG RC Overlay - Exit'

; GUI
Overlay := Gui('+AlwaysOnTop -Caption +ToolWindow +E0x20 +E0x80000')

Overlay.BackColor := color
WinSetTransparent(transparency, Overlay.Hwnd)

Overlay.SetFont('cDDDD00 s' font_size ' Bold', 'Segoe UI Semibold')
state := Overlay.AddText('x10 y5 Center 0x200 w' (scale * 60) ' h' (scale * 30), "???")

Overlay.SetFont('cE6E6E6 s' (font_size - 1), 'Segoe UI')
weapon := Overlay.AddText('x+10 yp 0x200 w' width ' h' (scale * 30), 'WEAPON')

border1 := Overlay.AddText('x0 y0 w' ((scale * 60) + width + 30) ' h1 BackgroundFFFF00')
border2 := Overlay.AddText('x0 y' (scale * 30) + 9 ' w' ((scale * 60) + width + 30) ' h1 BackgroundFFFF00')
border3 := Overlay.AddText('x0 y0 w1 h' (scale * 30) + 10 ' BackgroundFFFF00')
border4 := Overlay.AddText('x' ((scale * 60) + width + 29) ' y0 w1 h' (scale * 30) + 10 ' BackgroundFFFF00')

Overlay.Show('x' x ' y' y ' w' ((scale * 60) + width + 30) ' h' (scale * 30) + 10)

; Mainloop
while true {
	raw := FileRead('ghub_last_msg.txt')
	if (raw) {
		list := StrSplit(raw, '|')

		if list.Get(1) == 'omt' {
			is_on := list.Get(2) == '1'
			is_on_label := is_on ? 'ON' : 'OFF'

			if (state.Value != is_on_label) {
				c := is_on ? '00DD00' : 'DD0000'

				state.Opt('c' . c)
				state.Value := is_on_label

				ToolTip(c)

				border1.Opt('Background' c)
				border2.Opt('Background' c)
				border3.Opt('Background' c)
				border4.Opt('Background' c)
				border1.Redraw()
				border2.Redraw()
				border3.Redraw()
				border4.Redraw()
			}
		}

		if list.Get(1) == 'oms' {
			dmr_suffix := list.Get(3) == '1' ? ' [DMR]' : ''
			weapon_name := list.Get(2) . dmr_suffix

			if (weapon.Value != weapon_name) {
				weapon.Value := weapon_name
			}
		}

		Sleep(100)
	}
}