package main

import (
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
)

func main() {
	exePath, err := os.Executable()
	if err != nil {
		fail("could not locate launcher", err)
	}

	root := filepath.Dir(exePath)
	mpvPath := filepath.Join(root, "mpv", "mpv.exe")
	configDir := filepath.Join(root, "portable_config")

	if _, err := os.Stat(mpvPath); err != nil {
		fail(fmt.Sprintf("mpv executable not found: %s", mpvPath), err)
	}

	args := []string{"--config-dir=" + configDir}
	args = append(args, os.Args[1:]...)

	cmd := exec.Command(mpvPath, args...)
	cmd.Stdout = nil
	cmd.Stderr = nil
	cmd.Stdin = nil

	if err := cmd.Start(); err != nil {
		fail("could not start mpv", err)
	}
}

func fail(message string, err error) {
	text := message
	if err != nil {
		text = fmt.Sprintf("%s\n\n%s", message, err)
	}

	showError(text)
	os.Exit(1)
}
