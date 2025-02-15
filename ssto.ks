@lazyGlobal off.
runOncePath("0:libraries/read_line").

function sstoOrbit {
    clearScreen.

    local head to 90.
    local targetPitch to 0.
    LOCK steering TO HEADING(head, ship:facing:pitch, 0).

    local throt to 1.
    lock throttle to throt.
    local lastChangeTime to time:seconds.
    function targetSpeed {
        if altitude < 1000 {
            return 400.
        }
        if altitude > 20000 {
            return 5000.
        }
        return 400 + (altitude - 1000) / 19000 * 1600.
    }

    function hud {
        print "Pitch: " + targetPitch + "         " at (0, 0).
        print "Max TWR: " + round(ship:availablethrust / (ship:mass * constant:g0), 2) + "         " at (0, 1).
        print "TWR: " + round(ship:thrust / (ship:mass * constant:g0), 2) + "         " at (0, 2).
        print "Throttle: " + round(throt, 2) + "         " at (0, 3).
        print "Target speed: " + targetSpeed() + "         " at (0, 4).
    }

    function loop {
        hud().

        if time:seconds > lastChangeTime + 1 {
            if airspeed > targetSpeed() {
                set throt to throt - 0.01.
            } else {
                set throt to throt + 0.01.
            }
            set throt to max(0, min(1, throt)).
            set lastChangeTime to time:seconds.
        }
    }

    until airspeed > 100 {
        loop().
    }
    // set pitch to 8.
    set targetPitch to 14.

    LOCK steering TO HEADING(head, targetPitch, 0).
    until altitude > 78 {
        loop().
    }
    gear off.
    set targetPitch to 20.

    until apoapsis > 70000 {
        loop().
    }
    lock throttle to 0.

    until altitude > 70000 {
        loop().
    }
    unlock all.
}

