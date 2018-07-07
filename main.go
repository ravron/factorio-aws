package main

import (
	"fmt"
	"io/ioutil"
    "os"
    "os/exec"
    "time"

	"github.com/gtaylor/factorio-rcon"
)

func getPassword(filename string) string {
	b, err := ioutil.ReadFile(filename)
	if err != nil {
		panic(err)
	}
	return string(b)
}

const filename = "/factorio/_last-check"

func lastZeroDate() time.Time {
	b, err := ioutil.ReadFile(filename)
	if os.IsNotExist(err) {
		// Return zero time, January 1 year 1
		return time.Time{}
	} else if err != nil {
		panic(err)
	}

	t := time.Time{}
	err = t.UnmarshalText(b)
	if err != nil {
		panic(err)
	}
	return t
}

func writeNow() {
	t, err := time.Now().UTC().MarshalText()
	if err != nil {
		panic(err)
	}

	if err = ioutil.WriteFile(filename, t, 0777); err != nil {
		panic(err)
	}
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

	fmt.Printf("%d players online\n", online)

    // If there are any players, delete file and exit.
    if online > 0 {
        // Ignore errors
        os.Remove(filename)
        return
    }

	last := lastZeroDate()
	thirtyFiveMinAgo := time.Now().UTC().Add(-35 * time.Minute)

	if last.Before(thirtyFiveMinAgo) {
		// Last check was longer than thirty five minutes ago. Write now to
		// file and exit.
		writeNow()
		return
	}

	// Last check was less than thirty five minutes ago. Shutdown in one
	// minute!
	c := exec.Command("shutdown", "-H", "+1")
	c.Run()
}
