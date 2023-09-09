function boot {
    clearScreen.

    print "1: Launch".
    print "2: Execute maneuver".
    print "3: Dock".

    set mode to terminal:input:getchar().

    if mode = "1" {
        launch().
    }
    if mode = "2" {
        executeManeuver().
    }
    if mode = "3" {
        dock().
    }
    unlock all.
}

runPath("0:launch").
runPath("0:eM").
runPath("0:dock").

until false boot().