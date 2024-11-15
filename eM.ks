@lazyGlobal off.

function getIsp {
    parameter vess is ship.

    local isp is 0.
    local count is 0.

    for e in vess:engines {
        if e:availableThrust > 0 {
            set isp to isp + e:visp.
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

    return isp.
}

function executeManeuver {
    clearScreen.
    
    print "-------------------------------------".
    print "Min burn time: ".
    print "Default 10".

    local minBurnTime is 0.

    global throt is 1.
    global throtDownStep is 0.99.
    global maneuverNode is nextNode.

    clearScreen.

    lock steering to maneuverNode:burnvector.

    local nodedV to maneuverNode:burnvector:mag.

    local isp is getIsp().
    if isp = 0 return.

    local totalThrust is ship:availablethrust.
    local startMass is ship:mass.

    global startTime is 0.
    global endTime is 0.

    function calculateBurn {

        clearScreen.
        print "Node dV: " + round(nodedV, 2) + "m/s".
        print "Isp:     " + round(isp, 2) + "m/s".
        print "Thrust:  " + round(totalThrust, 2) + "kN".
        print "Mass:    " + round(startMass, 2) + "t".
        print "-------------------------------------".


        local thrust to totalThrust*throt.
        local massFlow is thrust/(isp * constant:g0).
        local burnTime is - (CONSTANT:E^(ln(startMass)-(nodedV*massFlow)/thrust)-startMass)/massFlow.
        local halfdVBurnTime is - (CONSTANT:E^(ln(startMass)-((nodedV/2)*massFlow)/thrust)-startMass)/massFlow.
        
        until burnTime >= minBurnTime {
            set thrust to thrust*throtDownStep.
            set massFlow to thrust/isp.

            set burnTime to - (CONSTANT:E^(ln(startMass)-(nodedV*massFlow)/thrust)-startMass)/massFlow.
            set halfdVBurnTime to - (CONSTANT:E^(ln(startMass)-((nodedV/2)*massFlow)/thrust)-startMass)/massFlow.

        }

        set throt to thrust/totalThrust.


        print "-------------------------------------" at (0, 7).
        print "Burn:" at (0, 8).
        print "     Throt:          " + round(throt*100, 1) + "%" at (0, 9).
        print "     Half dV time:   " + round(halfdVBurnTime, 2) + "s" at (0, 10).
        print "     Total time:     " + round(burnTime, 2) + "s" at (0, 11).
        print "-------------------------------------" at (0, 12).
        print "[C] Change min burn time (" + minBurnTime + "s)" at (0, 13).


        set startTime to maneuverNode:time - halfdVBurnTime.
        set endTime to startTime + burnTime.

        print "[Q] Cancel" at (0, 36).
    }

    calculateBurn().

    when time:seconds >= startTime then {
        lock throttle to throt.
        print "-------------------------------------" at (0, 19).
        print "Start burn                 " at (0, 20).
    }

    when time:seconds >= endTime then {
        lock throttle to 0.
    }

    // Warping
    local maxWarpLevel is kuniverse:timewarp:RAILSRATELIST:length - 1.
    when startTime - time:seconds - 10 < kuniverse:timewarp:RAILSRATELIST[maxWarpLevel - 1]*10 then {
        set maxWarpLevel to maxWarpLevel - 1.
        print "Max warp: " + kuniverse:timewarp:RAILSRATELIST[maxWarpLevel] + "                      " at (0, 17).
        print "At level: " + (maxWarpLevel + 1) at (0, 18).
        if maxWarpLevel > 0 {
            preserve.
        }
    }
    when warp > maxWarpLevel then {
        set warp to maxWarpLevel.
        if maxWarpLevel > -1 {
            preserve.
        }
    }

    // Countdown
    until time:seconds >= startTime {
        print "Start in:  " + round(startTime - time:seconds) + "s      " at (0, 15). 

        if terminal:input:hasChar {
            local input is terminal:input:getChar():toLower.

            if input = "q" {
                reboot.
            }
            if input = "c" {
                clearScreen.
                print "-------------------------------------".
                print "Min burn time: ".
                print "Default 0s".

                set minBurnTime to read_line(16, 1):toNumber(0).
                set throt to 1.
                calculateBurn().
            }
        }
    }

    // Remove countdown
    print "                                                           " at (0, 15).

    // Burn
    until time:seconds >= endTime {
        print round(endTime - time:seconds, 2) + "s left                    " at (0, 21). 

        if terminal:input:hasChar if terminal:input:getChar():toLower = "q" {
            reboot.
        }
    }.

    print "-------------------------------------" at (0, 21).
    print "Burn finished" at (0, 22).
    lock throttle to 0.
    set maxWarpLevel to -1.
    unlock all.

    print "Press any key to exit" at (0, 24).
    terminal:input:getchar().

    clearScreen.
}   
