package main

import (
	"fmt"
	"syscall"
	"time"
	"unsafe"

	"github.com/lxn/win"
)

var (
	className = syscall.StringToUTF16Ptr("FloatingClockWin")
	font      win.HFONT
)

func wndProc(hwnd win.HWND, msg uint32, wParam, lParam uintptr) uintptr {
	switch msg {
	case win.WM_CREATE:
		font = win.CreateFont(
			80, 0, 0, 0, win.FW_BOLD, 0, 0, 0,
			win.DEFAULT_CHARSET, win.OUT_OUTLINE_PRECIS,
			win.CLIP_DEFAULT_PRECIS, win.CLEARTYPE_QUALITY,
			win.DEFAULT_PITCH, syscall.StringToUTF16Ptr("Segoe UI"),
		)
		win.SetTimer(hwnd, 1, 1000, 0)
	case win.WM_TIMER:
		win.InvalidateRect(hwnd, nil, false)
	case win.WM_PAINT:
		var ps win.PAINTSTRUCT
		hdc := win.BeginPaint(hwnd, &ps)
		var rect win.RECT
		win.GetClientRect(hwnd, &rect)

		// Create memory DC
		memDC := win.CreateCompatibleDC(hdc)
		memBitmap := win.CreateCompatibleBitmap(hdc, rect.Right-rect.Left, rect.Bottom-rect.Top)
		oldBitmap := win.SelectObject(memDC, win.HGDIOBJ(memBitmap))

		// Fill background with black (color key)
		brush := win.CreateSolidBrush(0x000000)
		win.FillRect(memDC, &rect, brush)
		win.DeleteObject(win.HGDIOBJ(brush))

		t := time.Now()
		dateStr := t.Format("2006年1月2日")
		timeStr := t.Format("15:04:05")

		win.SetBkMode(memDC, win.TRANSPARENT)
		oldFont := win.SelectObject(memDC, win.HGDIOBJ(font))

		// Draw Cyan Color (0xFFFF00) Since BGR format: R=00(00), G=FF(255), B=FF(255) -> 0xFFFF00
		win.SetTextColor(memDC, 0xFFFF00)
		
		var rectDate win.RECT
		rectDate.Left, rectDate.Top, rectDate.Right, rectDate.Bottom = 0, 0, rect.Right, rect.Bottom/3
		dateUTF16 := syscall.StringToUTF16(dateStr)
		
        // Use standard DrawText by linking gdi32 manually if DrawText lacks in w32.
        // Actually DrawText is in win!
		win.DrawText(memDC, &dateUTF16[0], -1, &rectDate, win.DT_CENTER|win.DT_VCENTER|win.DT_SINGLELINE)

		var rectTime win.RECT
		rectTime.Left, rectTime.Top, rectTime.Right, rectTime.Bottom = 0, rect.Bottom/3, rect.Right, rect.Bottom
		timeUTF16 := syscall.StringToUTF16(timeStr)
		win.DrawText(memDC, &timeUTF16[0], -1, &rectTime, win.DT_CENTER|win.DT_VCENTER|win.DT_SINGLELINE)

		win.SelectObject(memDC, oldFont)

		// Copy to window
		win.BitBlt(hdc, 0, 0, rect.Right-rect.Left, rect.Bottom-rect.Top, memDC, 0, 0, win.SRCCOPY)

		win.SelectObject(memDC, oldBitmap)
		win.DeleteObject(win.HGDIOBJ(memBitmap))
		win.DeleteDC(memDC)

		win.EndPaint(hwnd, &ps)
		return 0

	case win.WM_NCHITTEST:
		// Make the whole window draggable
		res := win.DefWindowProc(hwnd, msg, wParam, lParam)
		if res == win.HTCLIENT {
			return win.HTCAPTION
		}
		return res

    case win.WM_RBUTTONUP:
        // Right click to close
        win.DestroyWindow(hwnd)

	case win.WM_DESTROY:
		win.KillTimer(hwnd, 1)
		win.DeleteObject(win.HGDIOBJ(font))
		win.PostQuitMessage(0)
	}
	return win.DefWindowProc(hwnd, msg, wParam, lParam)
}

func main() {
	inst := win.GetModuleHandle(nil)

	var wc win.WNDCLASSEX
	wc.CbSize = uint32(unsafe.Sizeof(wc))
	wc.LpfnWndProc = syscall.NewCallback(wndProc)
	wc.HInstance = inst
	wc.HIcon = win.LoadIcon(0, (*uint16)(unsafe.Pointer(uintptr(win.IDI_APPLICATION))))
	wc.HCursor = win.LoadCursor(0, (*uint16)(unsafe.Pointer(uintptr(win.IDC_ARROW))))
	wc.HbrBackground = win.HBRUSH(win.GetStockObject(win.BLACK_BRUSH))
	wc.LpszClassName = className

	if win.RegisterClassEx(&wc) == 0 {
		fmt.Println("RegisterClassEx failed")
		return
	}

	hwnd := win.CreateWindowEx(
		win.WS_EX_LAYERED|win.WS_EX_TOPMOST|win.WS_EX_TOOLWINDOW,
		className,
		syscall.StringToUTF16Ptr("FloatingClock"),
		win.WS_POPUP,
		100, 100, 400, 200,
		0, 0, inst, nil,
	)

	if hwnd == 0 {
		fmt.Println("CreateWindowEx failed")
		return
	}

	// Layered attributes: Key is black (0x000000), Alpha is 200
	win.SetLayeredWindowAttributes(hwnd, 0x000000, 0, win.LWA_COLORKEY)

	win.ShowWindow(hwnd, win.SW_SHOW)
	win.UpdateWindow(hwnd)

	var msg win.MSG
	for win.GetMessage(&msg, 0, 0, 0) > 0 {
		win.TranslateMessage(&msg)
		win.DispatchMessage(&msg)
	}
}
