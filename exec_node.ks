//Amit - added fucntion for autostaging when required during maneuver burn

function doStageWhenNeeded {
    set should_stage to false.
    set should_stage to (ship:maxthrust = 0).
    list engines in englist.
    for eng in englist {
        if eng:flameout {
            set should_stage to true.
          }
    }
    if should_stage {
      wait 0.5.
      stage.
    }
}

// based on https://ksp-kos.github.io/KOS/tutorials/exenode.html
// Changes by:
//  - Nat Tuck

local nd is nextnode.

print "Node in: " + round(nd:eta) + ", DeltaV: " + round(nd:deltav:mag).

local max_acc is ship:maxthrust/ship:mass.

// TODO: Apply rocket equation
// maybe from: https://github.com/KSP-KOS/KSLib/blob/master/library/lib_navigation.ks
local burn_duration is nd:deltav:mag/max_acc.
print "Crude Estimated burn duration: " + round(burn_duration) + "s".

wait until nd:eta <= (burn_duration/2 + 60).

local np is nd:deltav.
lock steering to np.

wait until vang(np, ship:facing:vector) < 0.25.
wait until nd:eta <= (burn_duration/2).

// we only need to lock throttle once to a certain variable in the beginning
// of the loop, and adjust only the variable itself inside it
local tset is 0.
lock throttle to tset.

local done is False.

//initial deltav
local dv0 is nd:deltav.
until done
{
    // recalculate current max_acceleration, as it changes while we burn through fuel
    local max_acc is ship:maxthrust/ship:mass.

    // throttle is 100% until there is less than 1 second of time left to burn
    // when there is less than 1 second - decrease the throttle linearly
    set tset to min(nd:deltav:mag/max_acc, 1).

    // here's the tricky part, we need to cut the throttle as soon as our
    // nd:deltav and initial deltav start facing opposite directions
    // this check is done via checking the dot product of those 2 vectors
    if vdot(dv0, nd:deltav) < 0
    {
        local rdv is round(nd:deltav:mag,1).
        local rdot is round(vdot(dv0, nd:deltav),1).
        print "End burn, remain dv " + rdv + "m/s, vdot: " + rvdot.
        lock throttle to 0.
        break.
    }

    // we have very little left to burn, less then 0.1m/s
    if nd:deltav:mag < 0.1
    {
        local rdv is round(nd:deltav:mag,1).
        local rdot is round(vdot(dv0, nd:deltav),1).
        print "Finalizing burn, remain dv " + rdv + "m/s, vdot: " + rdot.
        // we burn slowly until our node vector starts to drift significantly from
        // initial vector this usually means we are on point
        wait until vdot(dv0, nd:deltav) < 0.5.

        lock throttle to 0.
        print "End burn, remain dv " + round(nd:deltav:mag,1) + "m/s, vdot: " + round(vdot(dv0, nd:deltav),1).
        set done to True.
    }
    doStageWhenNeeded().
}

unlock steering.
unlock throttle.
wait 1.

// we no longer need the maneuver node
remove nd.

// set throttle to 0 just in case.
SET SHIP:CONTROL:PILOTMAINTHROTTLE TO 0.
