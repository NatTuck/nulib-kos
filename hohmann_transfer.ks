
// circularization burn calculation adapted from Lucius_Martius' comment on this
// thread: https://www.reddit.com/r/Kos/comments/2wuo9o/what_is_the_easiest_way_to_circularize_while/
// Adapted by Nolan Bock
// Takes a body to circularize around as a parameter and returns a maneuver node
// Returns maneuver node or "None" if no maneuver is required
function circularize {
    // the body we will circularize around
    parameter body.

    if ship:orbit:eccentricity > 0.008 {
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

    // if not circularization is required, return None
    return "None".
}

// True anomaly logic from Alex Ascherson's: https://github.com/AlexAscherson/Kerbal-Kos-Programming
// Lightly adapted by Nolan Bock to estimate times, mostly Alex Ascherson's work
// Helper function for setInclination
function eta_true_anom {
    declare local parameter tgt_lng.
    // convert the positon from reference to deg from PE (which is the true anomaly)
    local ship_ref to mod(obt:lan+obt:argumentofperiapsis+obt:trueanomaly,360).
    // s_ref = lan + arg + referenc

    local node_true_anom to (mod (720+ tgt_lng - (obt:lan + obt:argumentofperiapsis),360)).

    local node_eta to 0.
    local ecc to OBT:ECCENTRICITY.
    if ecc < 0.001 {
        set node_eta to SHIP:OBT:PERIOD * ((mod(tgt_lng - ship_ref + 360,360))) / 360.

    } else {
        local eccentric_anomaly to  arccos((ecc + cos(node_true_anom)) / (1 + ecc * cos(node_true_anom))).
        local mean_anom to (eccentric_anomaly - ((180 / (constant():pi)) * (ecc * sin(eccentric_anomaly)))).

        // time from periapsis to point
        local time_2_anom to  SHIP:OBT:PERIOD * mean_anom /360.

        local my_time_in_orbit to ((OBT:MEANANOMALYATEPOCH)*OBT:PERIOD /360).
        set node_eta to mod(OBT:PERIOD + time_2_anom - my_time_in_orbit,OBT:PERIOD) .

    }

    return node_eta.
}

// Inclination logic from Alex Ascherson's: https://github.com/AlexAscherson/Kerbal-Kos-Programming
// Lightly adapted by Nolan Bock to estimate times, mostly Alex Ascherson's work
// Helper function for setInclination
function set_inc_lan {
    DECLARE PARAMETER incl_t.
    DECLARE PARAMETER lan_t.
    local incl_i to SHIP:OBT:INCLINATION.
    local lan_i to SHIP:OBT:LAN.

    // setup the vectors to highest latitude; Transform spherical to cubic coordinates.
    local Va to V(sin(incl_i)*cos(lan_i+90),sin(incl_i)*sin(lan_i+90),cos(incl_i)).
    local Vb to V(sin(incl_t)*cos(lan_t+90),sin(incl_t)*sin(lan_t+90),cos(incl_t)).
    // important to use the reverse order
    local Vc to VCRS(Vb,Va).

    local dv_factor to 1.
    //compute burn_point and set to the range of [0,360]
    local node_lng to mod(arctan2(Vc:Y,Vc:X)+360,360).
    local ship_ref to mod(obt:lan+obt:argumentofperiapsis+obt:trueanomaly,360).

    local ship_2_node to mod((720 + node_lng - ship_ref),360).

    local node_true_anom to 360- mod(720 + (obt:lan + obt:argumentofperiapsis) - node_lng , 360 ).
    local ecc to OBT:ECCENTRICITY.
    local my_radius to OBT:SEMIMAJORAXIS * (( 1 - ecc^2)/ (1 + ecc*cos(node_true_anom)) ).
    local my_speed1 to sqrt(SHIP:BODY:MU * ((2/my_radius) - (1/OBT:SEMIMAJORAXIS)) ).
    local node_eta to eta_true_anom(node_lng).
    local my_speed to VELOCITYAT(SHIP, time+node_eta):ORBIT:MAG.
    local d_inc to arccos (vdot(Vb,Va) ).
    local dvtgt to dv_factor* (2 * (my_speed) * SIN(d_inc/2)).

    // Create a blank node
    local inc_node to NODE(node_eta, 0, 0, 0).

    // we need to split our dV to normal and prograde
    set inc_node:NORMAL to dvtgt * cos(d_inc/2).

    // always burn retrograde
    set inc_node:PROGRADE to 0 - abs(dvtgt * sin(d_inc/2)).
    set inc_node:ETA to node_eta.

    return inc_node.
}

// Calculate the inclination burn necessary to match the inclination of tgtbody's orbit
// Supplemental to hohmann transfer logic from Alex Ascherson (link below)
// Adapted by Nolan Bock
// Takes a body to match inclination of as a parameter and returns a maneuver node
// Returns maneuver node or "None" if no maneuver is required
function setInclination {
    parameter tgtbody.

    local ri is abs(obt:inclination - (tgtbody:obt:inclination+0.01)).
    // Align if necessary
    if ri > 0.1 {
        // print "Matching Inclination".
        set inc_node to set_inc_lan(tgtbody:orbit:inclination, tgtbody:orbit:LAN).
        return inc_node.
    }
    return "None".
}


// Calculate Hohmann transfer logic.
// My Hohmann transfer was supplemented with Alex Ascherson's: https://github.com/AlexAscherson/Kerbal-Kos-Programming
// Adapted by Nolan Bock to estimate times and return a node, also fixes to minor bugs in Hohmann transfer logic
// Assumes that inclination matches that of the tgtbody - if not, call setInclination(tgtbody)
// NOTE: setInclination relies on helper functions within this script
// Assumes that current orbit is circular - if not, call circularize(tgtbody)
// Takes a target orbit body as a parameter and returns a maneuver node to that target
function CalcHohmannTransfer {
    parameter tgtbody.

    set done to False.
    set delaynode to 0.

    //parameter tgtbody.
	// move origin to central body (i.e. Kebodyradiusin)
    set positionlocal to V(0,0,0) - body:position.
    set positiontarget to tgtbody:position - body:position.

    // Hohmann transfer orbit period
    set bodyradius to body:radius.
    set altitudecurrent to bodyradius + altitude.                 // actual distance to body
    set altitudeaverage to bodyradius + (periapsis+apoapsis)/2.  // average radius (burn angle not yet known)
    set currentvelocity to ship:velocity:orbit:mag.          // actual velocity
    set averagevelocity to sqrt( currentvelocity^2 - 2*body:mu*(1/altitudeaverage - 1/altitudecurrent) ). // average velocity
    set soi to (tgtbody:soiradius).
    set transferAp to positiontarget:mag - (0.3*soi).

    // Transfer SMA
    set sma_transfer to (altitudeaverage + transferAp)/2.
    set transfertime to 2 * constant():pi * sqrt(sma_transfer^3/body:mu).

    // current target angular position
    set targetangularpostioncurrent to arctan2(positiontarget:x,positiontarget:z).
    // target angular position after transfer
    set target_sma to positiontarget:mag.                       // mun/minmus have a circular orbit
    set orbitalperiodtarget to 2 * constant():pi * sqrt(target_sma^3/body:mu).      // mun/minmus orbital period
    set sma_ship to positionlocal:mag.
    set orbitalperiodship to 2 * constant():pi * sqrt(sma_ship^3/body:mu).      // ship orbital period

    set transferangle to (transfertime/2) / orbitalperiodtarget * 360.            // mun/minmus angle for hohmann transfer
    set das to (orbitalperiodship/2) / orbitalperiodtarget * 360.           // half a ship orbit to reduce max error to half orbital period

    set at1 to targetangularpostioncurrent - das - transferangle.                // assume counterclockwise orbits

    // current ship angular position
    set shipangularpostion_current to arctan2(positionlocal:x,positionlocal:z).

    // ship angular position for maneuver
    set shipangularpostion_manuever_temp to mod(at1 + 180, 360).

    // eta to maneuver node
    set shipangularpostion_manuever to shipangularpostion_manuever_temp.
    until shipangularpostion_current > shipangularpostion_manuever {
        set shipangularpostion_manuever to shipangularpostion_manuever - 360.
    }
    set etanode to (shipangularpostion_current - shipangularpostion_manuever) / 360 * orbitalperiodship.

    // hohmann orbit properties
    set transferdv to sqrt( averagevelocity^2 - body:mu * (1/sma_transfer - 1/sma_ship ) ).
    set dv to transferdv - averagevelocity.

    set delaynode to 0.
    // setup node
    if delaynode = 0 {
      set nd to node(time:seconds + etanode, 0, 0, dv).
    } else {
      set nd to node(time:seconds + (delaynode+ etanode), 0, 0, dv).
    }

    return nd.
}
