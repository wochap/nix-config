package main

import (
	"encoding/binary"
	"encoding/json"
	"io"
	"net"
	"os"
	"syscall"
)

const autologinMarker = "/run/greetd-autologin/autologin_done"

func execFallback() {
	if len(os.Args) > 1 {
		fallbackCmd := os.Args[1]
		syscall.Exec("/bin/sh", []string{"sh", "-c", fallbackCmd}, os.Environ())
	}
	os.Exit(1)
}

func main() {
	if _, err := os.Stat(autologinMarker); err == nil {
		execFallback()
		return
	} else if !os.IsNotExist(err) {
		execFallback()
		return
	}

	// Without a marker, a failed desktop would cause repeated autologins.
	if err := os.WriteFile(autologinMarker, []byte("done"), 0600); err != nil {
		execFallback()
		return
	}

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

	sendMsg := func(msg map[string]interface{}) map[string]interface{} {
		b, _ := json.Marshal(msg)
		log("Sending: " + string(b))

		length := uint32(len(b))
		lenBuf := make([]byte, 4)
		binary.LittleEndian.PutUint32(lenBuf, length)
		conn.Write(lenBuf)
		conn.Write(b)

		readLenBuf := make([]byte, 4)
		if _, err := io.ReadFull(conn, readLenBuf); err != nil {
			return nil
		}

		readLen := binary.LittleEndian.Uint32(readLenBuf)
		readBuf := make([]byte, readLen)
		if _, err := io.ReadFull(conn, readBuf); err != nil {
			return nil
		}

		log("Received: " + string(readBuf))
		var resp map[string]interface{}
		json.Unmarshal(readBuf, &resp)
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
