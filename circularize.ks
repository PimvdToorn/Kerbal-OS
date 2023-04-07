function circularizeRough {
    parameter height.

    local throt to 0.
    lock throttle to throt.
    local head to prograde.
    lock steering to head.


    if apoapsis < height {
        set head to prograde.
        wait until vang(prograde:vector, facing:vector) < 5.
        set throt to 1.
        wait until apoapsis >= height.
        set throt to 0.
    }
    else if periapsis > height {
        set head to retrograde.
        wait until vang(retrograde:vector, facing:vector) < 5.
        set throt to 1.
        wait until periapsis <= height.
        set throt to 0.
    }
    


    local mu is body:mu.
    local br is body:radius.
    local vel is velocity:orbit:mag.
    local r is br + altitude.

    lock ra to br + apoapsis. 
    
    if eta:apoapsis < eta:periapsis {
        local va is sqrt( vel^2 + 2*mu*(1/ra - 1/r) ).
        local sma is (periapsis + 2*br + apoapsis)/2.
    }
    else {
        lock ra to br + periapsis.
        local va is sqrt( vel^2 + 2*mu*(1/ra - 1/r) ).
        local sma is (periapsis + 2*br + apoapsis)/2.
    }


    local va is sqrt( vel^2 + 2*mu*(1/ra - 1/r) ).
    



    // Orbital speed that it needs to reach S(m/s)
    // Current speed C(m/s)
    // Acceleration A(m/s/s) (change throttle?)
    // change(m/s) = S - C
    // duration(s) = change / A
}