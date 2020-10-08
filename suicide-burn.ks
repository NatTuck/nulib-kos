//This Script was written by Connor Frazier
//Northeastern CS 5335 Fall 2020.

//Attributions:
//Trigonemtry rescource:
//https://www.mathsisfun.com/sine-cosine-tangent.html
//Kinimatic equation rescoruce:
//https://www.khanacademy.org/science/physics/one-dimensional-motion/kinematic-formulas/a/what-are-the-kinematic-formulas

//Ship accelaration = ship:maxthrust/ship:mass from the execute node script written by the the KOS authors at:
//(https://ksp-kos.github.io/KOS/tutorials/exenode.html).
//gravity of a planet in KOS = g = body:mu / (altitude + body:radius)^2 written by "dunadirect" at:
//https://www.reddit.com/r/Kos/comments/58amhh/how_do_you_check_the_ships_acceleration_and/



//Return the distance the ship has to stop by (hypotenuse of the right triangle
//formed by ship to the group).
function getAngledDistanceToGround {
  return ALT:RADAR/COS(SHIP:VELOCITY:SURFACE:DIRECTION:PITCH).
}

//Returns the distance required to come to a full stop the ship at its
//current velocity and accelaration. (Recommended using with ALT:RADAR instead
//of SHIP:ALTITUDE due to higher accuracy under 10km).

//Param: the body the ship is landing on.
function getDistanceRequiredToStopShip {
  parameter target_body.

  LOCAL target_planet_gravity_accelaration is target_body:MU / (ALT:RADAR + target_body:RADIUS)^2.
  return -1 * (SHIP:VELOCITY:SURFACE:MAG)^2/(2*(target_planet_gravity_accelaration - ship:maxthrust/ship:mass)).
}

//Returns the height above the terrain that the ship must start its suicide burn
//given its current velocity. (Recommended using with ALT:RADAR instead
//of SHIP:ALTITUDE due to higher accuracy under 10km).

//Param: the body the ship is landing on.
function getSuicideBurnAltitude {
  parameter target_body.

  return getDistanceRequiredToStopShip(target_body) * COS(SHIP:VELOCITY:SURFACE:DIRECTION:PITCH).
}
