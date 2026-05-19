//go:build windows

package main

import (
	"syscall"
	"unsafe"
)

func showError(text string) {
	user32 := syscall.NewLazyDLL("user32.dll")
	messageBoxW := user32.NewProc("MessageBoxW")

	title, _ := syscall.UTF16PtrFromString("mpv_r")
	message, _ := syscall.UTF16PtrFromString(text)

	const (
		mbOK       = 0x00000000
		mbIconStop = 0x00000010
		mbSetFocus = 0x00010000
		mbTopMost  = 0x00040000
	)

	_, _, _ = messageBoxW.Call(
		0,
		uintptr(unsafe.Pointer(message)),
		uintptr(unsafe.Pointer(title)),
		uintptr(mbOK|mbIconStop|mbSetFocus|mbTopMost),
	)
}
