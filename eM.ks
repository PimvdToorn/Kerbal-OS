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

    local ispg0 is ispg0s/count.
    local isp is ispg0 * constant:g0.

    return isp.
}

// function accAtT {
//     parameter t.
//     parameter F.
//     parameter M0.
//     parameter Isp.

//     return F / (M0 - t*(F/Isp)).
// }

// function calculateBurn {
//     parameter step is 0.1.
//     parameter thrust is ship:availablethrust().
//     parameter Isp is getIsp().
//     parameter startMass is ship:mass.
//     parameter targetdV is nextNode:burnvector:mag.

//     local burndV is 0.
//     local burnTime is 0.
//     local halfdVBurnTime is 0.

//     until burndV >= targetdV {
//         set burnTime to burnTime + step.

//         // Middle integral
//         set burndV to burndV + (accAtT(burnTime-(step/2), thrust, startMass, isp) * step).

//         if halfdVBurnTime = 0 and burndV >= targetdV/2 {
//             set halfdVBurnTime to burnTime.
//         }

//         print "Burn sec:    " + round(burnTime, 1) at (0, 5).
//         print "Burn dV:     " + round(burndV, 1) at (0, 6).
//     }

//     return list(burnTime, halfdVBurnTime).
// }

function executeManeuver {
    parameter minBurnTime is 10.
    parameter throt is 1.
    parameter throtDownStep is 0.5.
    parameter maneuverNode is nextNode.

    lock steering to maneuverNode:burnvector.

    local nodedV to maneuverNode:burnvector:mag.

    local isp is getIsp().
    local totalThrust is ship:availablethrust().
    local startMass is ship:mass.

    local thrust is totalThrust * throt.

    clearScreen.
    print "Node dV: " + nodedV + "m/s".
    print "Isp:     " + isp + "m/s".
    print "Thrust:  " + thrust + "N".
    print "Mass:    " + startMass + "kg".
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


    until time:seconds >= startTime {
        print "Start in:     " + round(startTime - time:seconds, 2) + "s      " at (0, 13). 
    }

    lock throttle to throt.

    when time:seconds >= endTime then {
        lock throttle to 0.
    }

    until time:seconds >= endTime {
        print round(endTime - time:seconds, 2) + "s left                    " at (0, 13). 
    }.



    print "-------------------------------------" at (0, 14).
    print "Burn finished" at (0, 15).
}   

parameter minTime is 10.
parameter Othrot is 1.

executeManeuver(minTime, Othrot).


print "Press any key to exit" at (0, 16).
terminal:input:getchar().
clearScreen.