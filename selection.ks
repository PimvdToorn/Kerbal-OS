runOncePath("0:launch").
runOncePath("0:eM").
runOncePath("0:dock").
runOncePath("0:rendezvous").
runOncePath("0:circularize").
runOncePath("0:ssto").
runOncePath("0:test").

function selection {
    clearScreen.

    print "1: Launch".
    print "2: Execute maneuver".
    print "3: Dock".
    print "4: Rendezvous".
    print "5: Circularize".
    print "6: SSTO launch".
    print "7: SSTO reentry".
    print "8: Test".
    print "[Q] Reboot" at (0, 36).

    local mode to terminal:input:getchar().

    print mode at (0, 15).

    if mode = "q" { reboot. }
    else if mode = "1" { launch(). }
    else if mode = "2" { executeManeuver(). }
    else if mode = "3" { dock(). }
    else if mode = "4" { rendezvous(). }
    else if mode = "5" { circularizeInput(). }
    else if mode = "6" { sstoOrbit(). }
    else if mode = "7" { sstoReentry(). }
    else if mode = "8" { test(). }
    else { print "Invalid mode". }
    unlock all.
}