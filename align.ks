function alignTarget {
    parameter t is target.

    lock steering to -t:facing:vector.

    print "Aligning, press any key to exit".
    terminal:input:getchar().
    clearScreen.
}

alignTarget().

