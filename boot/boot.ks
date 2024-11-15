@lazyGlobal off.

function boot {
    clearScreen.

    print "1: Launch".
    print "2: Execute maneuver".
    print "3: Dock".
    print "4: Rendezvous".

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
    else if mode = "4" {
        rendezvous().
    }
    else {
        print "Invalid mode".
    }
    unlock all.
}

runOncePath("0:launch").
runOncePath("0:eM").
runOncePath("0:dock").
runOncePath("0:rendezvous").

until false boot().