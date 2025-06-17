function steerPlane {
    parameter maxAngleOfAttack.
    parameter targetClimb.
    parameter targetHead.
    parameter targetHorizonRoll to 0.
    parameter pitchStrength to 3.
    parameter yawStrength to 3.
    parameter rollStrength to 3.
    
    // Pitch
    local progradePitch to getPitch(prograde:vector).

    local maxPitch to progradePitch + maxAngleOfAttack.
    local minPitch to progradePitch - maxAngleOfAttack.
    local differencePitch to targetClimb - progradePitch.

    local tPitch to max(minPitch, min(maxPitch, getPitch() + differencePitch * pitchStrength)).

    // Heading
    local differenceHeading to targetHead - getHeading().
    local tHead to targetHead + differenceHeading * yawStrength.
    // print "Heading change to: " + tHead + "                                 " at (0, 20).
    // Also harder steer for head and roll, e.g. head is 92, target 90, steer 88/86 etc

    // Roll
    local differenceRoll to targetHorizonRoll - getHorizonRoll().
    local tHorRoll to targetHorizonRoll + min(-180, max(180, differenceRoll * rollStrength)).
    print "Roll change to: " + tHorRoll + "                                 " at (0, 18).

    // Translate horizon roll to euler roll

    // lock steering to heading(tHead, tPitch, tHorRoll).
    lock steering to heading(tHead, tPitch, 0).
    // print "Pitch change to: " + tPitch  + "                                 " at (0, 16).
}

function eastVector {
    return vcrs(ship:north:vector, ship:up:vector):normalized.
}

function normalVector {
    parameter velVec to velocity:orbit.
    parameter bdy to body.
    return vcrs(bdy:position, velVec):normalized.
}

function radialVector {
    parameter velVec to velocity:orbit.
    parameter bdy to body.
    return vcrs(normalVector(velVec, bdy), velVec):normalized.
}

function progradeVector {
    parameter velVec to velocity:orbit.
    return velVec:normalized.
}

function getPitch {
    parameter forwardV to facing:vector.
    return -vectorAngle(ship:up:vector, forwardV) + 90.
}

function getHeading {
    parameter forwardV to facing:vector.
    local upV to ship:up:vector.
    
    // project the forward vector onto the horizontal plane
    local proj_forward to forwardV - ((forwardV * upV) * upV).
    set proj_forward to proj_forward:normalized.
    
    local north_vec to ship:north:vector.
    local east_vec to eastVector().
    
    // calculate horizontal components of proj_forward via dot products
    local north_component to proj_forward * north_vec.
    local east_component to proj_forward * east_vec.
    
    // compute heading in degrees using arctan2(east_component, north_component)
    local heading_degrees to arctan2(east_component, north_component).
    
    // normalize heading to 0-360 degrees
    if heading_degrees < 0 {
        set heading_degrees to abs(heading_degrees).
    } else {
        set heading_degrees to 360 - heading_degrees.
    }
    
    // print "calculated heading: " + heading_degrees.
    return heading_degrees.
}

function getHorizonRoll {
    local angleTopAndUp to vectorAngle(ship:up:vector, ship:facing:topvector).
    local angleStarAndUp to vectorAngle(ship:up:vector, ship:facing:starvector).

    if angleStarAndUp < 90 {
        return 360-angleTopAndUp.
    }
    return angleTopAndUp - getPitch().
}

// Convert from Euler roll (ship:facing:roll) to horizon roll
// (i.e. the roll if pitch were projected out to zero)
function getHorizonRollFromEuler {
    parameter eulerRoll to facing:roll.
    local pitch to getPitch().
    local horizonRoll to arctan( tan(eulerRoll) * cos(pitch) ).
    return horizonRoll.
}

// Convert from horizon roll (roll with pitch removed) to Euler roll (ship:facing:roll)
function getEulerRollFromHorizon {
    parameter horizonRoll.
    local upV to ship:up:vector.
    local northV to ship:north:vector.
    // local pitch to getPitch().
    local upYAngle to vectorAngle(upV, v(0, 1, 0)).
    local upXAngle to vectorAngle(upV, v(1, 0, 0)).
    local northXAngle to vectorAngle(northV, v(1, 0, 0)).
    print "upYAngle: " + upYAngle + "       " at (0, 10).
    print "northXAngle: " + northXAngle + "       " at (0, 11).
    print "upXAngle: " + upXAngle + "       " at (0, 12).
    local eulerRoll to rMod(horizonRoll + upYAngle, 360).
    return eulerRoll.
}

function getAoA {
    return getPitch() - getPitch(prograde:vector).
}

function maxDegreeChange_0_360 {
    parameter current, targ, maxChange.

    // turn left / down
    if targ < current and targ > current - 180 {
        return max(targ, current - maxChange).
    }
    if targ > current + 180 {
        local change to rMod(current - maxChange, 360). 
        if change < targ and change > current {
            return targ.
        }
        return change.
    }

    // turn right / up
    if targ > current {
        return min(targ, current + maxChange). 
    }
    local change to mod(current + maxChange, 360).
    if change > targ and change < current {
        return targ.
    }
    return change.
}

function maxDegreeChange_90_90 {
    parameter current, targ, maxChange.

    if targ > current {
        return min(targ, current + maxChange).
    }
    return max(targ, current - maxChange).
}

function waitAlignment {
    parameter vector.
    until vdot(ship:facing:forevector, vector) > 0.99 wait 1.
    wait 2.
    until vdot(ship:facing:forevector, vector) > 0.99 wait 1. 
}

function waitAlignmentDirection {
    parameter direction.
    until vdot(ship:facing:forevector, direction:vector) > 0.99 and ship:angularvel:mag < 0.01 wait 1.
    // wait 2.
    // until vdot(ship:facing:forevector, direction:vector) > 0.99 wait 1. 
}
