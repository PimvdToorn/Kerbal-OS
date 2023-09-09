function dock {
    runPath("0:libraries/read_line").

    lock t to target.
    clearScreen.

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

        local x is 1.
        print "Available dockingports at ".
        for port in dockingPorts {
            print x + " - " + port:tag.
            set x to x+1.
        }

        print "Select dockingport: ".
        // local portNumber to str_to_num(terminal:input:getchar()).
        local portNumber to read_line():tonumber(1).

        lock t to dockingPorts[portNumber-1].

        print "Selected port " + portNumber + ": " + t:tag.
        wait 2.
    }

    if t:typename <> "DockingPort" {
        print "Target the desired docking port".
        wait 5.
        return.
    }

    SAS off.
    RCS on.

    clearScreen.
    print "Rotate in degrees: ".
    local rotation is read_line(19, 0):toNumber(0).

    print "Docking with a rotation of " + rotation + " degrees " + round(mod(t:facing:roll + rotation, 360), 2).
    print round(t:facing:pitch, 1) + " " + round(t:facing:yaw, 1).
    // lock steering to t:facing + r(t:facing:pitch + 180, t:facing:yaw + 180, mod(t:facing:roll + 180 + rotation, 360)).
    // lock steering to -t:facing:forevector + r(0, 0, rotation).
    // local f to -t.
    local rotatedVector to cos(rotation) * t:facing:upvector 
        + sin(rotation) * (vCrs(t:facing:upvector, -t:facing:vector))
        + (1 - cos(rotation)) * vDot(-t:facing:vector, t:facing:upvector) * -t:facing:vector.

    lock steering to lookDirUp(-t:facing:vector, rotatedVector).

    until vdot(ship:facing:forevector, -t:facing:vector) > 0.99 wait 1.
    wait 2.
    until vdot(ship:facing:forevector, -t:facing:vector) > 0.99 wait 1.

    set dockingPort to ship:controlpart.

    if dockingPort:typename <> "DockingPort" {
        print "Set controlpoint to the dockingport".
        wait 5.
        return.
    }

    lock relativeVector to t:position - dockingPort:position.

    set targetFacingVector to vecDraw(
        { return t:position. }, 
        { return 3*t:facing:vector. }
        ).
    set targetFacingVector:show to true.

    set differenceVector to vecDraw(
        { return dockingPort:position. }, 
        { return relativeVector. },
        rgb(1,0,1)
        ).
    set differenceVector:show to true.

    set upVector to dockingPort:facing:upVector.
    set upVectorDraw to vecDraw(
        { return dockingPort:position. },
        { return 3*upVector. }, 
        rgb(0,0,1)
        ).
    set upVectorDraw:show to true.

    set rightVector to dockingPort:facing:rightVector.
    set rightVectorDraw to vecDraw(
        { return dockingPort:position. },
        { return 3*rightVector. }, 
        rgb(0,1,0)
        ).
    set rightVectorDraw:show to true.

    // set forwardVector to -t:facing:vector.

    lock forwardDistanceVector to relativeVector - vdot(relativeVector, upVector) * upVector - vdot(relativeVector, rightVector) * rightVector.
    set forwardDistanceVectorDraw to vecDraw(
        { return dockingPort:position. },
        { return forwardDistanceVector. },
        rgb(1,0,1)
    ).
    set forwardDistanceVectorDraw:show to true.

    lock movementVector to -(t:ship:velocity:orbit - ship:velocity:orbit).
    set movementVectorDraw to vecDraw(
        { return dockingPort:position. }, 
        { return 5*movementVector. }, 
        rgb(1,0,0)
        ).
    set movementVectorDraw:show to true.

    set desiredMovementVector to v(0,0,0).
    set desiredMovementVectorDraw to vecDraw(
        { return dockingPort:position. }, 
        { return 5*desiredMovementVector. }, 
        rgb(1,1,0)
        ).
    set desiredMovementVectorDraw:show to true.

    lock accelerationVector to desiredMovementVector - movementVector.
    set accelerationVectorDraw to vecDraw(
        { return dockingPort:position. }, 
        { return 5*accelerationVector. }, 
        rgb(1,1,1)
        ).
    set accelerationVectorDraw:show to true.

    set translationScalar to 5.
    // set trVec to {
    //     local vec to translationScalar*v(
    //         -accelerationVector:z,
    //         -accelerationVector:x,
    //         -accelerationVector:y
    //     ).

    //     // if abs(vec:z) > 0.01 set vec:z to 0.05.
    //     // if abs(vec:y) > 0.05 set vec:z to 0.
    //     // else if abs(vec:y) > 0.01 set vec:y to 0.05.
    //     // if abs(vec:x) > 0.05 set vec:y to 0.
    //     // else if abs(vec:x) > 0.01 set vec:x to 0.05.

    //     return vec.
    // }.
    lock translationVector to translationScalar*v(
        vDot(accelerationVector, rightVector),
        vDot(accelerationVector, upVector),
        vDot(accelerationVector, -t:facing:vector)
    ).

    set translationVectorDraw to vecDraw(
        { return dockingPort:position. },
        { return 5*v(translationVector:z, translationVector:y, translationVector:z). },
        rgb(0.5,1,0) 
    ).
    set translationVectorDraw:show to true.

    clearScreen.

    set forwardDistance to max(10, min(forwardDistanceVector:mag, 300)).

    set maxVelocity to 0.5.
    if relativeVector:mag > 50 set maxVelocity to 3.
    else if relativeVector:mag > 20 set maxVelocity to 1.

    print "[Q] cancel" at (0, 36).

    function everyLoop {
        set ship:control:translation to v(0,0,0).

        if terminal:input:hasChar if terminal:input:getChar():toLower = "q" {
            unlock all.
            return.
        }
        // set input to "".
        // if terminal:input:haschar {
        //     set input to terminal:input:getChar().
        //     print "Reading char " + input + " " + input:tolower() at (0, 34).
        //     // if input:toLower() = "q" {
        //     //     return.
        //     // }
        // }

        // set t to target.

        if dockingPort:haspartner or t:typename <> "DockingPort" or input:tolower() = "q" {
            unset targetFacingVector.
            unset differenceVector.
            unset upVectorDraw.
            unset rightVectorDraw.
            unset forwardDistanceVectorDraw.
            unset movementVectorDraw.
            unset desiredMovementVectorDraw.
            unset accelerationVectorDraw.
            unset translationVectorDraw.
            
            unlock translationVector.
            unlock accelerationVector.
            unlock movementVector.
            unlock forwardDistanceVector.
            unlock relativeVector.

            unlock all.

            // set targetFacingVector:show to false.
            // set differenceVector:show to false.
            // set upVectorDraw:show to false.
            // set rightVectorDraw:show to false.
            // set forwardDistanceVectorDraw:show to false.
            // set movementVectorDraw:show to false.
            // set desiredMovementVectorDraw:show to false.
            // set accelerationVectorDraw:show to false.
            // set translationVectorDraw:show to false.

            clearScreen.
            return.
        }

        if (desiredMovementVector:mag > maxVelocity) set desiredMovementVector:mag to maxVelocity.
        // set translationScalar to 1/sqrt(accelerationVector:mag).
        // print (desiredMovementVector - movementVector):mag at (0,12).

        set ship:control:translation to translationVector.
        print "Right: " + round(translationVector:x, 2) + "             " at (0,0).
        print "Up: " + round(translationVector:y, 2) + "             " at (0,1).
        print "Forward: " + round(translationVector:z, 2) + "             " at (0,2).

        if accelerationVector:mag < 6 
            set ship:control:translation to v(0,0,0).

        // print desiredMovementVector + "                          " at (0, 4).
        // print accelerationVector + "                         " at (0, 6).
        // print translationVector + "                          " at (0, 8).  

        // print vdot(relativeVector, upVector) + "          " at (0, 0).
        // print vdot(relativeVector, rightVector) + "          " at (0, 1).
        // print vdot(forwardDistanceVector, -t:facing:vector) + "          " at (0, 2).

        
    }

    print "Canceling relative momentum" at (0,10).

    until false {
        set desiredMovementVector to V(0,0,0).

        if (desiredMovementVector:mag < 0.1 and movementVector:mag < 0.1) break.

        everyLoop().
    }

    print "Aligning forward              " at (0,10).

    until false {
        local distance to abs(forwardDistanceVector:mag - forwardDistance).
        
        if distance > 100 set maxVelocity to 8.
        else if distance > 50 set maxVelocity to 3.
        else if distance > 20 set maxVelocity to 1.
        else if distance > 5 set maxVelocity to 0.5.
        else set maxVelocity to 0.2.

        set desiredMovementVector to 
            // (vdot(forwardDistanceVector, -t:facing:vector) - forwardDistance) * -t:facing:vector/10.
            (forwardDistanceVector:mag - forwardDistance) * -t:facing:vector.

        if desiredMovementVector:mag < 0.1 and movementVector:mag < 0.1 break.

        everyLoop().
    }

    print "Aligning up and right           " at (0,10).
    // set maxVelocity to 0.5.

    until false {
        local distance to sqrt(vDot(rightVector, relativeVector)^2 + vDot(upVector, relativeVector)^2).
        
        if distance > 100 set maxVelocity to 8.
        else if distance > 50 set maxVelocity to 3.
        else if distance > 20 set maxVelocity to 1.
        else if distance > 7 set maxVelocity to 0.5.
        else set maxVelocity to 0.2.
        
        set desiredMovementVector to 
            (vdot(forwardDistanceVector, -t:facing:vector) - forwardDistance) * -t:facing:vector
            + vDot(rightVector, relativeVector) * rightVector
            + vDot(upVector, relativeVector) * upVector.

        if desiredMovementVector:mag < 0.2 and movementVector:mag < 0.2 break.
        
        everyLoop().
    }

    print "--------------------               " at (0,10).
    set forwardDistance to 10.
    // set maxVelocity to 0.25.

    until false {
            
        set desiredMovementVector to  
            (vdot(forwardDistanceVector, -t:facing:vector) - forwardDistance) * -t:facing:vector
            + vDot(rightVector, relativeVector) * rightVector
            + vDot(upVector, relativeVector) * upVector.

        if desiredMovementVector:mag < 0.1 and movementVector:mag < 0.1 {
            set forwardDistance to 0.
            set maxVelocity to 0.25.
        }

        

        everyLoop().
    }
}
