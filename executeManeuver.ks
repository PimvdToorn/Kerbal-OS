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

function accAtT {
    parameter t.
    parameter F.
    parameter M0.
    parameter Isp.

    return F / (M0 - t*(F/Isp)).
}

function calculateBurn {
    parameter startStep is 0.1.
    parameter minStep is 0.001.
    parameter thrust is ship:availablethrust().
    parameter Isp is getIsp().
    parameter startMass is ship:mass.
    parameter targetdV is nextNode:burnvector:mag.

    local currentStep is startStep.
    local burndV is 0.
    local lastdV is 0.
    local burnTime is 0.
    local lastTime is 0.
    local halfdVBurnTime is 0.

    until currentStep < minStep {

        if currentStep >= minStep {
            set burndV to lastdV.
            set burnTime to lastTime.
        }
    
        until burndV >= targetdV {
            set lastdV to burndV.
            set lastTime to burnTime.

            set burnTime to burnTime + currentStep.

            // Middle integral
            set burndV to burndV + (accAtT(burnTime-(currentStep/2), thrust, startMass, isp) * currentStep).

            if halfdVBurnTime = 0 and burndV >= targetdV/2 {
                set halfdVBurnTime to burnTime.
            }

            print "Burn sec:    " + round(burnTime, 1) at (0, 5).
            print "Burn dV:     " + round(burndV, 1) at (0, 6).
        }

        set currentStep to currentStep * 0.1.
    }

    return list(burnTime, halfdVBurnTime).
}

function executeManeuver {
    parameter startStep is 0.1.
    parameter minStep is 0.001.
    parameter maneuverNode is nextNode.
    parameter minBurnTime is 10.
    parameter throtDownStep is 0.5.


    lock steering to maneuverNode:burnvector.

    local nodedV to maneuverNode:burnvector:mag.

    local isp is getIsp().
    local totalThrust is ship:availablethrust().
    local startMass is ship:mass.

    clearScreen.
    print "Node dV: " + nodedV + "m/s".
    print "Isp:     " + isp + "m/s".
    print "Thrust:  " + totalThrust + "N".
    print "Mass:    " + startMass + "kg".
    print "-------------------------------------".


    local burnTime is -1.
    local halfdVBurnTime is 0.
    local thrust to totalThrust/throtDownStep.
    
    until burnTime >= minBurnTime {
        set thrust to thrust*throtDownStep.

        local timeList is calculateBurn(startStep, minStep, thrust, isp).
        set burnTime to timeList[0].
        set halfdVBurnTime to timeList[1].

        
    }

    local throt is thrust/totalThrust.

    print "-------------------------------------" at (0, 7).
    print "Burn:" at (0, 8).
    print "     Throt:          " + throt*100 + "%" at (0, 9).
    print "     Half dV time:   " + round(halfdVBurnTime, 1) at (0, 10).
    print "     Total time:     " + round(burnTime, 1) at (0, 11).
    print "-------------------------------------" at (0, 12).




    local startTime is maneuverNode:time - halfdVBurnTime.
    local endTime is startTime + burnTime.


    until time:seconds >= startTime {
        print "Start in:     " + round(startTime - time:seconds, 1) + "s      " at (0, 13). 
    }

    lock throttle to throt.
    wait until time:seconds >= endTime.
    lock throttle to 0.
}   

parameter step.
parameter throt.

executeManeuver().