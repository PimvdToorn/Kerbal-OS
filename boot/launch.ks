set targetOrbit to 100000.
set altitude45deg to 10000.
set fairingAlt to 45000.

print "waiting for ship to fully load".
wait until ship:unpacked.
CLEARSCREEN.
SAS off.

print "Press any key to launch".
terminal:input:getchar().
CLEARSCREEN.


PRINT "Counting down:".
FROM {local countdown is 5.} UNTIL countdown = 0 STEP {SET countdown to countdown - 1.} DO {
    PRINT "..." + countdown.
    WAIT 1.
}

CLEARSCREEN.



WHEN MAXTHRUST = 0 THEN {
    PRINT "Staging".
    STAGE.
    PRESERVE.
}.

WHEN altitude > fairingAlt THEN {
    local fairings is ship:partstagged("fairing").

    for fairing in fairings {
        fairing:getmodule("moduleproceduralfairing"):doevent("deploy").
    }
}

function sqrtArc {
    parameter alt45deg.

    local derivative is (altitude / alt45deg).
    
    return arcTan2(1, derivative).
}


SET throt to 1.0.
LOCK THROTTLE TO throt.

set gravityTurnFunction to sqrtArc@:bind(altitude45deg).


LOCK steering TO HEADING(90, gravityTurnFunction(), -90).

until apoapsis >= targetOrbit {
    print ("Pitch: " + round(gravityTurnFunction(), 1)) at (0, 0).
}


set throt to 0.
LOCK steering TO prograde.


// until altitude >= targetOrbit {
until altitude >= 70000 {
    if apoapsis < targetOrbit {
        set throt to 1.
    }
    else {
        set throt to 0.
        wait 1.
    }
}

