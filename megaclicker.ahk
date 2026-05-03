#SingleInstance Force
#Persistent
SetBatchLines, -1
CoordMode, Mouse, Screen

; =========================
; SETTINGS
; =========================

toggleKey := "F6"
baseDelay := 500
randomAmount := 150

enableJitter := true
jitterRadius := 1

showClickMarker := true
markerSize := 24
markerDuration := 60000 ; 60 seconds

clicking := false
anchorX := 0
anchorY := 0

markerCounter := 0
clickMarkers := {}

; =========================
; MAIN GUI
; =========================

Gui, Main:Font, s10, Segoe UI

Gui, Main:Add, Text,, Toggle Hotkey:
Gui, Main:Add, Edit, vGuiToggleKey w130, %toggleKey%

Gui, Main:Add, Text,, Base Delay in ms:
Gui, Main:Add, Edit, vGuiBaseDelay w130, %baseDelay%

Gui, Main:Add, Text,, Random Variation +/- ms:
Gui, Main:Add, Edit, vGuiRandomAmount w130, %randomAmount%

Gui, Main:Add, Checkbox, vGuiEnableJitter Checked, Enable small mouse jitter

Gui, Main:Add, Text,, Jitter Radius in pixels:
Gui, Main:Add, Edit, vGuiJitterRadius w130, %jitterRadius%

Gui, Main:Add, Checkbox, vGuiShowClickMarker Checked, Show marker where it clicked

Gui, Main:Add, Text,, Click Marker Size:
Gui, Main:Add, Edit, vGuiMarkerSize w130, %markerSize%

Gui, Main:Add, Text,, Marker Duration in ms:
Gui, Main:Add, Edit, vGuiMarkerDuration w130, %markerDuration%

Gui, Main:Add, Button, gApplySettings w160, Apply Settings
Gui, Main:Add, Button, gToggleClicking w160, Toggle Clicking
Gui, Main:Add, Button, gClearMarkers w160, Clear Markers

Gui, Main:Add, Text, vStatusText w380 cRed, Status: OFF
Gui, Main:Add, Text,, 60000 ms = 60 seconds. Each marker stays independently.
Gui, Main:Add, Text,, Markers are forced click-through after being drawn.

Gui, Main:Show,, MegaClicker

Hotkey, %toggleKey%, ToggleClicking

return

; =========================
; APPLY SETTINGS
; =========================

ApplySettings:
Gui, Main:Submit, NoHide

Hotkey, %toggleKey%, ToggleClicking, Off

toggleKey := GuiToggleKey
baseDelay := GuiBaseDelay
randomAmount := GuiRandomAmount
enableJitter := GuiEnableJitter
jitterRadius := GuiJitterRadius
showClickMarker := GuiShowClickMarker
markerSize := GuiMarkerSize
markerDuration := GuiMarkerDuration

if (baseDelay < 1)
    baseDelay := 1

if (randomAmount < 0)
    randomAmount := 0

if (jitterRadius < 0)
    jitterRadius := 0

if (markerSize < 8)
    markerSize := 8

if (markerDuration < 1000)
    markerDuration := 1000

Hotkey, %toggleKey%, ToggleClicking, On

MsgBox, 64, Settings Applied, Settings updated!`n`nToggle Key: %toggleKey%`nBase Delay: %baseDelay% ms`nRandom Variation: +/- %randomAmount% ms`nJitter Enabled: %enableJitter%`nJitter Radius: %jitterRadius% px`nShow Click Marker: %showClickMarker%`nMarker Size: %markerSize%`nMarker Duration: %markerDuration% ms

return

; =========================
; TOGGLE CLICKING
; =========================

ToggleClicking:
clicking := !clicking

if (clicking) {
    MouseGetPos, anchorX, anchorY

    GuiControl, Main:, StatusText, Status: ON
    GuiControl, Main:+cGreen, StatusText

    SetTimer, AutoClickLoop, -1
    SetTimer, CleanupClickMarkers, 1000
} else {
    GuiControl, Main:, StatusText, Status: OFF
    GuiControl, Main:+cRed, StatusText

    MouseMove, %anchorX%, %anchorY%, 0
}

return

; =========================
; AUTO CLICK LOOP
; =========================

AutoClickLoop:
while (clicking) {
    clickX := anchorX
    clickY := anchorY

    if (enableJitter && jitterRadius > 0) {
        Random, offsetX, -%jitterRadius%, %jitterRadius%
        Random, offsetY, -%jitterRadius%, %jitterRadius%

        clickX := anchorX + offsetX
        clickY := anchorY + offsetY

        MouseMove, %clickX%, %clickY%, 0
    } else {
        MouseGetPos, clickX, clickY
    }

    Click

    if (showClickMarker) {
        ShowClickMarker(clickX, clickY)
    }

    minDelay := baseDelay - randomAmount
    maxDelay := baseDelay + randomAmount

    if (minDelay < 1)
        minDelay := 1

    Random, sleepTime, %minDelay%, %maxDelay%
    Sleep, %sleepTime%
}

return

; =========================
; CLICK MARKER OVERLAY
; =========================

ShowClickMarker(x, y) {
    global markerSize, markerDuration, markerCounter, clickMarkers

    markerCounter++

    guiName := "ClickMarker" . markerCounter

    half := Floor(markerSize / 2)
    drawX := x - half
    drawY := y - half
    center := Floor(markerSize / 2)

    ; +E0x20    = click-through
    ; +E0x80000 = layered window, helps transparency
    Gui, %guiName%:New, +AlwaysOnTop -Caption +ToolWindow +E0x20 +E0x80000 +HwndmarkerHwnd
    Gui, %guiName%:Color, Lime

    ; Crosshair
    Gui, %guiName%:Add, Text, x%center% y0 w2 h%markerSize% BackgroundBlack
    Gui, %guiName%:Add, Text, x0 y%center% w%markerSize% h2 BackgroundBlack

    ; Border
    Gui, %guiName%:Add, Text, x0 y0 w%markerSize% h2 BackgroundLime
    Gui, %guiName%:Add, Text, x0 y%markerSize% w%markerSize% h2 BackgroundLime
    Gui, %guiName%:Add, Text, x0 y0 w2 h%markerSize% BackgroundLime
    Gui, %guiName%:Add, Text, x%markerSize% y0 w2 h%markerSize% BackgroundLime

    Gui, %guiName%:Show, x%drawX% y%drawY% w%markerSize% h%markerSize% NoActivate

    ; Force click-through AFTER the window exists.
    WinSet, ExStyle, +0x20, ahk_id %markerHwnd%

    ; Force layered/transparency AFTER the window exists.
    WinSet, ExStyle, +0x80000, ahk_id %markerHwnd%
    WinSet, Transparent, 180, ahk_id %markerHwnd%

    ; Store this marker's expiration time.
    clickMarkers[guiName] := A_TickCount + markerDuration
}

; =========================
; MARKER CLEANUP
; =========================

CleanupClickMarkers:
now := A_TickCount

for guiName, expireTime in clickMarkers {
    if (now >= expireTime) {
        Gui, %guiName%:Destroy
        clickMarkers.Delete(guiName)
    }
}

if (!clicking && clickMarkers.Count() = 0) {
    SetTimer, CleanupClickMarkers, Off
}

return

ClearMarkers:
DestroyAllClickMarkers()
return

DestroyAllClickMarkers() {
    global clickMarkers

    for guiName, expireTime in clickMarkers {
        Gui, %guiName%:Destroy
    }

    clickMarkers := {}
}

; =========================
; EXIT CLEANLY
; =========================

MainGuiClose:
GuiClose:
DestroyAllClickMarkers()
ExitApp