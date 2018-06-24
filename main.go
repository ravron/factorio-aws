package main

import (
	"fmt"
	"io/ioutil"

	"github.com/gtaylor/factorio-rcon"
)

func getPassword(filename string) string {
	b, err := ioutil.ReadFile(filename)
	if err != nil {
		panic(err)
	}
	return string(b)
}

func main() {
	r, err := rcon.Dial("127.0.0.1:27015")
	if err != nil {
		panic(err)
	}
	defer r.Close()

	err = r.Authenticate(getPassword("/factorio/config/rconpw"))
	if err != nil {
		panic(err)
	}

	players, err := r.CmdPlayers()
	if err != nil {
		panic(err)
	}

	online := 0
	for _, p := range players {
		if p.Online {
			online += 1
		}
	}

	fmt.Printf("%d\n", online)
}
