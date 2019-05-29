// Description
// Codes reflect the following actions:
// 0 - no action for the train
// 1 - spawn the train
// 2 - move the front end
// 3 - move the rear end
// 4 - train disappears
// 5 - train disconnects
// 6 - train reconnects
// 7 - train splits
// 8 - move both front and rear ends of the train
// 9 - train loses integrity
// 10 - train gets integrity
// 16 + code above - train reports
// 32 + code above - train reports integrity
// 
// for timer fields, true means the timer has expired
#define SIMULATIONSTEPS 16
 
typedef Step {
	byte train[2];
	byte mutetimer[2];
	byte disconnecttimer[VSSCOUNT];
	byte integritylosstimer[VSSCOUNT];
	byte shadowtimerA[TTDCOUNT];
	byte shadowtimerB[TTDCOUNT];
	byte ghosttimer;
	byte eoma[2];
	byte eom[2];
}

typedef Scenario {
	Step step[SIMULATIONSTEPS];
}

// we have 9 scenarios so far, indexing from 1 to correspond to the spec
Scenario scenarios[10];

//Note that the step numbers reported in the comments refer to the steps of
//scenarios of the case study document.
inline initScenarios() {
////////////////////////////////////////////////
//////////////// Scenario 1 ////////////////////
////////////////////////////////////////////////
// no timer ever expires in this scenario, leaving the default value 0

//step 1
scenarios[1].step[0].train[0] = (1 | 48);//train 0 is spawned
scenarios[1].step[0].eoma[0] = 9;
//step 2
scenarios[1].step[1].train[0] = (8 | 16);//train 0 moves entirely and does not report its integrity
//step 3
scenarios[1].step[2].train[0] = (48);//train 0 reports everything
//step 4
scenarios[1].step[3].train[0] = (8 | 16);//train 0 moves entirely and does not report its integrity
//step 5
scenarios[1].step[4].train[0] = (48);//train 0 reports everything
//step 6
scenarios[1].step[5].train[0] = (8 | 16);//train 0 moves entirely and does not report its integrity
//step 7
scenarios[1].step[6].train[0] = (8 | 48);//train 0 moves entirely and reports everything
//step 8
scenarios[1].step[7].train[0] = (8 | 48);//train 0 moves entirely and reports everything



////////////////////////////////////////////////
//////////////// Scenario 2 ////////////////////
////////////////////////////////////////////////

scenarios[2].step[0].train[0] = (1 | 48);//train 1 is spawned
scenarios[2].step[0].eoma[0] = 9;
//step 1
scenarios[2].step[1].train[0] = (8 | 48);//move to the first VSS of the specifications scenario
//step 2
scenarios[2].step[2].train[0] = (7 | 48);//train splits
scenarios[2].step[2].eoma[1] = 1;
scenarios[2].step[2].train[1] = 0;
scenarios[2].step[2].integritylosstimer[1] = 3;
//step 3
scenarios[2].step[3].train[0] = (8 | 48);
scenarios[2].step[3].integritylosstimer[1] = 3;
//step 4
scenarios[2].step[4].train[0] = (8 | 48);
scenarios[2].step[4].integritylosstimer[1] = 3;
//step 5
scenarios[2].step[5].train[0] = (8 | 48);
scenarios[2].step[5].integritylosstimer[1] = 4;
//step 6
scenarios[2].step[6].train[0] = (2 | 48);
//step 7
scenarios[2].step[7].train[0] = (3 | 0);
scenarios[2].step[7].shadowtimerA[1] = 1;
//step 8
scenarios[2].step[8].train[0] = (48);
scenarios[2].step[8].shadowtimerA[1] = 1;



////////////////////////////////////////////////
//////////////// Scenario 3 ////////////////////
////////////////////////////////////////////////

scenarios[3].step[0].train[0] = (1 | 48);
scenarios[3].step[0].eoma[0] = 9;
scenarios[3].step[1].train[0] = (8 | 48);
//step 1
scenarios[3].step[2].train[0] = (7 | 16);//train splits
scenarios[3].step[2].integritylosstimer[1] = 4;
scenarios[3].step[2].eoma[1] = 1;
//step 2
scenarios[3].step[3].train[0] = (8 | 48);
scenarios[3].step[3].integritylosstimer[1] = 4;
scenarios[3].step[3].eoma[1] = 1;
scenarios[3].step[3].shadowtimerB[1] = 1;
//step 3
scenarios[3].step[4].train[0] = (8 | 48);
scenarios[3].step[4].eoma[1] = 2;
scenarios[3].step[4].shadowtimerB[1] = 1;
//step 4
scenarios[3].step[5].train[0] = (8 | 48);
scenarios[3].step[5].eoma[1] = 3;
scenarios[3].step[5].train[1] = (8);
scenarios[3].step[5].shadowtimerB[1] = 1;

//step 5
scenarios[3].step[6].train[0] = (2);//step 5
scenarios[3].step[6].eoma[1] = 4;
scenarios[3].step[6].train[1] = (8);//step 5
scenarios[3].step[6].shadowtimerB[1] = 1;
scenarios[3].step[6].mutetimer[0] = 1;
//step 6
scenarios[3].step[7].train[0] = (8 | 48);
scenarios[3].step[7].train[1] = (8);
scenarios[3].step[7].eoma[1] = 5;
scenarios[3].step[7].shadowtimerB[1] = 1;
//step 7
scenarios[3].step[8].train[1] = (8);
scenarios[3].step[8].train[0] = (3 | 48);
scenarios[3].step[8].eoma[1] = 6;
scenarios[3].step[8].shadowtimerA[1] = 1;
//step 8
scenarios[3].step[9].train[0] = (48);



////////////////////////////////////////////////
//////////////// Scenario 4 ////////////////////
////////////////////////////////////////////////

scenarios[4].step[0].train[0] = (1 | 48);
scenarios[4].step[0].eoma[0] = 3;
scenarios[4].step[0].eom[0] = 3;
scenarios[4].step[0].integritylosstimer[0] = 1;
scenarios[4].step[0].mutetimer[0] = 1;
//step 1
scenarios[4].step[1].train[0] = (5);
scenarios[4].step[1].integritylosstimer[0] = 2;
scenarios[4].step[1].mutetimer[0] = 2;
//step 2
scenarios[4].step[2].train[0] = (6 | 48);
//step 3
scenarios[4].step[3].train[0] = (8 | 48);
//step 4
scenarios[4].step[4].train[0] = (2 | 48);
scenarios[4].step[5].train[0] = (3 | 0);
scenarios[4].step[5].shadowtimerA[0] = 1;
scenarios[4].step[6].train[0] = (48);
scenarios[4].step[6].shadowtimerA[0] = 1;
//steps 5 and 6
scenarios[4].step[7].train[0] = (8 | 48);
//step 7
scenarios[4].step[8].train[0] = (5);
scenarios[4].step[8].disconnecttimer[3] = 1;
//step 8
scenarios[4].step[9].disconnecttimer[3] = 2;



////////////////////////////////////////////////
//////////////// Scenario 5 ////////////////////
////////////////////////////////////////////////

scenarios[5].step[0].train[0] = (1 | 48);//train 0 is spawned
scenarios[5].step[0].eoma[0] = 9;
scenarios[5].step[1].train[0] = (8 | 48);//move to the first VSS of the specifications scenario
//steps 1 and 2
scenarios[5].step[2].train[0] = (7 | 16);//train splits
scenarios[5].step[2].eoma[1] = 1;
scenarios[5].step[2].integritylosstimer[1] = 3;
//step 3
scenarios[5].step[3].train[0] = (8 | 16);
scenarios[5].step[3].integritylosstimer[1] = 3;
//step 4
scenarios[5].step[4].train[0] = (8 | 48);
scenarios[5].step[4].eoma[1] = 2;
scenarios[5].step[4].integritylosstimer[1] = 4;
//step 5
scenarios[5].step[5].train[0] = (8 | 48);
scenarios[5].step[5].eoma[1] = 3;
//step 6
scenarios[5].step[6].train[0] = (2 | 48);
//step 7
//We partially support step 7, as we do not model the delay time
//of the TTD detection system (i.e., we free the TTD section as
//soon as the train leaves it). See section 4.2 ("Delay in TTD processing")
//in the paper.
scenarios[5].step[7].train[0] = (3);
scenarios[5].step[7].eoma[1] = 4;
scenarios[5].step[7].shadowtimerB[1] = 1;
scenarios[5].step[8].train[0] = (48);
scenarios[5].step[8].shadowtimerB[1] = 1;
//step 8
scenarios[5].step[9].train[0] = (48);



////////////////////////////////////////////////
//////////////// Scenario 6 ////////////////////
////////////////////////////////////////////////

scenarios[6].step[0].train[0] = (1 | 48);//train 0 is spawned
scenarios[6].step[0].eoma[0] = 3;
//step 1
scenarios[6].step[1].train[0] = (8 | 48);//move to the first VSS of the specifications scenario
//step 2
scenarios[6].step[2].train[0] = (5);//connection lost
scenarios[6].step[2].mutetimer[0] = 1;
//step 3
scenarios[6].step[3].mutetimer[0] = 2;//mute timer expires
scenarios[6].step[3].disconnecttimer[0] = 1;
//step 4
scenarios[6].step[4].train[0] = (8);
scenarios[6].step[4].mutetimer[0] = 2;
scenarios[6].step[4].disconnecttimer[1] = 1;
//step 5
scenarios[6].step[5].train[0] = (8);
scenarios[6].step[5].mutetimer[0] = 2;
scenarios[6].step[5].disconnecttimer[1] = 2;
//step 6
scenarios[6].step[6].train[0] = (6 | 48);
scenarios[6].step[6].eoma[0] = 4;
//step 7
scenarios[6].step[7].train[0] = (8 | 48);
scenarios[6].step[7].eoma[0] = 5;
scenarios[6].step[7].shadowtimerA[1] = 1;
//step 8
scenarios[6].step[8].train[0] = (8 | 48);
scenarios[6].step[8].shadowtimerA[1] = 1;
//step 9
scenarios[6].step[9].train[0] = (48);
scenarios[6].step[9].shadowtimerA[1] = 1;


////////////////////////////////////////////////
//////////////// Scenario 7 ////////////////////
////////////////////////////////////////////////

scenarios[7].step[0].train[0] = (1 | 48);//train 0 is spawned
scenarios[7].step[0].eoma[0] = 6;
scenarios[7].step[1].train[0] = (8 | 48);
//step 1
scenarios[7].step[2].train[0] = (8 | 48);
//step 2
scenarios[7].step[3].train[0] = (8 | 48);
//step 3
scenarios[7].step[4].train[0] = (5);
scenarios[7].step[4].mutetimer[0] = 1;
//step 4
scenarios[7].step[5].train[0] = (8);
scenarios[7].step[5].mutetimer[0] = 2;
//step 5
scenarios[7].step[6].train[0] = (2);
scenarios[7].step[6].mutetimer[0] = 2;
//step 6
scenarios[7].step[7].train[0] = (6 | 48);
scenarios[7].step[7].mutetimer[0] = 1;
//step 7
scenarios[7].step[8].train[0] = (3 | 48);
//step 8
scenarios[7].step[9].train[0] = (8 | 48);


////////////////////////////////////////////////
//////////////// Scenario 8 ////////////////////
////////////////////////////////////////////////

scenarios[8].step[0].train[0] = (1 | 48);//train 0 is spawned
scenarios[8].step[0].eoma[0] = 9;
scenarios[8].step[1].train[0] = (8 | 48);
//step 1
scenarios[8].step[2].train[1] = (1 | 48);//train 1 is spawned
scenarios[8].step[2].eoma[1] = 1;
scenarios[8].step[2].train[0] = (48);
//step 2
scenarios[8].step[3].train[0] = (48);
scenarios[8].step[3].train[1] = (2 | 48);
//step 3
scenarios[8].step[4].train[0] = (8 | 48);
scenarios[8].step[4].train[1] = (3 | 48);
//step 4
scenarios[8].step[5].train[0] = (8 | 48);
scenarios[8].step[6].train[0] = (8 | 48);
scenarios[8].step[6].train[1] = (48);
scenarios[8].step[6].eoma[1] = 2;
//step 5
scenarios[8].step[7].train[0] = (8 | 48);
scenarios[8].step[7].train[1] = (8 | 48);
//scenarios[8].step[8].train[0] = (48);
scenarios[8].step[8].train[1] = (48);
scenarios[8].step[8].shadowtimerA[0] = 1;
//step 6
scenarios[8].step[9].train[0] = (8 | 48);
scenarios[8].step[9].train[1] = (8 | 48);
scenarios[8].step[10].train[0] = (8 | 48);
scenarios[8].step[10].train[1] = (48);
scenarios[8].step[10].shadowtimerA[0] = 1;
//step 7
scenarios[8].step[11].train[0] = (8 | 48);
scenarios[8].step[11].train[1] = (8 | 48);
scenarios[8].step[11].shadowtimerB[1] = 1;
scenarios[8].step[12].train[0] = (4);
scenarios[8].step[12].train[1] = (48);
scenarios[8].step[12].shadowtimerB[1] = 1;
//step 8
scenarios[8].step[13].train[1] = (8 | 16);



////////////////////////////////////////////////
//////////////// Scenario 9 ////////////////////
////////////////////////////////////////////////

scenarios[9].step[0].train[0] = (1 | 48);//train 0 is spawned
scenarios[9].step[0].eoma[0] = 9;
scenarios[9].step[1].train[0] = (8 | 48);
scenarios[9].step[2].train[0] = (8 | 48);
scenarios[9].step[3].train[0] = (8 | 48);
//step 1
scenarios[9].step[4].train[0] = (8 | 48);
//step 2
scenarios[9].step[5].train[1] = (1);//spawn train
scenarios[9].step[5].ghosttimer = 1;//ghost timer is started
//step 3
//in step 3, VSSs 2 and 3 should become UNKNOWN by 1F, and VSS 4 should become AMBIGUOUS by 8B
//rule 8B says that "the VSS in rear is UNKNOWN": however, the VSS in rear becomes UNKNOWN in this step.
//Do we assume an order of evaluation of the VSSs?
//See section 4.2 ("Order of update") in the paper.
scenarios[9].step[6].train[0] = 48;//train 0 reports
scenarios[9].step[6].ghosttimer = 2;//ghost timer expires
scenarios[9].step[6].train[1] = 5; //trains 1 disconnects
scenarios[9].step[6].eoma[1] = 3;
//step 4
scenarios[9].step[7].train[0] = (2 | 48);//train 0 moves and reports
scenarios[9].step[7].train[1] = (8);//train 1 moves without reporting
//step 5
scenarios[9].step[8].train[0] = (3);
scenarios[9].step[8].shadowtimerA[0] = 1;
scenarios[9].step[9].train[0] = (48);
scenarios[9].step[9].shadowtimerA[0] = 1;
scenarios[9].step[9].shadowtimerA[1] = 1;
scenarios[9].step[10].train[0] = (8 | 48);
scenarios[9].step[10].train[1] = (48);
scenarios[9].step[10].shadowtimerA[0] = 1;
scenarios[9].step[10].shadowtimerA[1] = 1;
//step 6
scenarios[9].step[11].train[0] = (2 | 48);
scenarios[9].step[11].train[1] = (6 | 48);
scenarios[9].step[11].shadowtimerA[0] = 1;
scenarios[9].step[11].shadowtimerA[1] = 1;
//step 7
scenarios[9].step[12].train[0] = (4);
scenarios[9].step[12].train[1] = (8 | 48);
scenarios[9].step[12].shadowtimerA[0] = 1;
scenarios[9].step[12].shadowtimerA[1] = 1;
scenarios[9].step[13].train[1] = 48;
scenarios[9].step[13].shadowtimerA[0] = 1;
scenarios[9].step[13].shadowtimerA[1] = 1;
//step 8
scenarios[9].step[14].train[1] = (8 | 16);
scenarios[9].step[15].train[1] = (16); 
scenarios[9].step[15].integritylosstimer[2] = 4;
}