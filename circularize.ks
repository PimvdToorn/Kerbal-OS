runOncePath("0:libraries/utils/utils").
runOncePath("0:libraries/utils/orbit").
runOncePath("0:libraries/read_line").
runOncePath("0:eM").

function circularizeInput {
    clearScreen.
    print "Target altitude: " at (0, 0).
    local targetAlt to readLine(17, 0):toNumber().
    print "Precision (default 1000m): " at (0, 1).
    local precision to readLine(11, 1):toNumber(1000).
    circ(targetAlt, precision).
}

function circ {
    parameter targetAlt.
    parameter precision to 1.
    local ret to circularize(targetAlt, precision).
    if ret = 1 {
        circ(targetAlt, precision).
    }
    else if ret = 2 {
        circularizePrecise(targetAlt, precision).
    }
}

function circularize {
    parameter targetAlt.
    parameter precision to 1000.
    clearScreen.
    
    if apoapsis < targetAlt {
        print "Raising apoapsis to " + format(targetAlt) + "m" at (0, 0).
        lock steering to prograde.
        waitAlignmentDirection(prograde).

        lock throttle to 1.
        until apoapsis >= targetAlt.
        lock throttle to 0.
        wait 1.
    }
    else if periapsis > targetAlt {
        print "Lowering periapsis to " + format(targetAlt) + "m" at (0, 0).
        lock steering to retrograde.
        waitAlignmentDirection(retrograde).

        lock throttle to 1.
        until periapsis <= targetAlt.
        lock throttle to 0.
        wait 1.
    }
    clearScreen.

    local timeAtAlt to timeAtAltitude(targetAlt).
    // local velocityVecAtTime to orbitableVelocityAtTime(timeAtAlt):orbit.
    local circSpeed to circulairSpeed(targetAlt).

    // local upVecAtAlt to positionAtTime(timeAtAlt) - body:position.
    // Remove up vector from velocity
    // local flatSurfaceVector to vectorExclude(upVecAtAlt, velocityVecAtTime).
    // Make the magnitude the circular speed
    // local circularVector to flatSurfaceVector:normalized * circSpeed.
    // local vecDiff to circularVector - velocityVecAtTime.

    // local velAtTime to velocityVecAtTime:mag.
    local velAtTime to speedAtAltitude(targetAlt).

    local angle to firstAngleAtAltitude(targetAlt).
    // if angle > 0 { set radialBurn to -radialBurn. }

    local progradeBurn to circSpeed*cos(-angle) - velAtTime.
    local radialBurn to circSpeed*sin(-angle).
    
    local totalBurn to sqrt(progradeBurn^2 + radialBurn^2).

    if totalBurn < 0.1 {
        // circularizePrecise(targetAlt, precision).
        return 2.
    }
    // When timeAtAlt is closer than the burntime + 1 min to rotate, wait until after timeAtAlt
    if timeAtAlt - time:seconds < burnTime(1, totalBurn) + 60 {
        clearScreen.
        print "Burn too close, wait for next option" at (0, 0).
        until time:seconds >= timeAtAlt {
            print "Seconds until next calc: " + round(timeAtAlt - time:seconds, 0) + "              " at (0, 1).
        }
        // circularize(targetAlt, precision).
        return 1.
    }

    // local progradeBurn to vecDiff * progradeVector(velocityVecAtTime).
    // local radialBurn to abs(vecDiff * radialVector(velocityVecAtTime)).

    
    add node(
        timeAtAlt,
        radialBurn,
        0,
        progradeBurn
    ).

    // print "Circ speed: " + circSpeed at (0, 21).
    // print "Vel at time: " + velAtTime at (0, 22).
    // print "Diff x: " + vecDiff:x at (0, 23).
    // print "Diff y: " + vecDiff:y at (0, 24).
    // print "Diff z: " + vecDiff:z at (0, 25).
    // print "Diff mag: " + vecDiff:mag at (0, 26).

    print "Prograde burn: " + progradeBurn at (0, 27).
    print "Radial burn: " + radialBurn at (0, 28).

    // print "Vertical speed: " + firstVerticalSpeedAtAltitude(targetAlt) at (0, 29).
    // print "Angle at apoapsis: " + angleAtAltitude(apoapsis) at (0, 30).
    // print "Angle at altitude: " + firstAngleAtAltitude(targetAlt) at (0, 31).


    // function drawVecs {
    //     // local progrVector to vecDraw(
    //     //     { return ship:position. }, 
    //     //     { return velocity:orbit. }
    //     // ).
    //     // set progrVector:show to true.
    //     // local upV to vecDraw(
    //     //     { return ship:position. }, 
    //     //     { return up:vector*5. },
    //     //     rgb(1, 0, 0)
    //     // ).
    //     // set upV:show to true.
    //     // local normVector to vecDraw(
    //     //     { return ship:position. }, 
    //     //     { return normalVector()*5. },
    //     //     rgb(0, 1, 0)
    //     // ).
    //     // set normVector:show to true.
    //     // local radVector to vecDraw(
    //     //     { return ship:position. }, 
    //     //     { return radialVector()*5. },
    //     //     rgb(0, 0, 1)
    //     // ).
    //     // set radVector:show to true.

    //     // local flatSurfVector to vecDraw(
    //     //     { return positionAtTime(timeAtAlt). }, 
    //     //     { return flatSurfaceVector*10000. },
    //     //     rgb(1, 0, 1)
    //     // ).
    //     // set flatSurfVector:show to true.
    //     // set circVector to vecDraw(
    //     //     { return positionAtTime(timeAtAlt). }, 
    //     //     { return circularVector*10000. },
    //     //     rgb(0, 1, 0.5)
    //     // ).
    //     // set circVector:show to true.

    //     // local positionTimeVector to vecDraw(
    //     //     { return ship:body:position. }, 
    //     //     { return positionAtTime(timeAtAlt) - ship:body:position. },
    //     //     rgb(1, 1, 0)
    //     // ).
    //     // set positionTimeVector:show to true.
    //     // local upVec to vecDraw(
    //     //     { return positionAtTime(timeAtAlt). }, 
    //     //     { return upVecAtAlt*250000. },
    //     //     rgb(1, 0.5, 0)
    //     // ).
    //     // set upVec:show to true.
    // }
    // drawVecs().

    executeManeuver(5, false).
    remove nextNode.
    wait(1).
    unlock all.

    if abs(apoapsis - targetAlt) > precision or abs(periapsis - targetAlt) > precision {
        circularize(targetAlt, precision).
        return 1.
    }
    return 0.
    // clearVecDraws().
    // terminal:input:getchar().
}

function circularizePrecise {
    parameter targetAlt.
    parameter precision to 1.
    
    clearScreen.
    print "Circularizing precise to " + format(targetAlt) + "m" at (0, 0).
    print "With precision " + precision + "m" at (0, 1).

    local apoapsDiff to abs(apoapsis - targetAlt).
    local periapsDiff to abs(periapsis - targetAlt).
    print "Apoapsis diff: " + apoapsDiff at (0, 2).
    print "Periapsis diff: " + periapsDiff at (0, 3).

    local apoapsCorrect to apoapsDiff < precision.
    local periapsCorrect to periapsDiff < precision.

    if apoapsCorrect and periapsCorrect { return. }
    if apoapsCorrect {
        circularizeApoapsis().
        circularizePrecise(targetAlt, precision).
        return.
    }
    else if periapsCorrect {
        circularizePeriapsis().
        circularizePrecise(targetAlt, precision).
        return.
    }

    local maxPossibleAcc to maxAcceleration().
    local maxAcc to precision / 2.
    local throt to min(1, maxAcc / maxPossibleAcc).

    if eta:apoapsis < eta:periapsis {
        print "Going to apoapsis" at (0, 5).
        local halfTime to periapsDiff / maxAcc / 2.

        if periapsis < targetAlt {
            lock steering to prograde.
            waitAlignmentDirection(prograde).
            until eta:apoapsis < halfTime.
            lock throttle to throt.
            until periapsis >= targetAlt - precision/10.
        }
        else {
            lock steering to retrograde.
            waitAlignmentDirection(retrograde).
            until eta:apoapsis < halfTime.
            lock throttle to throt.
            until periapsis <= targetAlt + precision/10.
        }
    }
    else {
        print "Going to periapsis" at (0, 5).
        local halfTime to apoapsDiff / maxAcc / 2.

        if apoapsis < targetAlt {
            lock steering to prograde.
            waitAlignmentDirection(prograde).
            until eta:periapsis < halfTime.
            lock throttle to throt.
            until apoapsis >= targetAlt - precision/10.
        }
        else {
            lock steering to retrograde.
            waitAlignmentDirection(retrograde).
            until eta:periapsis < halfTime.
            lock throttle to throt.
            until apoapsis <= targetAlt + precision/10.
        }
    }
    lock throttle to 0.
    wait(1).
    circularizePrecise(targetAlt, precision).
}

function circularizeApoapsis {
    local diff to circulairDifference(apoapsis).
    add node(time:seconds + eta:apoapsis, 0, 0, diff).
    executeManeuver(5).
    remove nextNode.
}

function circularizePeriapsis {
    local diff to circulairDifference(periapsis).
    add node(time:seconds + eta:periapsis, 0, 0, diff).
    executeManeuver(5).
    remove nextNode.
}

function circulairDifference {
    parameter targetAlt.
    local circleSpeed to circulairSpeed(targetAlt).
    local speedAtTarget to speedAtAltitude(targetAlt).
    return circleSpeed - speedAtTarget.
}

function circulairSpeed {
    parameter targetAlt.
    local mu to body:mu.
    local bodyRadius to body:radius.
    local targetRadius to targetAlt + bodyRadius.
    return sqrt(mu / targetRadius).
}

    // Bereken de doelradius en de benodigde circulaire snelheid
    // local body_radius to ship:body:radius.
    // local target_radius to target_altitude + body_radius.
    // local mu to ship:body:mu.
    // local circular_speed to sqrt(mu / target_radius).

    // Burn tot apoapsis of periapsis juiste hoogte heeft
    // Burn verschil snelheid en circulaire snelheid

    // Aligning twee satellieten
    // Verschil in gewilde en huidige angle naar de tijd van de orbit
    // maneuver maken die orbit vertraagd/versneld met gewilde verschil
    // Volgende orbit weer terug zetten

    
