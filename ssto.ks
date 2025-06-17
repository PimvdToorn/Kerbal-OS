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
    local targetHorizonRoll to 0.
    local targetClimb to 0.

    local pitchStrength to 1.
    local yawStrength to 3.
    local rollStrength to 3.

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

    function loop {
        local now to time:seconds.
        hud().

        // Steering
        if now > lastSteerTime + 0.1 {
            steerPlane(maxAngleOfAttack, targetClimb, targetHead, targetHorizonRoll, pitchStrength, yawStrength, rollStrength).
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
    // set targetHead to 90..
    lock steering to heading(targetHead, targetPitch, 0).
    for engine in s1Engines { engine:activate().}
    for engine in s12Engines { engine:activate().}
    until airspeed > 80 { hud(). }
    set targetPitch to 3.

    until altitude > 78 or latlng(-0.0485, -74.7293):distance > 2500 { hud(). }
    set targetClimb to 10.
    // set targetHead to 90.
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

    when altitude > 19000 then { set maxAngleOfAttack to 2. }

    when altitude > 21000 or rapiers[0]:thrust < 30 then {
        for engine in s1Engines { engine:shutdown(). }
        for rapier in rapiers { rapier:toggleMode(). }
        // set targetClimb to 8.
        set maxAngleOfAttack to 6.
    }

    until airspeed > 1550 {
        set targetClimb to 4 - (altitude - 18000)/3000 * 4.
        loop().
    }
    for engine in s2Engines { engine:activate(). }
    // set targetClimb to 5.
    set maxAngleOfAttack to 5.

    // until altitude > 40000 { 
    //     // set maxAngleOfAttack to min(7, max(0, altitude - altitude1300)/20000 * 4 + 3).
    //     // set targetPitch to min(20, max(0, altitude - altitude1300)/10000 * 10 + 10).

    //     set targetClimb to max(5, getPitch(prograde:vector)).
    //     if apoapsis < 75000 { set throt to 1. } 
    //     else { set throt to 0. }
    //     loop(). 
    // }

    set throt to 1.
    until apoapsis > 75000 {
        set targetClimb to max(5, getPitch(prograde:vector)).
        loop().
    }
    set throt to 0.
    for rapier in rapiers { rapier:shutdown(). }

    // if the stage 2 engines can reach orbit in time without the rapiers, then shut them down
    


    // until altitude > 50000 { 
    //     set targetClimb to getPitch(prograde:vector).
    //     if apoapsis < 75000 { set throt to 1. } 
    //     else { set throt to 0. }
    //     loop(). 
    // }
    // set targetClimb to round(getPitch(prograde:vector), 1).
    // set maxAngleOfAttack to 90.

    set maxAngleOfAttack to 1.
    set pitchStrength to 2.
    until altitude > 70000 { 
        set targetClimb to max(1, getPitch(prograde:vector)).

        local speedDifference to circularSpeed(apoapsis) - speedAtAltitude(apoapsis).
        local burnT is burnTime(1, speedDifference).
        local timeDifference is timeAtApoapsis() - timeAtAltitude(70000).
        print "Time difference: " + timeDifference at (0, 16).
        print "Burn time: " + burnT at (0, 17).

        local extraSeconds to 10.
        local minTimeDifference to burnT/2 + extraSeconds.

        if timeDifference < minTimeDifference {
            // Speed at apoaps vs circular speed, als apoaps eta minder dan helft burnTime is, dan meer power, anders low power ion/nuclear
            // Of afstand apoaps vs 70km
            local diff to minTimeDifference - timeDifference.
            set throt to min(1, diff/10).
        }
        else if apoapsis < 75000 { 
            set throt to min(1, abs(75000 - apoapsis) / 100). 
        } 
        else { set throt to 0. }
        loop(). 
    }
    set throt to 0.
    wait(1).

    // local circleSpeed to circulairSpeed(apoapsis).
    // local apoapsisSpeed to speedAtAltitude(apoapsis).
    // local diff to circleSpeed - apoapsisSpeed.
    // add node(time:seconds + obt:eta:apoapsis, 0, 0, diff).
    circularizeApoapsis().
    
    unlock steering.
    unlock throttle.
}

function sstoReentry {
    clearScreen.
    // lock steering to prograde.
    // waitAlignmentDirection(prograde).

    local maxAngleOfAttack to 45.
    local targetHead to 90.4.
    local targetClimb to 0.
    local targetRoll to 0.
    local pitchStrength to 3.
    local yawStrength to 3.

    local lastSteerTime to time:seconds.

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

        local groundDistance to geoDistance(ship:geoposition, latlng(-0.0485, -74.7293)).
        local targetAltitude to groundDistance / 6 + 78.

        drawHud(list(
            // "Max TWR:        " + round(ship:availablethrust / (ship:mass * constant:g0), 2),
            // "TWR:            " + round(ship:thrust / (ship:mass * constant:g0), 2),
            // "Throttle:       " + round(throt, 2),
            // "Target speed:   " + round(targetSpeed(), 0) + " m/s",
            "-------------------------------------",
            "Heading:        " + round(getHeading(), 1),
            "Target heading: " + round(targetHead, 1),
            "Roll:           " + round(getHorizonRoll(), 2),
            "Target roll:    " + round(targetRoll, 2),
            "-------------------------------------",
            "Pitch:          " + round(getPitch(), 1),
            "Target climb:   " + round(targetClimb, 1),
            "Prograde pitch: " + round(getPitch(prograde:vector), 1),
            "AoA:            " + round(getAoA(), 1),
            "Max AoA:        " + round(maxAngleOfAttack, 1),
            "-------------------------------------",
            "Ground distance: " + format(round(groundDistance, 0)),
            "Target altitude: " + format(round(targetAltitude, 0))
        )).
        print "[Q] Quit" at (0, 36).
    }

    function loop {
        local now to time:seconds.
        hud().

        // Steering
        if now > lastSteerTime + 0.1 {
        

            steerPlane(maxAngleOfAttack, targetClimb, getHeading(progradeVector()), targetRoll, pitchStrength, yawStrength).
            set lastSteerTime to now.
        }
    }

    lock steering to prograde.
    if altitude > 70000 waitAlignmentDirection(prograde).

    until altitude < 45000 {
        // between 70 and 20 km from 90 to 0 degrees
        // below 45 km below 30 degrees
        set maxAngleOfAttack to valueMap(altitude, 45000, 70000, 33, 90).//33 + (altitude - 45000)/25000 * 50.
        loop().
    }

    until altitude < 28000 {
        set maxAngleOfAttack to valueMap(altitude, 28000, 45000, 22, 33).//18 + (altitude - 25000)/20000 * 15.
        loop().
    }

    // until altitude < 18000 {
    //     set maxAngleOfAttack to valueMap(altitude, 18000, 25000, 7, 18).//7 + (altitude - 18000)/15000 * 11.
    //     loop().
    // }

    // Keep between latitudes approaching the runway
    // move naar latitude van runway

    // Roll enkele graden, relatief aan hoe hard je gaat

    // Target climb veranderen op basis van afstand tot de runway
    // richting het gewilde pad

    // max angle of attack op basis van snelheid en hoogte


    set maxAngleOfAttack to 4.
    set pitchStrength to 0.1.
    local decentRatio to 1/6.
    local decentAngle to -arcSin(decentRatio).

    until altitude < 125 {
        // Pitch
        local groundDistance to geoDistance(ship:geoposition, latlng(-0.0485, -74.7293)).
        local targetAltitude to groundDistance * decentRatio + 78.
        local tAltDifference to targetAltitude - altitude.
        set targetClimb to decentAngle + tAltDifference / 1000.

        // Roll
        local coords to ship:geoposition.
        local dist to latlng(-0.0485, coords:lng):distance.
        if coords:lat < -0.0485 { set dist to -dist. }
        set targetRoll to valueMap(dist, 0, 1000, 0, 75).

        // Heading
        local head to getHeading(progradeVector()).
        set targetHead to head + valueMap(dist, 0, 1000, 0, 10).

            
        loop().
    }
    gear on.


    // when altitude < 125 then {
    //     gear on.

    //     when altitude < 80 then {
    //         set maxAngleOfAttack to 0.
    //     }
    // }

    until false { loop(). }
}


