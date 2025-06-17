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

function burnTime {
    parameter throt to 1.
    parameter dV to nextNode:burnvector:mag.
    parameter isp to getIsp().

    local thrust to ship:availablethrust*throt.
    local massFlow is thrust/(isp * constant:g0).

    return - (CONSTANT:E^(ln(ship:mass)-(dV*massFlow)/thrust)-ship:mass)/massFlow.
}

function executeManeuver {
    parameter minBurnTime to 0.
    parameter askExit to true.
    clearScreen.

    local throt is 1.
    local maneuverNode is nextNode.

    lock steering to maneuverNode:burnvector.

    local nodedV to maneuverNode:burnvector:mag.

    local isp is getIsp().
    if isp = 0 {
        print "Error: No engines activated".
        print "Press any key to exit".
        terminal:input:getchar().
        return 1.
    }

    local totalThrust is ship:availablethrust.
    local startMass is ship:mass.

    local startTime is 0.
    local endTime is 0.

    function calculateBurn {

        clearScreen.
        print "-------------------------------------" at (0, 0).
        print "Node dV: " + round(nodedV, 2) + "m/s" at (0, 1).
        print "Isp:     " + round(isp, 2) + "m/s" at (0,2).
        print "Thrust:  " + round(totalThrust, 2) + "kN" at (0,3).
        print "Mass:    " + round(startMass, 2) + "t" at (0,4).
        print "-------------------------------------" at (0,5).

        local burnT is burnTime(throt).
        local halfdVBurnTime is burnTime(throt, nodedV/2).

        if burnT < minBurnTime {
            set throt to (burnT/minBurnTime)*throt.
            calculateBurn().
        } 
        else {
            print "Burn:" at (0, 6).
            print "     Throt:          " + round(throt*100, 1) + "%" at (0, 7).
            print "     Half dV time:   " + round(halfdVBurnTime, 2) + "s" at (0, 8).
            print "     Total time:     " + round(burnT, 2) + "s" at (0, 9).
            print "-------------------------------------" at (0, 10).
            print "[C] Change min burn time (" + minBurnTime + "s)" at (0, 11).


            set startTime to maneuverNode:time - halfdVBurnTime.
            set endTime to startTime + burnT.

            print "[Q] Cancel" at (0, 36).
        }
    }

    calculateBurn().

    when time:seconds >= startTime then {
        lock throttle to throt.
        print "Start burn                              " at (0, 11).
    }

    when time:seconds >= endTime - 3 then {
        lock steering to facing.
    }

    when time:seconds >= endTime then {
        lock throttle to 0.
    }

    // Warping
    local done to false.
    local maxWarpLevel is kuniverse:timewarp:RAILSRATELIST:length - 1.
    when startTime - time:seconds - 10 < kuniverse:timewarp:RAILSRATELIST[maxWarpLevel - 1]*10 then {
        if done { return. }
        set maxWarpLevel to maxWarpLevel - 1.
        print "Max warp: " + kuniverse:timewarp:RAILSRATELIST[maxWarpLevel] + "                      " at (0, 13).
        print "At level: " + (maxWarpLevel + 1) at (0, 14).
        if maxWarpLevel > 0 {
            preserve.
        }
    }
    when warp > maxWarpLevel then {
        if done { return. }

        set warp to maxWarpLevel.
        preserve.
    }

    // Countdown
    until time:seconds >= startTime {
        print "Start in:  " + round(startTime - time:seconds) + "s      " at (0, 16). 

        if terminal:input:hasChar {
            local input is terminal:input:getChar():toLower.

            if input = "q" {
                lock throttle to 0.
                set maxWarpLevel to 1.
                set done to true.
                unlock all.
                return 1.
            }
            if input = "c" {
                clearScreen.
                print "-------------------------------------".
                print "Min burn time: ".
                print "Default 0s".

                set minBurnTime to readLine(16, 1):toNumber(0).
                set throt to 1.
                calculateBurn().
            }
        }
    }

    // Remove countdown
    print "                                                           " at (0, 11).
    print "                                                           " at (0, 14).
    print "                                                           " at (0, 16).

    // Burn
    until time:seconds >= endTime {
        print round(endTime - time:seconds, 2) + "s left                    " at (0, 13). 

        if terminal:input:hasChar if terminal:input:getChar():toLower = "q" {
            reboot.
        }
    }.

    print "Burn finished                 " at (0, 11).
    lock throttle to 0.
    set maxWarpLevel to 1.
    set done to true.
    unlock all.

    if askExit {
        print "Press any key to exit                          " at (0, 13).
        terminal:input:getchar().
    }

    clearScreen.
    if hasNode and nextNode = maneuverNode { remove nextNode. }
    return 0.
}   
