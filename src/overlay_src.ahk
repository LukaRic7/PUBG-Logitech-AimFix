#Requires AutoHotkey >= v2.0
#SingleInstance Force
SetWorkingDir(A_ScriptDir)
Persistent()

VERSION := '1.4'

; === Read INI Settings ===
screenIdx  := IniRead('overlay_settings.ini', 'Position', 'screenIdx')
xPosPx     := IniRead('overlay_settings.ini', 'Position', 'xPosPx')
yPosPx     := IniRead('overlay_settings.ini', 'Position', 'yPosPx')
widthPx    := IniRead('overlay_settings.ini', 'Size', 'widthPx')
scale      := IniRead('overlay_settings.ini', 'Size', 'scale')
opacityPct := IniRead('overlay_settings.ini', 'Customization', 'opacityPct')
colorHex   := IniRead('overlay_settings.ini', 'Customization', 'colorHex')

; === Setup Tray ===
Tray := A_TrayMenu
Tray.Delete()
Tray.Add('Reload', (*) => Reload())
Tray.Add()
Tray.Add('Exit - PUBG RC Overlay v' VERSION, (*) => ExitApp())
Tray.Default := 'Exit - PUBG RC Overlay v' VERSION

; Calculate the font size from the scale
fontSize := Floor((35 * scale - 10) * 0.55)

; === Setup Overlay ===
Overlay := Gui('+AlwaysOnTop -Caption +ToolWindow +E0x20 +E0x80000')

Overlay.BackColor := colorHex
WinSetTransparent(Round(opacityPct / 100 * 255), Overlay.Hwnd)

; Initial Weapon State
Overlay.SetFont('cDDDD00 s' fontSize ' Bold', 'Segoe UI Semibold')
state := Overlay.AddText('x10 y5 Center 0x200 w' (scale * 60) ' h' (scale * 30), "???")

; Initial Weapon
Overlay.SetFont('cE6E6E6 s' (fontSize - 1), 'Segoe UI')
weapon := Overlay.AddText('x+10 yp 0x200 w' widthPx ' h' (scale * 20), 'WEAPON')

; Initial Hotbar
Overlay.SetFont('cE6E6E6 s' ((fontSize - 1) / 2), 'Segoe UI')
hotbar := Overlay.AddText('xp y+2 0x200 w' widthPx ' h' (scale * 10 - 2), 'HOTBAR')

; Overlay Borders
border1 := Overlay.AddText('x0 y0 w' ((scale * 60) + widthPx + 30) ' h1 BackgroundFFFF00')
border2 := Overlay.AddText('x0 y' (scale * 30) + 9 ' w' ((scale * 60) + widthPx + 30) ' h1 BackgroundFFFF00')
border3 := Overlay.AddText('x0 y0 w1 h' (scale * 30) + 10 ' BackgroundFFFF00')
border4 := Overlay.AddText('x' ((scale * 60) + widthPx + 29) ' y0 w1 h' (scale * 30) + 10 ' BackgroundFFFF00')
borders := [border1, border2, border3, border4]

Overlay.Show('x' xPosPx ' y' yPosPx ' w' ((scale * 60) + widthPx + 30) ' h' (scale * 30) + 10)

/**
 * Set the state label and border colors.
 * @param newState boolean. If the RC is hot.
 */
SetState(newState) {
	label := newState ? 'ON' : 'OFF'

	if (state.Value != label) {
		color := newState ? '00DD00' : 'DD0000'

		state.Opt('c' color)
		state.Value := label

		for border in borders {
			border.Opt('Background' color)
			border.Redraw()
		}
	}
}

; === Mainloop ===
while true {
	; Make sure the file exists
	if (!FileExist('ghub_last_msg.txt')) {
		Sleep(100)
		continue
	}

	; Attempt to read the file
	rawMessage := FileRead('ghub_last_msg.txt')
	if (!rawMessage || rawMessage == 'NO_CONSOLE_FOUND' || rawMessage == 'undefined') {
		Sleep(100)
		continue
	}

	; Parse the file
	messageSegments := StrSplit(rawMessage, '|')
	header := messageSegments.Get(1)

	; Update the overlay
	if (header == 'omt') {
		weaponState := messageSegments.Get(2) == '1'
		SetState(weaponState)
	} else if (header == 'oms') {
		dmrSuffix := messageSegments.Get(3) == '1' ? ' [DMR]' : ''
		weaponName := messageSegments.Get(2) . dmrSuffix
		hotbarName := messageSegments.Get(4)

		if (weapon.Value != weaponName) {
			weapon.Value := weaponName
		}

		if (hotbar.Value != hotbarName) {
			hotbar.Value := hotbarName
		}
	}
}