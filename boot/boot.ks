@lazyGlobal off.

function boot {
    clearScreen.

    print "1: Launch".
    print "2: Execute maneuver".
    print "3: Dock".

    local mode to terminal:input:getchar().

    if mode = "1" {
        launch().
    }
    else if mode = "2" {
        executeManeuver().
    }
    else if mode = "3" {
        dock().
    }
    unlock all.
}

runOncePath("0:launch").
runOncePath("0:eM").
runOncePath("0:dock").

until false boot().