@lazyGlobal off.
runOncePath("0:libraries/read_line").
runOncePath("0:libraries/utils/utils").

function maxVelocity {
    parameter distance.
    if distance > 100 return 8.
    else if distance > 50 return 3.
    else if distance > 20 return 1.
    else if distance > 5 return 0.5.
    else if distance > 1 return 0.2.
    else return 0.05.
}

function dock {
    clearScreen.
    set readingInput to false.

    if not hasTarget {
        print "Error: Set a target".
        print " ".
        print "Press any key to exit".
        terminal:input:getchar().
        return.
    }

    local t to target.
    local dockingPort to ship:controlpart.

    if dockingPort:typename <> "DockingPort" {
        print "Error: Set controlpoint to the dockingport".
        print " ".
        print "Press any key to exit".
        terminal:input:getchar().
        return.
    }

    if t:istype("Vessel") {
        local dockingPorts to t:dockingports:copy.

        if dockingPorts:length = 0 {
            print "Target has no dockingports".
            return.
        }

        local dockedPorts to list().
        for port in dockingPorts {
            if port:haspartner {
                dockedPorts:add(port).
            }
        }
        for port in dockedPorts {
            dockingPorts:remove(dockingPorts:find(port)).
        }

        print "Select dockingport: ".
        print " ".

        local x is 1.
        print "Available dockingports".
        for port in dockingPorts {
            print "[" + x + "] - " + port:tag.
            set x to x+1.
        }

        local portNumber to readLine(20, 0):tonumber(1).

        set t to dockingPorts[portNumber-1].
    }

    if t:typename <> "DockingPort" {
        print "Error: Target the desired docking port".
        print " ".
        print "Press any key to exit".
        terminal:input:getchar().
        return.
    }

    SAS off.
    RCS on.

    //--------------------------------------------------------------------------------------------

    function relativeVector { return t:position - dockingPort:position. }

    function upVector { return dockingPort:facing:upVector. }
    function rightVector { return dockingPort:facing:rightVector. }
    function forwardVector { return -t:facing:vector. }

    function forwardDistanceVector {
        return relativeVector() - vdot(relativeVector(), upVector()) * upVector() - vdot(relativeVector(), rightVector()) * rightVector().
    }

    function movementVector { return -(t:ship:velocity:orbit - ship:velocity:orbit). } 
    local desiredMovementVector to v(0,0,0).

    function accelerationVector { return desiredMovementVector - movementVector(). }
    local translationScalar to 5.
    local lock translationVector to translationScalar*v(
        vDot(accelerationVector(), rightVector()),
        vDot(accelerationVector(), upVector()),
        vDot(accelerationVector(), forwardVector())
    ).

    local distance to 0.
    local maxVelocityMultiplier to 1.
    local rotation to 0.
    local forwardDistance to max(2, min(forwardDistanceVector():mag, 200)).

    local CANCEL_MOMENTUM to 1.
    local ALIGN_FORWARD_DISTANCE to 2.
    local ALIGN_SIDE_AND_UP to 3.
    local APPROACH to 4.
    local CHANGE_ROTATION to 5.

    local mode to CANCEL_MOMENTUM.
    local modeOverride to 0.

    //--------------------------------------------------------------------------------------------

    function draw {
        clearScreen.
        local m to choose mode if modeOverride = 0 else modeOverride.
        local modeString to "Mode: ".
        if      m = CANCEL_MOMENTUM         set modeString to modeString + "Canceling relative momentum".
        else if m = ALIGN_FORWARD_DISTANCE  set modeString to modeString + "Aligning forward".
        else if m = ALIGN_SIDE_AND_UP       set modeString to modeString + "Aligning sideways and up/down".
        else if m = APPROACH                set modeString to modeString + "Approaching".

        drawHud(list(
            modeString,
            "-------------------------------------",
            "Target           : " + t:tag,
            "Rotation         : " + rotation,
            "Dist waypoint    : " + distance,
            "-------------------------------------",
            "[W/S] Change max velocity multiplier: " + round(maxVelocityMultiplier,1),
            "         ------------------",
            "         |Distance|Max vel|",
            "         |----------------|",
            "         |  >100  |  8.11 |",
            "         |  <100  |  8.11 |",
            "         |  <50   |  8.11 |",
            "         |  <20   |  8.11 |",
            "         |  <5    |  8.11 |",
            "         |  <1    |  8.11 |",
            "         ------------------",
            "Max velocity: "
        )).

        drawHud(list(
            round(maxVelocity(101)*maxVelocityMultiplier, 2) + "   ",
            round(maxVelocity(99)*maxVelocityMultiplier, 2) + "   ",
            round(maxVelocity(49)*maxVelocityMultiplier, 2) + "   ",
            round(maxVelocity(19)*maxVelocityMultiplier, 2) + "   ",
            round(maxVelocity(4)*maxVelocityMultiplier, 2) + "   ",
            round(maxVelocity(0.9)*maxVelocityMultiplier, 2) + "   "
        ), 21, 10).

        drawHud(list(
            "|",
            "|",
            "|",
            "|",
            "|",
            "|"
        ), 26, 10).

        drawHud(list(
            "[R] change rotation", 
            "[Q] cancel docking"
        ), 0, 34).
    }
    draw().

    function setRotation {
        parameter alignWait to false.

        local rotatedVector to cos(rotation) * t:facing:upvector 
            + sin(rotation) * (vCrs(t:facing:upvector, -t:facing:vector))
            + (1 - cos(rotation)) * vDot(-t:facing:vector, t:facing:upvector) * -t:facing:vector.

        lock steering to lookDirUp(-t:facing:vector, rotatedVector).

        if alignWait {
            print "Aligning heading and rotation         " at (0,0).
            until vdot(ship:facing:forevector, forwardVector) > 0.99 wait 1.
            wait 2.
            until vdot(ship:facing:forevector, forwardVector) > 0.99 wait 1. 
        }
    }
    setRotation(true).

    function changeRotation {
        if modeOverride <> CHANGE_ROTATION {
            set modeOverride to CHANGE_ROTATION.
            print "<Set rotation>" at (0,3).
        }

        set rotation to readLineNonBlocking(19, 3).
        if rotation = terminal:input:return return.

        set rotation to rotation:toNumber(0).
        setRotation(true).

        set modeOverride to 0.
        draw().
        everyLoop().
    }

    function drawVecs {
        local targetFacingVector to vecDraw(
            { return t:position. }, 
            { return 3*t:facing:vector. }
            ).
        set targetFacingVector:show to true.

        local differenceVector to vecDraw(
            { return dockingPort:position. }, 
            { return relativeVector(). },
            rgb(1,0,1)
            ).
        set differenceVector:show to true.

        local upVectorDraw to vecDraw(
            { return dockingPort:position. },
            { return 3*upVector(). }, 
            rgb(0,0,1)
            ).
        set upVectorDraw:show to true.

        local targetUpVectorDraw to vecDraw(
            { return t:position. },
            { return 3*t:facing:upVector. }, 
            rgb(0,0,1)
            ).
        set targetUpVectorDraw:show to true.

        // local rightVectorDraw to vecDraw(
        //     { return dockingPort:position. },
        //     { return 3*rightVector. }, 
        //     rgb(0,1,0)
        //     ).
        // set rightVectorDraw:show to true.

        local forwardDistanceVectorDraw to vecDraw(
            { return dockingPort:position. },
            { return forwardDistanceVector(). },
            rgb(1,0,1)
        ).
        set forwardDistanceVectorDraw:show to true.

        local movementVectorDraw to vecDraw(
            { return dockingPort:position. }, 
            { return 5*movementVector(). }, 
            rgb(1,0,0)
            ).
        set movementVectorDraw:show to true.

        local desiredMovementVectorDraw to vecDraw(
            { return dockingPort:position. }, 
            { return 5*desiredMovementVector. }, 
            rgb(1,1,0)
            ).
        set desiredMovementVectorDraw:show to true.

        local accelerationVectorDraw to vecDraw(
            { return dockingPort:position. }, 
            { return 5*accelerationVector(). }, 
            rgb(1,1,1)
            ).
        set accelerationVectorDraw:show to true.
    }
    drawVecs().

    function quit {
        unlock all.
        clearVecDraws().
        set ship:control:translation to v(0,0,0).
        set ship:control:neutralize to true.
        clearScreen.
        print "Quitting" at (0,0).
        wait 2.
    }


    function everyLoop {
        if terminal:input:haschar and not readingInput {
            local input to terminal:input:getChar():tolower.
            terminal:input:clear().

            if input = "r" {
                set distance to 0.
                set desiredMovementVector to V(0,0,0).
                changeRotation().
            }
            else if input = "q" {
                quit().
                return 1.
            }
            else if input = "w" {
                set maxVelocityMultiplier to maxVelocityMultiplier + 0.25.
                draw().
            }
            else if input = "s" {
                set maxVelocityMultiplier to maxVelocityMultiplier - 0.25.
                draw().
            }
        }

        local m to choose mode if modeOverride = 0 else modeOverride.
        if m = CANCEL_MOMENTUM {
            
        }
        else if m = ALIGN_FORWARD_DISTANCE {
            set distance to abs(vdot(forwardDistanceVector, forwardVector) - forwardDistance).
            set desiredMovementVector to 
                (vdot(forwardDistanceVector, forwardVector) - forwardDistance) * forwardVector.
        }
        else if m = ALIGN_SIDE_AND_UP {
            set distance to sqrt(vDot(rightVector, relativeVector)^2 + vDot(upVector, relativeVector)^2).
            set desiredMovementVector to 
                (vdot(forwardDistanceVector, forwardVector) - forwardDistance) * forwardVector
                + vDot(rightVector, relativeVector) * rightVector * 10
                + vDot(upVector, relativeVector) * upVector * 10.
        }
        else if m = APPROACH {
            set distance to relativeVector:mag.
            set desiredMovementVector to  
                (vdot(forwardDistanceVector, forwardVector) - forwardDistance) * forwardVector
                + vDot(rightVector, relativeVector) * rightVector * 10
                + vDot(upVector, relativeVector) * upVector * 10.
        }
        else if m = CHANGE_ROTATION {
            changeRotation().
        }

        print round(distance, 1) + "m     " at (19,4).

        if (desiredMovementVector:mag > (maxVelocity(distance)*maxVelocityMultiplier)) set desiredMovementVector:mag to maxVelocity(distance)*maxVelocityMultiplier.
        print round(desiredMovementVector:mag, 2) + "m/s        " at (14,17).

        if m <> CHANGE_ROTATION {
            setRotation().
        }

        set ship:control:translation to translationVector.

        return 0.
    }

    set mode to CANCEL_MOMENTUM.
    draw().
    set distance to 0.
    set desiredMovementVector to V(0,0,0).

    until distance < 1 and abs(desiredMovementVector:mag - movementVector():mag) < 0.1 and modeOverride = 0 { 
        if everyLoop() = 1 return 1. 
    }

    set mode to ALIGN_FORWARD_DISTANCE.
    draw().
    everyLoop().

    until distance < 1 and abs(desiredMovementVector:mag - movementVector():mag) < 0.1 and modeOverride = 0 {
        if everyLoop() = 1 return.
    }

    set mode to ALIGN_SIDE_AND_UP.
    draw().
    everyLoop().

    until distance < 1 and abs(desiredMovementVector:mag - movementVector():mag) < 0.1 and modeOverride = 0 {
        if everyLoop() = 1 return.
    }

    set mode to APPROACH.
    set forwardDistance to 0.
    draw().
    everyLoop().

    // until distance < 0.2 and abs(desiredMovementVector:mag - movementVector():mag) < 0.1 and modeOverride = 0 {
    until dockingPort:haspartner and modeOverride = 0 {
        if everyLoop() = 1 return.
    }
    quit().
}
