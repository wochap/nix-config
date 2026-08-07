package main

import (
	"bufio"
	"encoding/json"
	"net"
	"os"
	"syscall"
)

func execFallback() {
	if len(os.Args) > 1 {
		fallbackCmd := os.Args[1]
		syscall.Exec("/bin/sh", []string{"sh", "-c", fallbackCmd}, os.Environ())
	}
	os.Exit(1)
}

func main() {
	if _, err := os.Stat("/run/greetd_autologin_done"); err == nil {
		execFallback()
		return
	}

	os.WriteFile("/run/greetd_autologin_done", []byte("done"), 0644)

	sockPath := os.Getenv("GREETD_SOCK")
	if sockPath == "" {
		execFallback()
		return
	}

	conn, err := net.Dial("unix", sockPath)
	if err != nil {
		execFallback()
		return
	}
	defer conn.Close()

	if len(os.Args) < 3 {
		execFallback()
		return
	}

	username := os.Args[2]
	cmdArgs := os.Args[3:]

	logFile, _ := os.OpenFile("/tmp/greetd_autologin.log", os.O_CREATE|os.O_WRONLY|os.O_APPEND, 0666)
	defer logFile.Close()
	log := func(msg string) {
		logFile.WriteString(msg + "\n")
	}

	reader := bufio.NewReader(conn)
	sendMsg := func(msg map[string]interface{}) map[string]interface{} {
		b, _ := json.Marshal(msg)
		log("Sending: " + string(b))
		conn.Write(append(b, '\n'))

		line, _ := reader.ReadString('\n')
		log("Received: " + line)
		if line == "" {
			return nil
		}
		var resp map[string]interface{}
		json.Unmarshal([]byte(line), &resp)
		return resp
	}

	resp := sendMsg(map[string]interface{}{"type": "create_session", "username": username})
	for resp != nil && resp["type"] == "auth_message" {
		resp = sendMsg(map[string]interface{}{"type": "post_auth_message_response", "response": ""})
	}

	if resp != nil && resp["type"] == "success" {
		sendMsg(map[string]interface{}{"type": "start_session", "cmd": cmdArgs})
		// Block forever
		select {}
	} else {
		execFallback()
	}
}
