package main

import (
	"bufio"
	"fmt"
	"os"
	"path/filepath"
	"strings"
	"syscall"
)

func main() {
	isSilent := false
	var session string

	for i := 1; i < len(os.Args); i++ {
		arg := os.Args[i]
		if arg == "--silent" || arg == "-s" {
			isSilent = true
		} else {
			session = arg
		}
	}

	if session == "" {
		fmt.Fprintf(os.Stderr, "Usage: %s [--silent|-s] <session>\n", os.Args[0])
		os.Exit(1)
	}

	if !isSilent {
		fmt.Printf("Session: %s\n", session)
	}

	sessionDirs := []string{
		"/run/current-system/sw/share/wayland-sessions",
		"/run/current-system/sw/share/xsessions",
		os.Getenv("WAYLAND_SESSIONS_PATH"),
	}

	for _, dir := range sessionDirs {
		if dir == "" {
			continue
		}

		path := filepath.Join(dir, session+".desktop")
		file, err := os.Open(path)
		if err != nil {
			continue
		}
		defer file.Close()

		if !isSilent {
			fmt.Printf("Found %s\n", path)
		}

		scanner := bufio.NewScanner(file)
		inDesktopEntry := false
		var execCmd string

		for scanner.Scan() {
			line := strings.TrimSpace(scanner.Text())
			if line == "[Desktop Entry]" {
				inDesktopEntry = true
			} else if strings.HasPrefix(line, "[") {
				inDesktopEntry = false
			} else if inDesktopEntry && strings.HasPrefix(line, "Exec=") {
				execCmd = strings.TrimPrefix(line, "Exec=")
				break
			}
		}

		if execCmd != "" {
			if !isSilent {
				fmt.Printf("Exec: %s\n", execCmd)
			} else {
				nullFile, _ := os.OpenFile("/dev/null", os.O_WRONLY, 0666)
				syscall.Dup2(int(nullFile.Fd()), 1)
				syscall.Dup2(int(nullFile.Fd()), 2)
			}
			syscall.Exec("/bin/sh", []string{"sh", "-c", execCmd}, os.Environ())
			fmt.Fprintf(os.Stderr, "Failed to execute '%s'\n", execCmd)
			os.Exit(1)
		} else {
			if !isSilent {
				fmt.Fprintf(os.Stderr, "Could not find 'Exec' entry in '%s'.\n", path)
			}
		}
	}

	if !isSilent {
		fmt.Fprintf(os.Stderr, "Error: Could not find a desktop entry for session '%s'.\n", session)
	}
	os.Exit(1)
}
