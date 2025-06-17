@lazyGlobal off.
runOncePath("0:libraries/read_line").
runOncePath("0:libraries/utils/orbit").

function rendezvous {
    clearScreen.
    if not target:istype("Vessel") {
        print "No target selected".
        print "Press any key to return".
        terminal:input:getchar().
        return.
    }
    local lock tOrbit to target:orbit.

    print orbit:inclination at (0, 0).
    print tOrbit:inclination at (0, 1).
    print "-------------------------------------" at (0, 2).
    print orbit:lan at (0, 3).
    print tOrbit:lan at (0, 4).

    local meanAngularMotion to 360 / orbit:period.
    local periapsisTime to time:seconds + orbit:eta:periapsis - orbit:period.
    local trueAnomalyAscendingNode to 360 - orbit:argumentofperiapsis.
    local trueAnomalyDescendingNode to mod(trueAnomalyAscendingNode + 180, 360).
    print trueAnomalyDescendingNode at (0, 5).

    local timeAscendingNode to trueAnomalyToUTSeconds(trueAnomalyAscendingNode, meanAngularMotion, periapsisTime, orbit:eccentricity).
    local timeDescendingNode to trueAnomalyToUTSeconds(trueAnomalyDescendingNode, meanAngularMotion, periapsisTime, orbit:eccentricity).

    print "-------------------------------------" at (0, 6).
    print "P time: " + timeStamp(periapsisTime):full at (0, 7).
    print "Time asc. node: " + timeStamp(timeAscendingNode):full at (0, 8).
    print "Time desc. node: " + timeStamp(timeDescendingNode):full at (0, 9).

    print "-------------------------------------" at (0, 10).
    print "LAN: " + orbit:lan at (0, 11).
    print "tLAN: " + tOrbit:lan at (0, 12).
    print "incl.: " + orbit:inclination at (0, 13).
    print "tIncl.: " + tOrbit:inclination at (0, 14).


    local nodeTimes to targetNodeTimes().
    add node(nodeTimes[0], 0, 0, 0).
    // add node(nodeTimes[1], 0, 0, 0).
    // add node(targetNodeTimes()[0], 0, 0, 0).
    // add node(targetNodeTimes()[1], 0, 0, 0).


    print "Press any key to return" at (0, 36).
    terminal:input:getchar().
}

function orbitToNodeTimes {
    parameter o to orbit.
    
    local meanAngularMotion to 360 / o:period.
    local periapsisTime to time:seconds + o:eta:periapsis - o:period.
    local eccentricity to o:eccentricity.

    local trueAnomalyAscendingNode to 360 - o:argumentofperiapsis.
    local trueAnomalyDescendingNode to mod(trueAnomalyAscendingNode + 180, 360).

    local meanAnomalyAscendingNode to trueToMeanAnomaly(trueAnomalyAscendingNode, eccentricity).
    local meanAnomalyDescendingNode to trueToMeanAnomaly(trueAnomalyDescendingNode, eccentricity).
    
    local timeAscendingNode to meanAnomalyToUTSeconds(meanAnomalyAscendingNode, meanAngularMotion, periapsisTime).
    local timeDescendingNode to meanAnomalyToUTSeconds(meanAnomalyDescendingNode, meanAngularMotion, periapsisTime).

    if timeAscendingNode < time:seconds {
        set timeAscendingNode to timeAscendingNode + o:period.
    }
    if timeDescendingNode < time:seconds {
        set timeDescendingNode to timeDescendingNode + o:period.
    }

    local nodeTimes to list().
    nodeTimes:add(timeAscendingNode).
    nodeTimes:add(timeDescendingNode).
    return nodeTimes.
}

function targetNodeTimes {
    parameter o to orbit.
    parameter tO to target:orbit.
    
    local meanAngularMotion to 360 / o:period.
    local oTimeAscend to o:lan / meanAngularMotion.
    local tOTimeAscend to tO:lan / meanAngularMotion.
    local deltaTimeAscend to tOTimeAscend - oTimeAscend.

    local periapsisTime to time:seconds + o:eta:periapsis - o:period.
    local eccentricity to o:eccentricity.
    local lanDifference to -abs(o:lan - tO:lan).
    local incDifference to tO:inclination - o:inclination.
    local i to tO:inclination.
    local j to o:inclination.
    local l to lanDifference.
    // print sqrt(j^2*sin(l)^2 + j^2*cos(l)^2 - 2*i*j*cos(l) - 1) at (0, 15).
    // print (j*cos(l)-i) at (0, 16).
    // print (j*cos(l)-i)/sqrt(j^2*sin(l)^2 + j^2*cos(l)^2 - 2*i*j*cos(l) - 1) at (0, 17).
    // print arccos((j*cos(l)-i)/sqrt(j^2*sin(l)^2 + j^2*cos(l)^2 - 2*i*j*cos(l) - 1)) at (0, 18).
    local cosOffset to -(j*cos(l)-i)/sqrt(j^2*sin(l)^2 + j^2*cos(l)^2 - 2*i*j*cos(l) - 1).
    // if cosOffset < 0 {
    //     set cosOffset to cosOffset + constant:pi.
    // }
    print cosOffset at (0, 19).
    // terminal:input:getchar().
    local offset to arccos(cosOffset).
    print offset at (0, 20).

    local trueAnomalyAscendingNode to 360 - o:argumentOfPeriapsis + offset.
    local trueAnomalyDescendingNode to mod(trueAnomalyAscendingNode + 180, 360).

    local meanAnomalyAscendingNode to trueToMeanAnomaly(trueAnomalyAscendingNode, eccentricity).
    local meanAnomalyDescendingNode to trueToMeanAnomaly(trueAnomalyDescendingNode, eccentricity).

    local timeAscendingNode to meanAnomalyToUTSeconds(meanAnomalyAscendingNode, meanAngularMotion, periapsisTime).
    local timeDescendingNode to meanAnomalyToUTSeconds(meanAnomalyDescendingNode, meanAngularMotion, periapsisTime).

    if timeAscendingNode < time:seconds {
        set timeAscendingNode to timeAscendingNode + o:period.
    }
    if timeDescendingNode < time:seconds {
        set timeDescendingNode to timeDescendingNode + o:period.
    }

    local nodeTimes to list().
    nodeTimes:add(timeAscendingNode).
    nodeTimes:add(timeDescendingNode).
    return nodeTimes.
}