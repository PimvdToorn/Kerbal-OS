@lazyGlobal off.

function getIsp {
    parameter vess is ship.

    local ispg0s is 0.
    local count is 0.

    for e in vess:engines {
        if e:availableThrust > 0 {
            set ispg0s to ispg0s + e:visp.
            set count to count + 1.
        } 
    }

    if count = 0 {
        print "Error: No engines activated".
        print " ".
        print "Press any key to exit".
        terminal:input:getchar().
        return 0.
    }

    local ispg0 is ispg0s/count.
    local isp is ispg0 * constant:g0.

    return isp.
}

function executeManeuver {
    parameter minBurnTime is 10.
    parameter throt is 1.
    parameter throtDownStep is 0.5.
    parameter maneuverNode is nextNode.

    clearScreen.

    lock steering to maneuverNode:burnvector.

    local nodedV to maneuverNode:burnvector:mag.

    local isp is getIsp().
    if isp = 0 return.

    local totalThrust is ship:availablethrust().
    local startMass is ship:mass.

    local thrust is totalThrust * throt.

    clearScreen.
    print "Node dV: " + round(nodedV, 2) + "m/s".
    print "Isp:     " + round(isp, 2) + "m/s".
    print "Thrust:  " + round(thrust, 2) + "N".
    print "Mass:    " + round(startMass, 2) + "kg".
    print "-------------------------------------".


    local burnTime is -1.
    local halfdVBurnTime is 0.
    set thrust to (totalThrust*throt)/throtDownStep.
    
    until burnTime >= minBurnTime {
        set thrust to thrust*throtDownStep.
        local massFlow is thrust/isp.

        set burnTime to - (CONSTANT:E^(ln(startMass)-(nodedV*massFlow)/thrust)-startMass)/massFlow.
        set halfdVBurnTime to - (CONSTANT:E^(ln(startMass)-((nodedV/2)*massFlow)/thrust)-startMass)/massFlow.

    }

    set throt to thrust/totalThrust.


    print "-------------------------------------" at (0, 7).
    print "Burn:" at (0, 8).
    print "     Throt:          " + throt*100 + "%" at (0, 9).
    print "     Half dV time:   " + round(halfdVBurnTime, 1) at (0, 10).
    print "     Total time:     " + round(burnTime, 1) at (0, 11).
    print "-------------------------------------" at (0, 12).


    local startTime is maneuverNode:time - halfdVBurnTime.
    local endTime is startTime + burnTime.

    print "[Q] Cancel" at (0, 36).

    until time:seconds >= startTime {
        print "Start in:     " + round(startTime - time:seconds, 2) + "s      " at (0, 13). 

        if terminal:input:hasChar if terminal:input:getChar():toLower = "q" {
            unlock all.
            return.
        }
    }

    lock throttle to throt.

    when time:seconds >= endTime then {
        lock throttle to 0.
    }

    until time:seconds >= endTime {
        print round(endTime - time:seconds, 2) + "s left                    " at (0, 13). 

        if terminal:input:hasChar if terminal:input:getChar():toLower = "q" {
            unlock all.
            return.
        }
    }.



    print "-------------------------------------" at (0, 14).
    print "Burn finished" at (0, 15).
    unlock all.

    print "Press any key to exit" at (0, 16).
    terminal:input:getchar().

    clearScreen.
}   
