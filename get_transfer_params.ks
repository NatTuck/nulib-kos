// Author: Thomas Kaunzinger
//
// Function that approximates the time and delta_v needed to transfer from a circular orbit of body_distance around body1
// to an eliptical orbit where the apoapsis is at body_distance beyond body2.
//
// time_offset is used if this transfer would be occuring in the future (i.e. after another transfer)
//
// This function roughly accounts for the travel time that would be required for the orbit.
//
// Returns a lex with items "time", and "delta_v" for the respective time and delta_v that the transfer would need
//
// Usage:
//
// // Gets information for a transfer from the ship's current body to the mun
// local trans is get_transfer_params(ship:body, body("Mun")).
// print "Transfer Time".
// print trans:time.
// print "Delta V required".
// print trans:delta_v.

// Gets the duration of time and delta_v needed for a transfer from a start body to a target body.
function get_transfer_params {
    parameter body1.                    // Starting body
    parameter body2.                    // Transfer target body
    parameter time_offset is 0.         // For checking transfers in the future
    parameter body_distance is 100000.  // Change if circularizing at a different altitude

    // Finds out how long to transfer to a target body
    local transfer_time_now is 0.
    local pos_1_offset is positionat(body1, time_offset).
    local pos_2_offset is positionat(body2, time_offset).
    local delta_start is (pos_1_offset - pos_2_offset):mag.

    local start_per is body_distance + body1:radius.
    local start_apo is delta_start - body1:radius + (2 * body2:radius) + body_distance.
    local semimajor_start is (start_per + start_apo) / 2.

    // Formula by /u/nuggreat on reddit
    local transfer_time_start is 2 * constant:pi * sqrt(semimajor_start^3 / body1:mu).

    // Approximately accounts for moving position of the second body
    local pos_2_offset_and_travel is positionat(body2, time_offset + transfer_time_start).
    local delta_travel is (pos_1_offset - pos_2_offset_and_travel):mag.

    local end_apo is delta_travel - body1:radius + (2 * body2:radius) + body_distance.
    local semimajor_final is (start_per + end_apo) / 2.

    local transfer_time is 2 * constant:pi * sqrt(semimajor_final^3 / body1:mu).

    local ret is lexicon().
    ret:add("time", transfer_time).
    
    // Finds the delta_v needed for the transfer, using the vis-viva equation
    local start_v is sqrt((constant:g * body1:mass) * ((2 / start_per) - ( 1 / start_per))).
    local end_v is sqrt((constant:g * body1:mass) * ((2 / start_per) - (1 / end_apo))).
    local delta_v is end_v - start_v.

    ret:add("delta_v", delta_v).

    return ret.
}