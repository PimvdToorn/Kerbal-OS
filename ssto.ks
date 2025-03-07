@lazyGlobal off.
runOncePath("0:libraries/read_line").
runOncePath("0:libraries/utils/utils").
runOncePath("0:libraries/utils/orbit").
runOncePath("0:libraries/utils/steering").
runOncePath("0:circularize").
runOncePath("0:eM").

function sstoOrbit {
    clearScreen.

    local targetHead to 90.
    local targetPitch to 0.
    // local targetRoll to 270.
    local targetClimb to 0.

    // local maxHeadPerSecond to 10.
    // local maxPitchPerSecond to 200.
    // local maxRollPerSecond to 45.
    local maxAngleOfAttack to 15.

    local s1Engines to ship:partstagged("Stage 1").
    local s12Engines to ship:partstagged("Stage 1/2").
    local s2Engines to ship:partstagged("Stage 2").
    local rapiers to ship:partsnamed("Rapier").

    local throt to 1.
    lock throttle to throt.
    // local lastLoopTime to time:seconds.
    local lastChangeTime to time:seconds.
    local lastSteerTime to time:seconds.
    function targetSpeed {
        if altitude < 1000 {
            return 400.
        }
        if altitude < 20000 {
            return 400 + (altitude - 1000) / 19000 * 1600.
        }
        return 5000.
    }

    function hud {
        if terminal:input:hasChar {
            local input is terminal:input:getChar():toLower.

            if input = "q" {
                reboot.
            }
            else if input = "w" {
                set targetClimb to targetClimb + 1.
            }
            else if input = "s" {
                set targetClimb to targetClimb - 1.
            }
            else if input = "a" {
                set targetHead to targetHead - 0.1.
            }
            else if input = "d" {
                set targetHead to targetHead + 0.1.
            }
        }

        drawHud(list(
            "Max TWR:        " + round(ship:availablethrust / (ship:mass * constant:g0), 2),
            "TWR:            " + round(ship:thrust / (ship:mass * constant:g0), 2),
            "Throttle:       " + round(throt, 2),
            "Target speed:   " + round(targetSpeed(), 0) + " m/s",
            "-------------------------------------",
            "Heading:        " + round(getHeading(), 1) + "(" + round(targetHead, 1) + ")",
            "Roll:           " + round(ship:facing:roll, 2),
            "-------------------------------------",
            "Pitch:          " + round(getPitch(), 1),
            "Target climb:   " + round(targetClimb, 1),
            "Prograde pitch: " + round(getPitch(prograde:vector), 1),
            "AoA:            " + round(getAoA(), 1),
            "Max AoA:        " + round(maxAngleOfAttack, 1),
            "-------------------------------------"
            // "Apoapsis velocity: " + round(speedAtAltitude(apoapsis), 0) + " m/s"
        )).
        print "[Q] Quit" at (0, 36).
    }

    function steer {
        local progradePitch to getPitch(prograde:vector).

        local maxPitch to progradePitch + maxAngleOfAttack.
        local minPitch to progradePitch - maxAngleOfAttack.
        local difference to targetClimb - progradePitch.

        local tPitch to max(minPitch, min(maxPitch, getPitch() + difference * 3)).
        // Also harder steer for head and roll, e.g. head is 92, target 90, steer 88/86 etc

        lock steering to heading(targetHead, tPitch, 0).
        print "Pitch change to: " + tPitch  + "                                 " at (0, 16).
        // parameter maxHeadChange to maxHeadPerSecond * deltaTime.
        // parameter maxPitchChange to maxPitchPerSecond * deltaTime.
        // // local
        // local head to getHeading().   
        // local pitch to getPitch().
        // // local roll to facing:roll.
        // // print "Roll change to: " + maxDegreeChange_0_360(roll, targetRoll, maxRollPerSecond * deltaTime) at (0, 9).
        // print "Pitch change to: " + maxDegreeChange_90_90(pitch, tPitch, maxPitchChange) at (0, 16).
        // lock steering to heading(
        //     maxDegreeChange_0_360(head, targetHead, maxHeadChange),
        //     maxDegreeChange_90_90(pitch, tPitch, maxPitchChange),
        //     0
        //     // maxDegreeChange(roll, targetRoll, maxRollPerSecond * deltaTime)
        // ).
    }

    function loop {
        local now to time:seconds.
        hud().

        // Steering
        if now > lastSteerTime + 0.1 {
            steerPlane(maxAngleOfAttack, targetClimb, targetHead).
            // Higher steer back when over max pitch

            // if targetClimb > progradePitch {
            //     if getPitch() < progradePitch or targetClimb < maxPitch {
            //         steer(targetClimb + getAoA()).
            //         print "Steering target+AoA: " + targetClimb + getAoA() + "              " at (0, 14).
            //     } else if getPitch() < maxPitch {
            //         steer(maxPitch + getAoA()).
            //         print "Steering max pitch: " + maxPitch + "              " at (0, 14).
            //     } else {
            //         // Too high, nose hard steer back to progradePitch.
            //         // steer(progradePitch).
            //         // 0 tot 1 pitch te ver van maxpitch
            //         // van maxpitch tot progradepitch
            //         steer(maxpitch - (getPitch() - maxPitch) * 4).
            //         print "Steering mp - afstand: " + maxpitch - (getPitch() - maxPitch) * 4 + "              " at (0, 14).
            //     }
            // } else {
            //     if getPitch() > progradePitch or targetClimb > progradePitch - maxAngleOfAttack {
            //         steer(targetClimb - getAoA()).
            //     }
            //     else if getPitch() > progradePitch - maxAngleOfAttack {
            //         steer(minPitch - getAoA()).
            //     } else {
            //         // Hard steer back to progradePitch.
            //         // steer(progradePitch).
            //         steer(minPitch + (minPitch - getPitch()) * 4).
            //     }
            // }
            set lastSteerTime to now.
        }

        if time:seconds > lastChangeTime + 1 {
            if airspeed > targetSpeed() {
                set throt to throt - 0.01.
            } else {
                set throt to throt + 0.01.
            }
            set throt to max(0, min(1, throt)).
            set lastChangeTime to time:seconds.
        }

        // set lastLoopTime to now.
    }

    // Stacking to only have one check at a time
    // when airspeed > 250 then {
        // set maxPitchPerSecond to 20.

    when airspeed > 400 then {
        // set maxPitchPerSecond to 10.
        set maxAngleOfAttack to 5.

    when airspeed > 800 then {
        // set maxPitchPerSecond to 2.
        set maxAngleOfAttack to 2.
    } }


    // when apoapsis > 75000 then {
    //     lock throttle to 0.
    //     unlock throttle.
    // }

    // Take off
    lock steering to heading(targetHead, targetPitch, 0).
    for engine in s1Engines { engine:activate().}
    for engine in s12Engines { engine:activate().}
    until airspeed > 80 { hud(). }
    set targetPitch to 3.

    until altitude > 78 or latlng(-0.0485, -74.7293):distance > 2500 { hud(). }
    set targetClimb to 10.
    gear off.

    until altitude > 700 { loop(). }
    set maxAngleOfAttack to 7.
    // set targetPitch to 15.

    until airspeed > 600 { 
        // from <400 to 600m/s, pitch from 5 to 15
        set targetClimb to max(0, airspeed - 400)/200 * 10 + 5.
        loop(). 
    }
    set targetClimb to 15.

    until altitude > 13000 { loop(). }
    set targetClimb to 8.

    until altitude > 18000 { loop(). }
    set maxAngleOfAttack to 3.

    when altitude > 19000 then { set maxAngleOfAttack to 4. }

    when altitude > 21000 or rapiers[0]:thrust < 30 then {
        for engine in s1Engines { engine:shutdown(). }
        for rapier in rapiers { rapier:toggleMode(). }
    }

    until airspeed > 1600 {
        set targetClimb to 4 - (altitude - 18000)/3000 * 4.
        loop().
    }
    for engine in s2Engines { engine:activate(). }
    set targetClimb to 5.

    until altitude > 40000 { 
        // set maxAngleOfAttack to min(7, max(0, altitude - altitude1300)/20000 * 4 + 3).
        // set targetPitch to min(20, max(0, altitude - altitude1300)/10000 * 10 + 10).
        if apoapsis < 75000 { set throt to 1. } 
        else { set throt to 0. }
        loop(). 
    }

    // until altitude > 50000 { 
    //     set targetClimb to getPitch(prograde:vector).
    //     if apoapsis < 75000 { set throt to 1. } 
    //     else { set throt to 0. }
    //     loop(). 
    // }
    // set targetClimb to round(getPitch(prograde:vector), 1).
    // set maxAngleOfAttack to 90.

    set maxAngleOfAttack to 0.
    until altitude > 70000 { 
        set targetClimb to getPitch(prograde:vector).
        if apoapsis < 75000 { set throt to 1. } 
        else { set throt to 0. }
        loop(). 
    }

    // local circleSpeed to circulairSpeed(apoapsis).
    // local apoapsisSpeed to speedAtAltitude(apoapsis).
    // local diff to circleSpeed - apoapsisSpeed.
    // add node(time:seconds + obt:eta:apoapsis, 0, 0, diff).
    circularizeApoapsis().
    executeManeuver().
    
    unlock steering.
    unlock throttle.
}

function sstoReentry {
    clearScreen.

    
}


