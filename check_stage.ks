// Checks if resources in stage are depleted, so we should stage
// Assumes that stage will be necessary when resources[0] fuel is empty
// Written by Nolan Bock
function check_stage {
    // checks if liquid fuel is empty and stages
    until stage:resources[0]:amount > 0.1 {
        stage.
        wait until stage:ready.
    }
}
