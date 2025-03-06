function speedAtAltitude {
    parameter height.
    parameter a to ship:orbit:semiMajorAxis.
    local mu to ship:body:mu. // Gravitatieconstante van het lichaam

    // Bereken de snelheid op height via de vis-viva vergelijking
    return sqrt(mu * (2 / (ship:body:radius + height) - 1 / a)).
}

function verticalSpeedAtAltitude {
    parameter height.
    parameter orb to orbit.
    return speedAtAltitude(height) * sin(angleAtAltitude(height, orb)).
}

function firstVerticalSpeedAtAltitude {
    parameter height.
    parameter orb to orbit.
    local vertSpeed to verticalSpeedAtAltitude(height, orb).
    
    if (orb:eta:apoapsis > orb:eta:periapsis and altitude > height) 
    or (orb:eta:apoapsis < orb:eta:periapsis and altitude < height) {
        return -vertSpeed.
    }
    return vertSpeed.
}

function angleAtAltitude {
    parameter height.
    parameter orb to orbit.
    local e to orb:eccentricity.
    local trueAnomaly to trueAnomalyAtAltitude(height, orb).
    return arcTan((e * sin(trueAnomaly) / (1 + e * cos(trueAnomaly)))).
}

function firstAngleAtAltitude {
    parameter height.
    parameter orb to orbit.
    local angle to angleAtAltitude(height, orb).
    if (orb:eta:apoapsis > orb:eta:periapsis and altitude > height) 
    or (orb:eta:apoapsis < orb:eta:periapsis and altitude < height) {
        return -angle.
    }
    return angle.
}

function eccentricAnomalyAtAltitude {
    parameter tAlt.
    parameter orb to orbit.

    if tAlt < periapsis or tAlt > apoapsis { return 0. }

    // r = a*(1-e cos(E))
    // r/a = 1 - e cos(E)
    // e cos(E) = 1 - r/a
    // cos(E) = (1 - r/a) / e
    // E = acos((1 - r/a) / e)

    local totalRadius to body:radius + tAlt.
    return arcCos((orb:semimajoraxis - totalRadius) / (orb:semimajoraxis * orb:eccentricity)).
}

function firstEccentricAnomalyAtAltitude {
    parameter tAlt.
    parameter orb to orbit.

    if tAlt < periapsis or tAlt > apoapsis { return 0. }

    local eccentricAnomaly to eccentricAnomalyAtAltitude(tAlt, orb).
    local currentEccentricAnomaly to trueToEccentricAnomaly(orb:trueanomaly).
    if currentEccentricAnomaly > eccentricAnomaly and currentEccentricAnomaly < 360 - eccentricAnomaly {
        return 360 - eccentricAnomaly.
    }
    return eccentricAnomaly.
}

function trueAnomalyAtAltitude {
    parameter tAlt.
    parameter orb to orbit.

    if tAlt < periapsis or tAlt > apoapsis { return 0. }

    // local timeAtAlt to timeAtAltitude(tAlt, orb).
    // local offsetOrb to offsetOrbit(timeAtAlt, orb).	
    // return offsetOrb:trueAnomaly.

    // r = a*(1-e^2) / (1 + e cos(tA))
    // 1 + e cos(tA) = a*(1-e^2) / r
    // e cos(tA) = a*(1-e^2) / r - 1
    // cos(tA) = (a*(1-e^2) / r - 1) / e
    // tA = acos((a*(1-e^2) / r - 1) / e)
    local a to orb:semimajoraxis.
    local e to orb:eccentricity.
    local totalRadius to orb:body:radius + tAlt.
    return arcCos((a * (1 - e^2) / totalRadius - 1) / e). // Not tested
}

function firstTrueAnomalyAtAltitude {
    parameter tAlt.
    parameter orb to orbit.

    if tAlt < periapsis or tAlt > apoapsis { return 0. }

    local trueAnomaly to trueAnomalyAtAltitude(tAlt, orb).
    local currentTrueAnomaly to orb:trueAnomaly.
    if currentTrueAnomaly > trueAnomaly and currentTrueAnomaly < 360 - trueAnomaly {
        return 360 - trueAnomaly.
    }
    return trueAnomaly.
}

function timeAtAltitude {
    parameter tAlt.
    parameter orb to orbit.

    if tAlt < periapsis {
        return eta:periapsis.
    } else if tAlt > apoapsis {
        return eta:apoapsis.
    }

    // local totalRadius to body:radius + tAlt.
    local eccentricAnomaly to eccentricAnomalyAtAltitude(tAlt, orb).
    local meanAnomaly to eccentricToMeanAnomaly(eccentricAnomaly, orb:eccentricity).
    local timeAtAlt to meanAnomalyToUTSeconds(meanAnomaly, orb).
    local otherTime to meanAnomalyToUTSeconds(rMod(-meanAnomaly, 360), orb).
    if timeAtAlt < time:seconds {
        set timeAtAlt to timeAtAlt + orb:period.
    }
    if otherTime < time:seconds {
        set otherTime to otherTime + orb:period.
    }
    // clearScreen.
    // print "timeToAltitude: " + (timeAtAlt - time:seconds) at (0, 0).
    // print "otherTime: " + (otherTime - time:seconds) at (0, 1).
    // print "Mean anomaly: " + meanAnomaly at (0, 2).
    // print "Other mean anomaly: " + rMod(-meanAnomaly, 360) at (0, 3).
    // print "Eccentric anomaly: " + eccentricAnomaly at (0, 4).
    // print "Eccentricity: " + orb:eccentricity at (0, 5).
    // print "Semi major axis: " + orb:semiMajorAxis at (0, 6).
    // print "Radius: " + totalRadius at (0, 7).
    // print "Period: " + orb:period at (0, 8).
    // print "Time to periapsis: " + orb:eta:periapsis at (0, 9).
    // print "Mean angular motion: " + 360 / orb:period at (0, 10).	
    // print "Periapsis: " + orb:periapsis at (0, 11).
    // print "Apoapsis: " + orb:apoapsis at (0, 12).
    // print "Time: " + time:seconds at (0, 13).
    // print "Time at altitude: " + timeAtAlt at (0, 14).
    // print "Other time: " + otherTime at (0, 15).
    // print "calc period: " + 2*(eta:apoapsis - eta:periapsis) at (0, 16).
    // print "ecc to mean: " + eccentricToMeanAnomaly(90) at (0, 17).
    // print "true to e: " + trueToEccentricAnomaly(90) at (0, 18).
    // print "mean 90: " + meanAnomalyToUTSeconds(90) at (0, 19).

    return min(timeAtAlt, otherTime).
}

function offsetOrbit {
    parameter t.
    parameter orb to orbit.
    local timeDiff to t - time:seconds.

    return createOrbit(
        orb:inclination,
        orb:eccentricity,
        orb:semimajoraxis,
        orb:longitudeofascendingnode,
        orb:argumentofperiapsis,
        orb:meananomalyatepoch,
        orb:epoch - timeDiff,
        orb:body
    ).
}

function orbitableVelocityAtTime {
    parameter t.
    parameter orb to orbit.
    return offsetOrbit(t, orb):velocity.
}

function positionAtTime {
    parameter t.
    parameter orb to orbit.
    return offsetOrbit(t, orb):position.
}

function trueToEccentricAnomaly {
    parameter trueAnomaly.
    parameter eccentricity to orbit:eccentricity.
    local eccentricAnomaly to arcTan2(-sqrt(1 - eccentricity^2) * sin(trueAnomaly), -eccentricity - cos(trueAnomaly)) + 180.
    return eccentricAnomaly.
}

function eccentricToMeanAnomaly {
    parameter eccentricAnomaly.
    parameter eccentricity to orbit:eccentricity.
    return eccentricAnomaly - (eccentricity * sin(eccentricAnomaly)) / constant:pi * 180 .
}

function trueToMeanAnomaly {
    parameter trueAnomaly.
    parameter eccentricity to orbit:eccentricity.
    local eccentricAnomaly to trueToEccentricAnomaly(trueAnomaly, eccentricity).
    return eccentricToMeanAnomaly(eccentricAnomaly, eccentricity).
}

function meanAnomalyToUTSeconds {
    parameter meanAnomaly.
    parameter orb to orbit.
    parameter meanAngularMotion to 360 / orb:period.
    parameter periapsisTime to lastPeriapsisTime(orb).
    return periapsisTime + (meanAnomaly / meanAngularMotion).

    // local meanAnAtEpoch to orbit:meananomalyatepoch.
    // local epoch to orbit:epoch.
    // local period to orbit:period.
    // return period / 360 * (meanAnomaly - meanAnAtEpoch) + epoch.
}

function trueAnomalyToUTSeconds {
    parameter trueAnomaly.
    parameter meanAngularMotion to 360 / orbit:period.
    parameter periapsisTime to lastPeriapsisTime().
    parameter eccentricity to orbit:eccentricity.
    return meanAnomalyToUTSeconds(trueToMeanAnomaly(trueAnomaly, eccentricity), meanAngularMotion, periapsisTime).
}

function eccentricAnomalyToUTSeconds {
    parameter eccentricAnomaly.
    parameter eccentricity to orbit:eccentricity.
    parameter meanAngularMotion to 360 / orbit:period.
    parameter periapsisTime to lastPeriapsisTime().
    return meanAnomalyToUTSeconds(eccentricToMeanAnomaly(eccentricAnomaly, eccentricity), meanAngularMotion, periapsisTime).
}

function lastPeriapsisTime {
    parameter orb to orbit.
    return time:seconds + orb:eta:periapsis - orb:period.
}

function lastApoapsisTime {
    parameter orb to orbit.
    return time:seconds + orb:eta:apoapsis - orb:period.
}
