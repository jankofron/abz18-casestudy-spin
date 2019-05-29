#include "dsl.pml"

//4 TTD, 10 VSS, 11 steps of the scenario
CREATEINFRASTRUCTURE(4,10,11);

// a necessity because promela syntax...
BEGINUSECASE

//lenghts of particular TTD in VSS
SETTTDLEN(0,2);
SETTTDLEN(1,3);
SETTTDLEN(2,3);
SETTTDLEN(3,2);

// create a slow train woth ID 0 that appears in step 0
FASTTRAIN(0,0);

// train 0 disconnects at step 5
DISCONNECT(0, 5);
// ... and connects back at step 7
CONNECT(0, 7);

// fast train with ID 1 spawns at step 3
FASTTRAIN(1, 3);

LOOSEINTEGRITY(1, 6);

GAININTEGRITY(1, 8);

// again, syntax need
ENDUSECASE


