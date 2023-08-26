function dock {
    parameter t is target.

    if not t:typename = "DockingPort" {
        print "Target the desired docking port".
        return.
    }

    SAS off.
    lock steering to -t:facing:vector.

    until vdot(ship:facing:forevector, -t:facing:vector) > 0.95 {}

    RCS on.

    lock dockingPort to ship:controlpart.

    if not dockingPort:typename = "DockingPort" {
        print "Set controlpoint to the dockingport".
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

    set translationScalar to 10.
    lock translationVector to 10*-v(
        accelerationVector:x,
        accelerationVector:z,
        accelerationVector:y
    ).

    clearScreen.

    set dockingStep to 3.
    set forwardDistance to 20.
    set maxVelocity to 0.5.
    print "Canceling relative velocity" at (0,10).

    until false {
        if (desiredMovementVector - movementVector):mag < 2 set ship:control:translation to v(0,0,0).

        if relativeVector:mag > 50 set maxVelocity to 3.
        else if relativeVector:mag > 20 set maxVelocity to 1.
        else if dockingstep = 4 set maxVelocity to 0.2.
        else set maxVelocity to 0.5.


        print vdot(relativeVector, upVector) + "          " at (0, 0).
        print vdot(relativeVector, rightVector) + "          " at (0, 1).
        print vdot(forwardDistanceVector, -t:facing:vector) + "          " at (0, 2).



        // if dockingStep = 0 {    

        //     set desiredMovementVector to -movementVector.

        //     if desiredMovementVector:mag < 0.2 and movementVector:mag < 0.2 {
        //         print "Straight distance to 10          " at (0,10).
        //         set dockingStep to 1.
        //     }
        // }.
        // else if dockingStep = 1 {
        //     set desiredMovementVector to 
        //         -movementVector 
        //         + (vdot(forwardDistanceVector, -t:facing:vector) - forwardDistance) * -t:facing:vector.

        //     if desiredMovementVector:mag < 0.2 and movementVector:mag < 0.2 {
        //         print "Starboard distance to 0            " at (0,10).
        //         set dockingStep to 2.
        //     }
        // }
        // else if dockingStep = 2 {
        //     set desiredMovementVector to 
        //         -movementVector 
        //         + (vdot(forwardDistanceVector, -t:facing:vector) - forwardDistance) * -t:facing:vector
        //         + vDot(rightVector, relativeVector) * rightVector.

        //     if desiredMovementVector:mag < 0.2 and movementVector:mag < 0.2 {
        //         print "Top distance to 0               " at (0,10).
        //         set dockingStep to 3.
        //     }
        // }
        if dockingStep = 3 {
            set desiredMovementVector to 
                -movementVector 
                + (vdot(forwardDistanceVector, -t:facing:vector) - forwardDistance) * -t:facing:vector
                + vDot(rightVector, relativeVector) * rightVector
                + vDot(upVector, relativeVector) * upVector.

            if desiredMovementVector:mag < 0.01 and movementVector:mag < 0.01 {
                print "--------------------               " at (0,10).
                set forwardDistance to 10.
                set dockingStep to 4.
            }
        }
        else if dockingStep = 4 {
            set desiredMovementVector to 
                -movementVector 
                + (vdot(forwardDistanceVector, -t:facing:vector) - forwardDistance) * -t:facing:vector
                + vDot(rightVector, relativeVector) * rightVector
                + vDot(upVector, relativeVector) * upVector.

            if desiredMovementVector:mag < 0.01 and movementVector:mag < 0.01 {
                set forwardDistance to 0.
            }

            if dockingPort:haspartner {
                set targetFacingVector:show to false.
                set differenceVector:show to false.
                set upVectorDraw:show to false.
                set rightVectorDraw:show to false.
                set forwardDistanceVectorDraw:show to false.
                set movementVectorDraw:show to false.
                set desiredMovementVectorDraw:show to false.
                set accelerationVectorDraw:show to false.
                clearScreen.
                return.
            }
        }

        set translationScalar to (desiredMovementVector - movementVector):mag.
    

        
        if (desiredMovementVector:mag > maxVelocity) set desiredMovementVector:mag to maxVelocity.
        set ship:control:translation to translationVector.
        print desiredMovementVector + "                          " at (0, 4).
        print accelerationVector + "                         " at (0, 6).
        print translationVector + "                          " at (0, 8).  
        
    }
}

dock().