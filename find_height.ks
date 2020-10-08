// This code was written by brekus on this link: https://www.reddit.com/r/Kos/comments/3u1l5s/how_do_you_get_your_crafts_altitude_off_the_ground/
// Adapted by Nolan Bock
// Helper function for finding the height of a ship, which is useful during landing
function find_height {
    list parts in partList.
    set lp to 0. // lowest part height
    set hp to 0. // hightest part height

    for p in partList{
        set cp to facing:vector * p:position.
    if cp < lp
        set lp to cp.
    else if cp > hp
        set hp to cp.
    }

    set height to hp - lp.
    return height.
}
