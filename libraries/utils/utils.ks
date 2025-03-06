@lazyGlobal off.

function rMod {
    parameter a, b.
    if a < 0 { return b + mod(a, b). }
    return mod(a, b).
}

function drawHud {
    parameter text.
    parameter widthOffset to 0.
    parameter heightOffset to 0.

    local lines to text:length().
    for i in range(lines) {

        print text[i]:padRight(terminal:width - widthOffset) at (0 + widthOffset, i + heightOffset).
    }
}

function getPitch {
    parameter forwardV to facing:vector.
    return -vectorAngle(ship:up:vector, forwardV) + 90.
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

function getHeading {
    parameter forwardV to facing:vector.
    local upV to ship:up:vector.
    
    // project the forward vector onto the horizontal plane
    local proj_forward to forwardV - ((forwardV * upV) * upV).
    set proj_forward to proj_forward:normalized.
    
    local north_vec to ship:north:vector.
    
    // compute east vector using vector cross (north_vec x upV yields east)
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

// function getRoll {
//     local forward to ship:facing:vector.
//     local upV to ship:up:vector.
    
//     // Compute the ship's right vector (perpendicular to forward and up)
//     local right_vec to vcrs(forward, upV):normalized.
    
//     // Compute the horizon's right vector (perpendicular to forward and planet up)
//     local horizon_right_vec to vcrs(forward, ship:body:up:vector):normalized.
    
//     // Compute roll components using dot products
//     local roll_component_x to right_vec * horizon_right_vec.
//     local roll_component_y to vcrs(right_vec, horizon_right_vec) * forward.
    
//     // Compute roll angle in degrees
//     local roll_degrees to arctan2(roll_component_y, roll_component_x).
    
//     // // Normalize to -180 to 180 range
//     // if roll_degrees > 180 {
//     //     set roll_degrees to roll_degrees - 360.
//     // }
    
//     // print "calculated roll: " + roll_degrees.
//     return roll_degrees.
// }

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

function format {
    parameter number.
    // parameter decimals to 0.
    local str to "".
    local negator to "".

    if number < 0 {
        set negator to "-".
        set number to abs(number).
    }

    until number < 1 {
        local num to mod(number, 1000) + "".
        set num to num:padLeft(3):replace(" ", "0").
        set str to num + "." + str.
        set number to number / 1000.
    }
    set str to negator + str.
    return str:substring(0, str:length - 1). // remove trailing dot
}

function maxAcceleration {
    return ship:availablethrust / ship:mass.
}