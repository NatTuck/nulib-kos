// Circularization burn calculation adapted from Lucius_Martius' comment on this
// thread: https://www.reddit.com/r/Kos/comments/2wuo9o/what_is_the_easiest_way_to_circularize_while/
// Adapted by Nolan Bock
// Takes a body to circularize around as a parameter and returns a maneuver node
function circularize {
    // the body we will circularize around
    parameter body.

    set mu to body:mu.
    set body_radius to body:radius.

    // calculations for delta v to circularize orbit
    set r_ap to ship:apoapsis + body_radius.
    set r_pe to ship:periapsis + body_radius.
    set dv to (sqrt(mu/r_ap) - sqrt((r_pe * mu) / (r_ap * (r_pe + r_ap)/2))).
    set max_acc to ship:maxthrust/ship:mass.
    set burn_duration to dv/max_acc.

    // equalize the burn on both sides of the apoapsis
    set n_time to (eta:apoapsis - round(burn_duration) / 2).
    set nd to NODE(time:seconds + n_time, 0, 0, dv).
    return nd.
}
