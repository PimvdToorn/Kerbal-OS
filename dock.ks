function dock {
    parameter t is target.

    if not t:typename = "DockingPort" {
        print "Target the desired docking port".
        return.
    }

    SAS off.
    lock steering to -t:facing:vector.

    RCS on.

    local dockingPort to ship:controlpart.

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


    // clearScreen.

    set oldTargetPosition to t:position.
    set oldTime to time:seconds.
    set movementVector to V(0, 0, 0).

    function moveVec {
        if (time:seconds - oldTime > 0){
            set vec to (oldTargetPosition - t:position) / (time:seconds - oldTime).

            set oldTargetPosition to t:position.
            set oldTime to time:seconds.
        }
        return vec.
    }
    lock movementVector to moveVec().
    lock movementVector to -(t:ship:velocity:orbit - ship:velocity:orbit).
    
    set movementVectorDraw to vecDraw(
        { return dockingPort:position. }, 
        { return 3*movementVector. }, 
        rgb(1,0,0)
        ).
    set movementVectorDraw:show to true.

    clearScreen.

    until false {

        if (time:seconds - oldTime > 0){

            print vdot(relativeVector, upVector) + "          " at (0, 0).
            print vdot(relativeVector, rightVector) + "          " at (0, 1).

            // set movementVector to (oldTargetPosition - t:position) / (time:seconds - oldTime).
            print movementVector at (0, 2).
            print vDot(t:facing:vector, movementVector) + "          " at (0, 3).



            set forwardDistance to 5.
            set maxVelocity to 1.

            set desiredMovementVector to 
                t:facing:vector * (forwardDistanceVector:mag - forwardDistance)
                + -vdot(rightVector, movementVector) * rightVector
                + -vdot(upVector, movementVector) * upVector.
            if (desiredMovementVector:mag > maxVelocity) set desiredMovementVector:mag to maxVelocity.

            set desiredMovementVectorDraw to vecDraw(
                { return dockingPort:position. }, 
                { return 3*desiredMovementVector. }, 
                rgb(1,1,0)
                ).
            set desiredMovementVectorDraw:show to true.

            // set ship:control:fore to vdot(t:facing:vector, movementVector).
            // set ship:control:starboard to -vdot(rightVector, movementVector).
            // set ship:control:top to -vdot(upVector, movementVector).
            // set ship:control:fore to forwardDistanceVector:mag - forwardDistance.
            // set ship:control:fore to desiredMovementVector:mag.
            // set ship:control:translation to desiredMovementVector.
            print forwardDistanceVector:mag - forwardDistance + "          " at (0, 4).
            
            // if ((t:position - dockingPort:position):mag)
            // set ship:control:fore 

            

            // if (vdot(t:facing:vector, movementVector) > 0.001)







            // set oldTargetPosition to t:position.
            // set oldTime to time:seconds.
        }
    }
}

dock().