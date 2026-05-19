//go:build !windows

package main

import (
	"fmt"
	"os"
)

func showError(text string) {
	_, _ = fmt.Fprintln(os.Stderr, text)
}
