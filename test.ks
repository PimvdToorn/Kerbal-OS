function test {
    clearScreen.
    local xVec to vecDraw(
        { return ship:position. }, 
        { local p to ship:position. 
            set p:x to p:x + 10.
            return p.
        },
        rgb(1, 0, 0)
    ).
    set xVec:show to true.
    local yVec to vecDraw(
        { return ship:position. }, 
        { local p to ship:position. 
            set p:y to p:y + 10.
            return p.
        },
        rgb(0, 1, 0)
    ).
    set yVec:show to true.
    local zVec to vecDraw(
        { return ship:position. }, 
        { local p to ship:position. 
            set p:z to p:z + 10.
            return p.
        },
        rgb(0, 0, 1)
    ).
    set zVec:show to true.
    local topVec to vecDraw(
        { return ship:position. }, 
        { return facing:topvector * 10. },
        rgb(1, 1, 0)
    ).
    set topVec:show to true.
    local starVec to vecDraw(
        { return ship:position. }, 
        { return facing:starvector * 10. },
        rgb(1, 0, 1)
    ).
    set starVec:show to true.
    local upVec to vecDraw(
        { return ship:position. }, 
        { return ship:up:vector * 10. },
        rgb(0, 1, 1)
    ).
    set upVec:show to true.

    print "[Q] Quit" at (0, 36).
    until false {
        print "Horizon roll: " + round(getHorizonRoll(), 1) + "       " at (0, 0).
        print "Direction roll: " + round(facing:roll, 1) + "       " at (0, 1).


        print "Euler roll: " + round(getEulerRollFromHorizon(getHorizonRoll()), 1) + "       " at (0, 2).
        print "Horizon roll from Euler: " + round(getHorizonRollFromEuler(facing:roll), 1) + "       " at (0, 3).

        if terminal:input:hasChar {
            local input is terminal:input:getChar():toLower.

            if input = "q" {
                clearVecDraws().
                reboot.
            }
        }
    }
}