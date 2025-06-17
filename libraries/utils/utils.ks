@lazyGlobal off.

function rMod {
    parameter a, b.
    if a < 0 { return b + mod(a, b). }
    return mod(a, b).
}

function drawHud {
    parameter text.
    parameter widthOffset to 0.
    parameter heightOffset to 0.

    local lines to text:length().
    for i in range(lines) {

        print text[i]:padRight(terminal:width - widthOffset) at (0 + widthOffset, i + heightOffset).
    }
}

function format {
    parameter number.
    // parameter decimals to 0.
    local str to "".
    local negator to "".

    if number < 0 {
        set negator to "-".
        set number to abs(number).
    }

    until number < 1 {
        local num to round(mod(number, 1000)) + "".
        local last to number < 1000.
        if not last {
            set num to num:padLeft(3):replace(" ", "0").
        }
        set str to num + "." + str.
        set number to number / 1000.
    }
    set str to negator + str.
    return str:substring(0, str:length - 1). // remove trailing dot
}

function maxAcceleration {
    return ship:availablethrust / ship:mass.
}

function geoDistance {
    parameter geo1.
    parameter geo2.
    parameter bod to body.

    local lat1 to geo1:lat * constant:pi / 180.
    local lon1 to geo1:lng * constant:pi / 180.
    local lat2 to geo2:lat * constant:pi / 180.
    local lon2 to geo2:lng * constant:pi / 180.

    local dLat to lat2 - lat1.
    local dLon to lon2 - lon1.
    local sinDLat to sin(dLat / 2).
    local sinDLon to sin(dLon / 2).
    local a to sinDLat * sinDLat + cos(lat1) * cos(lat2) * sinDLon * sinDLon.
    local c to 2 * arcsin(sqrt(a)).
    return bod:radius * c.
}

function valueMap {
    parameter value.
    parameter fromMin.
    parameter fromMax.
    parameter toMin.
    parameter toMax.

    return toMin + (value - fromMin) * (toMax - toMin) / (fromMax - fromMin).
}