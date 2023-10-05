@lazyGlobal off.
runOncePath("0:libraries/read_line").

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
    local lock dockingPort to ship:controlpart.

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

        local portNumber to read_line(20, 0):tonumber(1).

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

    local lock relativeVector to t:position - dockingPort:position.

    local lock upVector to dockingPort:facing:upVector.
    local lock rightVector to dockingPort:facing:rightVector.
    local lock forwardVector to -t:facing:vector.
    local lock forwardDistanceVector to relativeVector - vdot(relativeVector, upVector) * upVector - vdot(relativeVector, rightVector) * rightVector.

    local lock movementVector to -(t:ship:velocity:orbit - ship:velocity:orbit).
    local desiredMovementVector to v(0,0,0).

    local lock accelerationVector to desiredMovementVector - movementVector.
    local translationScalar to 5.
    local lock translationVector to translationScalar*v(
        vDot(accelerationVector, rightVector),
        vDot(accelerationVector, upVector),
        vDot(accelerationVector, forwardVector)
    ).

    local distance to 0.
    local maxVelocity to 1.
    local maxVelocityMultiplier to 1.
    local rotation to 0.
    local forwardDistance to max(10, min(forwardDistanceVector:mag, 200)).

    local CANCEL_MOMENTUM to 1.
    local ALIGN_FORWARD_DISTANCE to 2.
    local ALIGN_SIDE_AND_UP to 3.
    local APPROACH to 4.
    local CHANGE_ROTATION to 5.

    local mode to CANCEL_MOMENTUM.
    local modeOverride to 0.

    //--------------------------------------------------------------------------------------------

    function drawHUD {
        clearScreen.
        local m to choose mode if modeOverride = 0 else modeOverride.
        if      m = CANCEL_MOMENTUM         print "Canceling relative momentum  " at (0,0).
        else if m = ALIGN_FORWARD_DISTANCE  print "Aligning forward             " at (0,0).
        else if m = ALIGN_SIDE_AND_UP       print "Aligning sideways and up/down" at (0,0).
        else if m = APPROACH                print "Approaching                  " at (0,0).

        print "---------------------------------------------" at (0,1).
        print "Target                : " + t:tag at (0,2).
        print "Rotation              : " + rotation at (0,3).
        print "Distance nxt waypoint : " at (0,4).
        print "---------------------------------------------" at (0,5).
        print "[W/S] Change max velocity multiplier: " + round(maxVelocityMultiplier,1) at (0,6).
        print "------------------" at (0,7).
        print "|Distance|Max vel|" at (0,8).
        print "|----------------|" at (0,9).
        print "|  >100  |  8.11 |" at (0,10).
        print "|  >50   |  8.11 |" at (0,11).
        print "|  >20   |  8.11 |" at (0,12).
        print "|  >5    |  8.11 |" at (0,13).
        print "|  >1    |  8.11 |" at (0,14).
        print "|  -     |  8.11 |" at (0,15).
        print "------------------" at (0,16).
        print round(8*maxVelocityMultiplier, 2) + "   " at (12,10).
        print round(3*maxVelocityMultiplier, 2) + "   " at (12,11).
        print round(1*maxVelocityMultiplier, 2) + "   " at (12,12).
        print round(0.5*maxVelocityMultiplier, 2) + "   " at (12,13).
        print round(0.2*maxVelocityMultiplier, 2) + "   " at (12,14).
        print round(0.05*maxVelocityMultiplier, 2) + "   " at (12,15).
        print "|" at (17,10).
        print "|" at (17,11).
        print "|" at (17,12).
        print "|" at (17,13).
        print "|" at (17,14).
        print "|" at (17,15).

        print "[R] change rotation" at (0, 34).
        print "[Q] cancel docking" at (0, 35).
    }
    drawHUD().

    function changeRotation {
        if modeOverride <> CHANGE_ROTATION {
            set modeOverride to CHANGE_ROTATION.
            print "<Set rotation>" at (0,3).
        }

        set rotation to read_line_non_blocking(29, 3).
        if rotation = terminal:input:return return.

        set rotation to rotation:toNumber(0).

        local rotatedVector to cos(rotation) * t:facing:upvector 
            + sin(rotation) * (vCrs(t:facing:upvector, -t:facing:vector))
            + (1 - cos(rotation)) * vDot(-t:facing:vector, t:facing:upvector) * -t:facing:vector.

        lock steering to lookDirUp(-t:facing:vector, rotatedVector).

        set modeOverride to 0.
        drawHUD().
    }

    lock steering to forwardVector.
    print "Aligning heading              " at (0,0).
    until vdot(ship:facing:forevector, forwardVector) > 0.99 wait 1.
    wait 2.
    until vdot(ship:facing:forevector, forwardVector) > 0.99 wait 1. 

    local targetFacingVector to vecDraw(
        { return t:position. }, 
        { return 3*t:facing:vector. }
        ).
    set targetFacingVector:show to true.

    local differenceVector to vecDraw(
        { return dockingPort:position. }, 
        { return relativeVector. },
        rgb(1,0,1)
        ).
    set differenceVector:show to true.

    local upVectorDraw to vecDraw(
        { return dockingPort:position. },
        { return 3*upVector. }, 
        rgb(0,0,1)
        ).
    set upVectorDraw:show to true.

    local rightVectorDraw to vecDraw(
        { return dockingPort:position. },
        { return 3*rightVector. }, 
        rgb(0,1,0)
        ).
    set rightVectorDraw:show to true.

    local forwardDistanceVectorDraw to vecDraw(
        { return dockingPort:position. },
        { return forwardDistanceVector. },
        rgb(1,0,1)
    ).
    set forwardDistanceVectorDraw:show to true.

    local movementVectorDraw to vecDraw(
        { return dockingPort:position. }, 
        { return 5*movementVector. }, 
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
        { return 5*accelerationVector. }, 
        rgb(1,1,1)
        ).
    set accelerationVectorDraw:show to true.

    function quit {
        wait 3.
        CLEARVECDRAWS().
        set ship:control:translation to v(0,0,0).
        unlock steering.
        set ship:control:neutralize to true.
    }

    when dockingPort:haspartner then {
        quit().
        return.
    }

    function everyLoop {
        // set ship:control:translation to v(0,0,0).

        print readingInput at (0,25).
        if terminal:input:haschar and not readingInput {
            local input to terminal:input:getChar().
            terminal:input:clear().

            if input:tolower = "r" {
                set distance to 0.
                set desiredMovementVector to V(0,0,0).
                changeRotation().
            }
            else if input:tolower = "q" {
                quit().
                return 1.
            }
            else if input:tolower = "w" {
                set maxVelocityMultiplier to maxVelocityMultiplier + 0.1.
                drawHUD().
            }
            else if input:tolower = "s" {
                set maxVelocityMultiplier to maxVelocityMultiplier - 0.1.
                drawHUD().
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
            set distance to abs(forwardDistanceVector:mag - forwardDistance).
            set desiredMovementVector to  
                (vdot(forwardDistanceVector, forwardVector) - forwardDistance) * forwardVector
                + vDot(rightVector, relativeVector) * rightVector * 10
                + vDot(upVector, relativeVector) * upVector * 10.
        }
        else if m = CHANGE_ROTATION {
            changeRotation().
        }

        print round(distance, 1) + "m     " at (24,4).

        if distance > 100 set maxVelocity to 8.
        else if distance > 50 set maxVelocity to 3.
        else if distance > 20 set maxVelocity to 1.
        else if distance > 5 set maxVelocity to 0.5.
        else if distance > 1 set maxVelocity to 0.2.
        else set maxVelocity to 0.05.

        if (desiredMovementVector:mag > (maxVelocity*maxVelocityMultiplier)) set desiredMovementVector:mag to maxVelocity*maxVelocityMultiplier.
        // set translationScalar to 1/sqrt(accelerationVector:mag).

        set ship:control:translation to translationVector.

        return 0.
    }

    set mode to CANCEL_MOMENTUM.
    drawHUD().
    set distance to 0.
    set desiredMovementVector to V(0,0,0).

    until desiredMovementVector:mag < 0.1 and movementVector:mag < 0.1 and modeOverride = 0 { 
        if everyLoop() = 1 return 1. 
    }

    set mode to ALIGN_FORWARD_DISTANCE.
    drawHUD().
    everyLoop().

    until desiredMovementVector:mag < 0.1 and movementVector:mag < 0.1 and modeOverride = 0 {
        if everyLoop() = 1 return.
    }

    set mode to ALIGN_SIDE_AND_UP.
    drawHUD().
    everyLoop().

    until desiredMovementVector:mag < 0.1 and movementVector:mag < 0.1 and modeOverride = 0 {
        if everyLoop() = 1 return.
    }

    set mode to APPROACH.
    set forwardDistance to 0.
    drawHUD().
    everyLoop().

    until desiredMovementVector:mag < 0.1 and movementVector:mag < 0.1 and modeOverride = 0 {
        if everyLoop() = 1 return.
    }
}
