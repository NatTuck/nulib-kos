// Description
//              Warps to the time of an encounter.
// Usecase
//              In the moon landing script, once in a transfer orbit, 
//              this is useful to warp to the time of encounter.
// Purpose
//              This is a much more simple solution than trying to calculate 
//              the time of the encounter using fancy orbital mechanics.
// How it Works
//              1) Stores the current body. 
//              2) Warps till the orbiting body is not equal to the inital body.

CLEARSCREEN.

SET WARPMODE TO "RAILS".
SET WARP TO 5.
DECLARE INITAL_BODY TO SHIP:ORBIT:BODY.

UNTIL SHIP:ORBIT:BODY <> INITAL_BODY {
    PRINT "Currently in transfer orbit." AT (0,1).
}
PRINT "Reached encounter!" AT (0,2).
SET WARP TO 0.