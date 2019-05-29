//////////////////////////////////////////
// parametrization
//////////////////////////////////////////

#ifndef dsl
// number of VSSs
#define VSSCOUNT 10
// number of TTDs
#define TTDCOUNT 4
// number of trains
#endif

#define TRAINCOUNT 2

// the number of scenario to be used, if undefined, no particular scenario is considered
// #define sce 2

#ifdef sce
#include "scenarios.pml"
// the current step of the scenario, initially 0
byte st;
#endif



//////////////////////////////////////////
// Types and vars
//////////////////////////////////////////

// scheduling between the Trackside and Reality process
mtype = {REALITY, TRACKSIDE};
mtype schedule = REALITY;
																	 
// status of a VSS
mtype = {FREE, OCCUPIED, AMBIGUOUS, UNKNOWN};

// type of the train - for the DSL mode
mtype = {FAST, SLOW}

typedef VSS {
	mtype state;
	byte ttd;
}

#ifndef dsl
// the computed state of VSS - the way it works in practice
VSS vss[VSSCOUNT];	

// representation of the real position of trains, just taking values FREE and OCCUPIED
VSS real[VSSCOUNT];
#endif

#ifndef dsl
byte shadowtimerA[TTDCOUNT];
byte shadowtimerB[TTDCOUNT];
#endif


// TTD type
mtype = {TTDFREE, TTDOCCUPIED};
typedef TTDSection {
	byte firstVSS;
	mtype state;
	// contains a ghost train
	bool ghost;
		
	//this is used just for dsl initialization of VSS
	byte _lastVSS; 

}

#ifndef dsl
// TTDs, they are ordered and should be correctly mapped
TTDSection ttd[TTDCOUNT];
#endif

// train
typedef Train {
	// index of the real VSS where the trains starts
	byte front;
	// index of the last real VSS the train occupies
	byte rear;
	// is the train connected
	bool connected;
	// is the train integer
	bool integer;
	// is alive
	bool alive;
	// end of movement authority
	byte eoma;
	// last reported front end position, 255 otherwise (at the beginning and if there was no report on leaving a vss)
	byte reportedposition;
	// last reported integrity, 255 otherwise (at the beginning and if there was no report on leaving a vss)
	byte reportedintegrity;
	// is the train integer?
	bool reportedinteger;
	// index of the last left vss, 255 otherwise (at the beginning and if there was no report on leaving a vss)
	byte reportedleftvss; 
	// reported length in VSS
	byte reportedlength;
	// the train has reported the last cycle
	bool hasreported;
	// End of Mission
	byte eom;
	//Length status - 
	//   0 - train length has not changed since last report
	//   1 - train length has changed since last report but not reported
	//   2 - changed train length reported
	byte reportedchangedlength;
	// 0, 1, 2 as length status	
	byte reportedchangedconnection;
	// state of the VSS at the previously reported position
	mtype vssstateafterlastreport;
	// type of the train
	mtype type;
}

Train trains[TRAINCOUNT];

#ifdef dsl
#include "usecase.pml"
byte st;
#endif


bool rnd;
byte trainrnd;

inline setrnd() {
	if
		::rnd = true;
		::rnd = false;		
	fi		
}

inline settrainrnd() {
	byte _r
	trainrnd = 0;
	
	for (_r : 1 .. TRAINCOUNT) {
		if
			::trainrnd = _r;
			::skip -> break;
		fi
	}

}


// number of trains on the railway
byte alive = 0;


//////////////////////////////////////////
// Processes
//////////////////////////////////////////

// printing the state of the railway and trains
inline printreal() {
	byte curtrain;
	byte it;
	
	d_step {
			
	for (it : 0 .. TRAINCOUNT - 1) {
		if 
			:: trains[it].alive -> printf("Train "); 
			   printf("%c", 'A' + it); 
			   printf(" - eoma: %d\n", trains[0].eoma);
			:: else -> skip;
		fi
	}
	
	printf("\n");
 
	if 
		:: alive > 1 -> curtrain = alive - 1;
		:: else -> curtrain = 0;
	fi;

	for ( it : 0 .. VSSCOUNT - 1 ) {
		if
			:: it >= trains[curtrain].rear && it <= trains[curtrain].front ->
				if
					:: trains[curtrain].connected -> printf("%c", 'A' + curtrain);
					:: else -> printf("%c", 'a' + curtrain);
				fi;
				if
				// is there the other train as well as a result of train splitting?
					::curtrain > 0 && it >= trains[curtrain - 1].rear && it <= trains[curtrain - 1].front ->
					if
						:: trains[curtrain - 1].connected -> printf("%c", 'A' + curtrain - 1);
						:: else -> printf("%c", 'a' + curtrain - 1);
					fi
					::else -> skip;				
				fi;
				if
					:: it == trains[curtrain].front -> 
					if
					   :: curtrain > 0 -> curtrain--;
					   :: else -> break;
					fi
		            :: else -> skip;
		    fi;
    
		    :: else -> skip;
		fi;
    printf("\t");
	}

    printf("\n");
	
	
	for(it : 0 .. VSSCOUNT - 1) {
		if
			:: vss[it].state == FREE -> printf("F\t");
			:: vss[it].state == OCCUPIED -> printf("O\t");
			:: vss[it].state == UNKNOWN -> printf("U\t");
			:: vss[it].state == AMBIGUOUS -> printf("A\t");
		fi
	}

	printf("\n");
	
	for(it : 0 .. VSSCOUNT - 1) {
		if
			:: ttd[vss[it].ttd].state == TTDFREE -> printf("F\t");
			:: ttd[vss[it].ttd].state == TTDOCCUPIED -> printf("O\t");
		fi
	}

	printf("\n");
	
	for(it : 0 .. VSSCOUNT - 1) {
		printf("%d\t", vss[it].ttd)
	}

	printf("\n____________________________________________________________________________\n\n");
	
	}	 		
}

//////////////////////////////////////////
// Trackside	
//////////////////////////////////////////

// updates the state of the (computed) VSS if necessary according to the state machine in Fig.7 of the spec

#define ttdstate ttd[real[i].ttd].state

inline checktrainpresentonpreviousttd() {
	trainpresentonpreviousttd = false;
	for ( ti : 0 .. TRAINCOUNT - 1 ) {
		if
			:: (trains[ti].alive) && (trains[ti].reportedposition < VSSCOUNT) &&
				(trains[ti].reportedposition != 255 &&
					(vss[trains[ti].reportedposition].ttd == vss[i].ttd - 1 ||
						(trains[ti].reportedlength !=255 &&
							vss[trains[ti].reportedposition-trains[ti].reportedlength].ttd == vss[i].ttd - 1)))
				-> 
				trainpresentonpreviousttd = true; break;
			:: else -> skip;
		fi
	}
}

inline checktrainpresentonttd() {
	trainpresentonttd = false;
	for ( ti : 0 .. TRAINCOUNT - 1 ) {
		/*
		if
			:: (real[trains[ti].front].ttd == vss[i].ttd) ||
				 (real[trains[ti].rear].ttd == vss[i].ttd) ->
				trainpresentonttd = true; break;
			:: else -> skip;
		fi
		*/
		
		if 
			:: (mutetimer[ti] != 0) && 
			   ((trains[ti].reportedposition != 255 &&	((vss[trains[ti].reportedposition].ttd == vss[i].ttd - 1) ||
			  	(trains[ti].reportedlength !=255 &&	vss[trains[ti].reportedposition - trains[ti].reportedlength].ttd == vss[i].ttd - 1)))) 
					->
					trainpresentonttd = true; break;
			:: else -> skip;
		fi
		
		
		if
			:: (trains[ti].alive) && (trains[ti].reportedposition < VSSCOUNT) &&
				(trains[ti].reportedposition != 255 &&
					(vss[trains[ti].reportedposition].ttd == vss[i].ttd ||
						(trains[ti].reportedlength !=255 &&
							vss[trains[ti].reportedposition - trains[ti].reportedlength].ttd == vss[i].ttd)))
				->
				trainpresentonttd = true; break;
			:: else -> skip;
		fi
	}
}

inline checktrainidonvss(_vss) {
	trainidonvss = 255;
	for ( ti : 0 .. TRAINCOUNT - 1 ) {
		if 
			:: trains[ti].alive && (trains[ti].reportedposition == _vss || ((trains[ti].reportedposition - trains[ti].reportedlength) == _vss)) -> trainidonvss = ti; break;
			:: else -> skip;
		fi
	}
}

inline checktrainidonpreviousttd() {
	trainidonpreviousttd = 255;
	for ( ti : 0 .. TRAINCOUNT - 1 ) {
		if 
			:: (trains[ti].alive) && (trains[ti].reportedposition < VSSCOUNT) && (vss[trains[ti].reportedposition].ttd == vss[i].ttd - 1 || vss[trains[ti].reportedposition - trains[ti].reportedlength].ttd == vss[i].ttd - 1) -> 
					trainidonpreviousttd = ti; break;
			:: else -> skip;
		fi
	}
}

inline checkfreeorunknown(_i,_j) {
	freeorunknown = true;
	if
		:: _i == 255 -> freeorunknown = false;
		:: _i <= _j -> 
			for ( ti : _i + 1 .. _j - 1 ) {
				if
					:: ((vss[ti].state != FREE) && (vss[ti].state != UNKNOWN)) -> freeorunknown = false; break;
					:: else -> skip;
				fi
			}
		:: (_i != 255) && (_j < _i) ->
			for ( ti : _j + 1 .. _i - 1 ) {
				if
					:: ((vss[ti].state != FREE) && (vss[ti].state != UNKNOWN)) -> freeorunknown = false; break;
					:: else -> skip;
				fi
			}
	fi
}

//"there is(/are) only FREE or UNKNOWN VSS or none between this VSS and the TTD for which the "ghost train propagation timer" is expired"
//and "VSS is not located on the TTD for which the timer is expired"
// for #12A
inline checkfreeinfrontofunknown() {
	freeinfrontofunknown = true;
	ti = i; 
	do
		:: ti > 0 && vss[ti].state == FREE && ttd[vss[ti].ttd].state == TTDOCCUPIED -> break;
		:: ti > 0 && vss[ti].state == UNKNOWN -> ti = ti - 1;
		:: ti == 0 -> break;
		:: else -> freeinfrontofunknown = false; break;
	od
}

//in rear of this VSS and subsequent VSS(s) that had become "unknown" because of the lost connection of this train is a "free" VSS on the same TTD as the train is located on
inline checkfreeinfrontofunknwononthisttd() {
	freeinfrontofunknownthisttd = false;
	if
		:: i > 0 ->
			ti = i - 1;
			do
				:: vss[i].ttd != vss[ti].ttd -> break;
				:: vss[i].ttd == vss[ti].ttd && vss[ti].state == UNKNOWN ->
					if
						:: ti == 0 -> break;
						:: else -> ti = ti - 1;
					fi
				:: vss[i].ttd == vss[ti].ttd && vss[ti].state == FREE ->
					freeinfrontofunknownthisttd = true;	break;
				:: else -> break;
			od
		:: else -> skip;
	fi
}

inline checkghost(_i) {
	freeorunknownghost1 = false;

	if
		:: i > 0 -> 
			ti = _i - 1;
			do
				:: !ttd[vss[ti].ttd].ghost && ti > 0 && (vss[ti].state == FREE || vss[ti].state == UNKNOWN) -> ti = ti - 1; 
				:: !ttd[vss[ti].ttd].ghost && (ti == 0 || (vss[ti].state != FREE && vss[ti].state != UNKNOWN)) -> break;
				:: ttd[vss[ti].ttd].ghost ->
					if
						:: vss[ti].ttd != vss[_i].ttd -> freeorunknownghost1 = true;
						:: else -> skip;
					fi
					break;
			od
		:: else -> skip;
	fi
}

#define log(_msg) 	printf("VSS%d: ", i);	printf(_msg)


#define rule2A (ttdstate == TTDOCCUPIED) && (trainidonvss != 255) &&  (trains[trainidonvss].vssstateafterlastreport == OCCUPIED) && (vss[trains[trainidonvss].reportedposition].state != UNKNOWN)

// TTD in rear is free
// train location is on the previous TTD
// train location is not on the TTD
// VSS is the first VSS of the TTD
// VSS is part of the MA sent to this train
#define rule2B (ttdstate == TTDOCCUPIED) && (vss[i].ttd > 0 && ttd[vss[i].ttd-1].state == TTDFREE) && trainpresentonpreviousttd && (!trainpresentonttd) && (vss[i].ttd != vss[i-1].ttd) &&  (trains[trainidonvss].vssstateafterlastreport == OCCUPIED) && (trains[trainidonpreviousttd].eoma >= i)

//"integer train reconnects within the same session".
//VSS is part of the MA sent to this train
//VSS in advance of the VSS where the reconnected train is located
#define rule4B(_trainid) trains[_trainid].reportedinteger && trains[_trainid].hasreported && mutetimer[_trainid] == 1 && trains[_trainid].reportedchangedconnection == 2 && (trains[_trainid].eoma >= i) && (trains[_trainid].reportedposition < i)

#define rule4C(_trainid) trains[_trainid].reportedinteger && trains[_trainid].hasreported && mutetimer[_trainid] == 1 && trains[_trainid].reportedchangedlength == 0 && freeinfrontofunknownthisttd && i < (trains[_trainid].reportedposition - trains[_trainid].reportedlength) && (trains[_trainid].alive && (real[trains[_trainid].front].ttd == vss[i].ttd || real[trains[_trainid].rear].ttd == vss[i].ttd)) 

//train is located on the VSS
//mute timer is expired OR EoM
#define rule7A trainidonvss != 255 && ((mutetimer[0] == 2 && trainidonvss == 0) || (mutetimer[1] == 2 && trainidonvss == 1) || (trains[trainidonvss].alive && trains[trainidonvss].eom == i && trains[trainidonvss].reportedlength == 0))

//train has reported to have left the VSS
//train reports lost integrity
//PTD with no integrity information is received outside the integrity waiting period
//train reports changed train data length
#define rule7B ((trains[0].alive && (trains[0].hasreported && trains[0].reportedleftvss == i) && ((!trains[0].reportedinteger && integritylosstimer[i] == 2) || trains[0].reportedchangedlength == 2)) || (trains[1].alive && (trains[1].hasreported && trains[1].reportedleftvss == i) && ((!trains[1].reportedinteger && integritylosstimer[i] == 4) || trains[1].reportedchangedlength == 2) ))

#define rule12A ((mutetimer[0] == 1 && trainidonvss == 0 && trains[0].reportedchangedconnection == 2) || (mutetimer[1] == 1 && trainidonvss  == 1 && trains[1].reportedchangedconnection == 2)) && freeinfrontofunknown

#define rule12B (ttdstate == TTDOCCUPIED) && (trainidonvss != 255) && (trains[trainidonvss].vssstateafterlastreport == OCCUPIED) && (mutetimer[trainidonvss] == 1)  && vss[trains[trainidonvss].reportedposition].state != UNKNOWN


inline startShadowtimerB(i) {
//shadowtimer B
#ifdef sce		
	skip;
#else 
		if
			:: (vss[i].ttd < TTDCOUNT - 1) && (ttd[vss[i].ttd + 1].firstVSS - 1 == i) -> shadowtimerB[vss[i].ttd] = 1;
			:: else -> skip
		fi
#endif
}

#include "asserts.pml"

inline updateVSS(i) {
	
	checktrainpresentonttd();
	checktrainpresentonpreviousttd();

	if 
		:: trains[0].alive && !trains[0].hasreported && (trains[0].reportedposition < VSSCOUNT) && (disconnecttimer[trains[0].reportedposition] == 2) ->
				checkfreeorunknown(trains[0].reportedposition, i);
				freeorunknown0 = freeorunknown;
		:: else -> freeorunknown0 = false;
	fi

	if 
		:: trains[1].alive && !trains[1].hasreported && (trains[1].reportedposition < VSSCOUNT) && (disconnecttimer[trains[1].reportedposition] == 4) ->
				checkfreeorunknown(trains[1].reportedposition, i);
				freeorunknown1 = freeorunknown;
		:: else -> freeorunknown1 = false;
	fi
	
	if 
		:: trains[0].alive && !trains[0].reportedinteger && (trains[0].reportedintegrity < VSSCOUNT) && (integritylosstimer[trains[0].reportedintegrity] == 2) ->
				checkfreeorunknown(trains[0].reportedintegrity, i);
				freeorunknownint0 = freeorunknown;
		:: else -> freeorunknownint0 = false;
	fi

	if 
		:: trains[1].alive && !trains[1].reportedinteger && (trains[1].reportedintegrity < VSSCOUNT) && (integritylosstimer[trains[1].reportedintegrity] == 4) ->
				checkfreeorunknown(trains[1].reportedintegrity, i);
				freeorunknownint1 = freeorunknown;
		:: else -> freeorunknownint1 = false;
	fi
	
	checkghost(i);
	checktrainidonvss(i);
	
	// this is necessary, because we overwrite the state of the previous vss to, e.g., OCCUPIED, and in consequence for this vss this is wrongly set to false.
	if
		:: (i > 0) && (freeinfrontofunknown) && (vss[i].state == UNKNOWN) ->skip;
		:: else -> checkfreeinfrontofunknown();
	fi
	
	//printf("Freeinfrontofunknown %d %d\n", i, freeinfrontofunknown);
	
	checkfreeinfrontofunknwononthisttd();
	


	if
		:: vss[i].state == FREE ->
			assertFREE(i);
			if
				// #1A
				:: (ttdstate == TTDOCCUPIED) &&
					//(no FS MA is issued or no train is located on this TTD)
					((trains[0].alive && trains[0].eoma < 10 && vss[trains[0].eoma].ttd < vss[i].ttd && trains[1].eoma < 10 && vss[trains[1].eoma].ttd < vss[i].ttd)
					||
					!trainpresentonttd) ->
						vss[i].state = UNKNOWN;
						log("transition #1A taken\n");
						//printf("%d\n", trainpresentonttd);

				// #1B
				:: (ttdstate == TTDOCCUPIED) &&
					((trains[0].alive && !trains[0].hasreported && trains[0].reportedposition <= i && trains[0].eoma >= i && mutetimer[0] == 2) || 
					 (trains[1].alive && !trains[1].hasreported && trains[1].reportedposition <= i && trains[1].eoma >= i && mutetimer[1] == 2)) &&
					//VSS is located in advance of the VSS where the train was last reported - have to check both trains
					(((trains[0].alive && trains[0].reportedposition < i) && (trains[0].eoma >= i) && (!trains[0].hasreported)) || ((trains[1].alive && trains[1].reportedposition < i) && (trains[1].eoma >= i) && !trains[1].hasreported)) -> 
						vss[i].state = UNKNOWN;
						log("transition #1B taken\n");

				// #1C
				:: (ttdstate == TTDOCCUPIED) &&			
					((!trains[0].connected && // disconnecttimer[i] == 2 &&
					//VSS is located on the same TTD as the VSS for which the timer is expired
					(trains[0].alive && trains[0].reportedposition != 255 ) &&
					(vss[i].ttd == vss[trains[0].reportedposition].ttd || (trains[0].reportedlength != 255 && vss[i].ttd == vss[trains[0].reportedposition - trains[0].reportedlength].ttd)) &&
					freeorunknown0) ||  
					(trains[1].alive && !trains[1].connected && // disconnecttimer[i] == 4 &&
					(trains[1].reportedposition != 255) &&
					(vss[i].ttd == vss[trains[1].reportedposition].ttd || (trains[1].reportedlength != 255 && vss[i].ttd == vss[trains[1].reportedposition - trains[1].reportedlength].ttd)) &&
					freeorunknown1)) ->	
						vss[i].state = UNKNOWN;
						log("transition #1C taken\n");


				// #1D
				:: (ttdstate == TTDOCCUPIED) &&
					((trains[0].alive && !trains[0].connected && 
					//VSS is not located on the same TTD as the VSS for which the timer is expired
					trains[0].reportedposition != 255 &&
					(trains[0].reportedlength != 255 && vss[i].ttd != vss[trains[0].reportedposition].ttd && vss[i].ttd != vss[trains[0].reportedposition - trains[0].reportedlength].ttd) &&
					freeorunknown0) ||
					(trains[1].alive && !trains[1].connected &&  
					//VSS is not located on the same TTD as the VSS for which the timer is expired
					trains[1].reportedposition != 255 &&
					(trains[1].reportedlength != 255 && vss[i].ttd != vss[trains[1].reportedposition].ttd && vss[i].ttd != vss[trains[1].reportedposition - trains[1].reportedlength].ttd) &&
					freeorunknown1)) &&
					//VSS is not part of an MA
					(trains[0].eoma < i || (trains[0].reportedposition - trains[0].reportedlength) > i) && (trains[1].eoma < i || (trains[1].reportedposition - trains[1].reportedlength) > i) ->	
						vss[i].state = UNKNOWN;
						log("transition #1D taken\n");


				// #1E
				:: (ttdstate == TTDOCCUPIED) &&
					((trains[0].alive && !trains[0].reportedinteger && 
					//VSS is located on the same TTD as the VSS for which the "integrity loss propagation timer" is expired
					(vss[trains[0].reportedintegrity].ttd == vss[i].ttd) &&
					freeorunknownint0) ||
					(trains[1].alive && !trains[1].reportedinteger &&					
					//VSS is located on the same TTD as the VSS for which the "integrity loss propagation timer" is expired
					(vss[trains[1].reportedintegrity].ttd == vss[i].ttd) &&
					freeorunknownint1)) ->
						vss[i].state = UNKNOWN;
						log("transition #1E taken\n");

				// #1F
				:: (ttdstate == TTDOCCUPIED) &&
					ghosttimer == 2 &&
					freeorunknownghost1 && trains[1].alive // &&
					// trains[1].reportedposition < VSSCOUNT // &&
					//VSS is not located on the TTD for which the timer is expired
					//(vss[i].ttd != vss[trains[1].reportedposition].ttd && vss[i].ttd != vss[trains[1].reportedposition - trains[1].reportedlength].ttd) ->
						-> vss[i].state = UNKNOWN;
						log("transition #1F taken\n");


				// #2A
				:: rule2A ->
						vss[i].state = OCCUPIED;
						log("transition #2A taken\n");
						//printf("%e\n",trains[0].vssstateafterlastreport);

				// #2B
				:: rule2B ->
						vss[i].state = OCCUPIED;
						log("transition #2B taken\n");


				// #3A
				:: (ttdstate == TTDOCCUPIED) &&
					//train is located on the VSS
					trainidonvss != 255 &&
					//lower priority than #2: !(#2A || #2B)
					!(rule2A || rule2B) ->
						vss[i].state = AMBIGUOUS;
						log("transition #3A taken\n");

				// #3B
				:: (ttdstate == TTDOCCUPIED) &&
					// TTD in rear is free
					(vss[i].ttd > 0 && ttd[vss[i].ttd-1].state == TTDFREE) &&
					// train location is on the previous TTD
					trainpresentonpreviousttd &&
					// train location is not on the TTD
					(!trainpresentonttd) &&
					// VSS is the first VSS of the TTD
					(vss[i].ttd != vss[i-1].ttd) &&
					// VSS is part of the MA sent to this train
					trains[trainidonpreviousttd].eoma >= i &&

					//lower priority than #2: !(#2A || #2B)
					!(rule2A || rule2B) ->
						vss[i].state = AMBIGUOUS;
						log("transition #3B taken\n");

				// if none of the above applies, just stay in the current state
				:: else -> skip;
			fi

////////////////////////////////////////////////////

		:: vss[i].state == OCCUPIED ->
			assertOCCUPIED(i);
			if
				// #6A
				:: (ttdstate == TTDFREE) ->
						vss[i].state = FREE;
						log("transition #6A taken\n");

				// #6B
					//integer train has reported to have left the VSS
				:: trains[0].hasreported && trains[0].reportedinteger && trains[0].reportedleftvss >= i && trains[0].reportedleftvss != 255 &&
				   (!trains[1].alive || (real[trains[1].front].ttd < real[i].ttd))
						-> vss[i].state = FREE;
						// we have to "consume" the information
					  //  trains[0].reportedleftvss = 255;
						log("transition #6B taken\n");
						
				:: trains[1].hasreported && trains[1].reportedinteger && trains[1].reportedleftvss >= i && trains[1].reportedleftvss != 255 ->
						vss[i].state = FREE;
						// we have to "consume" the information
					  //  trains[1].reportedleftvss = 255;						
					   log("transition #6B taken\n");


				// #7A
				::	rule7A ->
						vss[i].state = UNKNOWN;
						log("transition #7A taken\n");

				// #7B
				:: rule7B ->
						vss[i].state = UNKNOWN;
						log("transition #7B taken\n");


				// #8A
				:: (//train is located on the VSS
					trainidonvss != 255 && trains[trainidonvss].hasreported &&
					(//train reports lost integrity
					!trains[trainidonvss].reportedinteger ||
					//PTD with no integrity information is received outside the integrity waiting period
					(!trains[trainidonvss].reportedinteger && ((trainidonvss == 0 && integritylosstimer[i] == 1) || (trainidonvss == 1 && integritylosstimer[i] == 3))) ||
					//train reports changed train data length
					trains[trainidonvss].reportedchangedlength == 2
					) &&
					//lower priority than #7: !(#7A || #7B)
					!(rule7A || rule7B)) ->
						vss[i].state = AMBIGUOUS;
						log("transition #8A taken\n");

				// #8B
					//train is located on the VSS
				::	trainidonvss != 255 &&
					//VSS in rear is UNKNOWN
					i > 0 && vss[i-1].state == UNKNOWN &&
					//lower priority than #7: !(#7A || #7B)
					!(rule7A || rule7B) ->
						vss[i].state = AMBIGUOUS;
						log("transition #8B taken\n");

				// #8C
					//another train is located on the VSS
				::	trainidonvss != 255 &&
					(trains[1-trainidonvss].alive && ((trains[1-trainidonvss].reportedposition == i) || (trains[1-trainidonvss].reportedposition - trains[1-trainidonvss].reportedlength == i))) &&
					//lower priority than #7: !(#7A || #7B)
					!(rule7A || rule7B) ->
						vss[i].state = AMBIGUOUS;
						log("transition #8C taken\n");

				// if none of the above applies, just stay in the current state
				:: else -> skip;
			fi
			
////////////////////////////////////////////////////

		:: vss[i].state == AMBIGUOUS ->
			assertAMBIGUOUS(i);
			if
				// #9A
				:: ttd[vss[i].ttd].state == TTDFREE ->
					vss[i].state = FREE;
					log("transition #9A taken\n");

				// #9B
				:: if
					::	//integer train has reported to have left the VSS
						(trains[0].hasreported &&
						trains[0].reportedinteger && trains[0].reportedlength != 255 &&
						trains[0].reportedleftvss != 255 && trains[0].reportedleftvss >= i &&
						shadowtimerA[vss[i].ttd] == 1 &&
						trains[1].alive && trains[1].reportedposition < i) ||
						(trains[1].alive && trains[1].hasreported &&
						trains[1].reportedinteger && trains[1].reportedlength != 255 &&
						trains[1].reportedleftvss != 255 && trains[1].reportedleftvss >= i &&
						shadowtimerA[vss[i].ttd] == 1)
						 ->
							vss[i].state = FREE;
							log("transition #9B taken\n");

					// #10A
					::	//VSS is left by all reporting trains
						(!trains[0].connected || trains[0].reportedposition < i || (trains[0].hasreported && trains[0].reportedleftvss >= i && trains[0].reportedleftvss != 255)) &&
						(!trains[1].connected || trains[1].reportedposition < i || (trains[1].hasreported && trains[1].reportedleftvss >= i && trains[1].reportedleftvss != 255)) 
						//trainidonvss == 255
						->							
							vss[i].state = UNKNOWN;
							log("transition #10A taken\n");
							startShadowtimerB(i);
							

					// #10B
					:: trainidonvss != 255 &&
						// mute timer expired or end of mission reached
						((trainidonvss == 0 && mutetimer[0] == 2) || (trainidonvss == 1 && mutetimer[1] == 2) || (trains[trainidonvss].eom == i && trains[trainidonvss].reportedlength == 0)) ->
							vss[i].state = UNKNOWN;
							log("transition #10B taken\n");
							startShadowtimerB(i);							
					 fi

				// #11A
				::	//(integer train located on the VSS reported to have left the TTD in rear)
					trainidonvss != 255 &&
					trains[trainidonvss].hasreported &&
					trains[trainidonvss].reportedleftvss == ttd[vss[i].ttd].firstVSS - 1 &&
					// the shadow train timer expiration if the TTD in rear was not expired at the moment of the position report  
					 // && the reported min-safe-rear-end of this train is within the distance.....
					 (vss[i].ttd > 0) &&
					 shadowtimerA[vss[i].ttd - 1] == 1
						-> vss[i].state = OCCUPIED;
						log("transition #11A taken\n");

				// #11B
				:: ((vss[i].ttd > 0 && ttd[vss[i].ttd-1].state == TTDFREE) || (vss[i].ttd == 0)) &&
					trainidonvss != 255 &&
				   (vss[i].ttd > 0) && (trains[trainidonvss].reportedleftvss >= ttd[vss[i].ttd].firstVSS - 1) && trains[trainidonvss].hasreported &&
				   (vss[i].ttd > 0) &&
					 (shadowtimerB[vss[i].ttd - 1] == 1)  
						-> vss[i].state = OCCUPIED;
						log("transition #11B taken\n");
						
				// if none of the above applies, just stay in the current state
				:: else -> skip;

			fi

////////////////////////////////////////////////////

		:: vss[i].state == UNKNOWN -> 
			assertUNKNOWN(i);
			if
				// #4A
				:: ttdstate == TTDFREE ->
					vss[i].state = FREE;
					log("transition #4A taken\n");

				// #4B train 0
				::	rule4B(0) ->
						vss[i].state = FREE;
						log("transition #4B taken\n");

				// #4B train 1
				:: 	rule4B(1) ->
						vss[i].state = FREE;
						log("transition #4B taken\n");

				// #4C train 0
				:: rule4C(0) ->
						vss[i].state = FREE;
						log("transition #4C taken\n");

				// #4C train 1
				:: rule4C(1) ->
						vss[i].state = FREE;
						log("transition #4C taken\n");

				// #12A
				:: rule12A &&
					//lower priority than #4: !(#4B || #4C)
					!(rule4B(0) || rule4B(1) || rule4C(0) || rule4C(1)) ->
						vss[i].state = OCCUPIED;
						log("transition #12A taken\n");

				// #12B
				:: rule12B &&
					//lower priority than #4: !(#4B || #4C)
					!(rule4B(0) || rule4B(1) || rule4C(0) || rule4C(1)) ->
						vss[i].state = OCCUPIED;
						log("transition #12B taken\n");

				// #5A
				 ::	trainidonvss != 255 && //NEW to model "train is located on the VSS": is it correct?
					(trains[trainidonvss].hasreported)  && //NEW 11/01/2018
					//lower priority than #12
					(!(rule12A || rule12B)) &&
					// not #4A - ASSUMPTION - this is not in the spec. table
					ttdstate != TTDFREE &&
					//lower priority than #4: !(#4B || #4C)
					!(rule4B(0) || rule4B(1) || rule4C(0) || rule4C(1)) ->
						vss[i].state = AMBIGUOUS;
						log("transition #5A taken\n");

				// if none of the above applies, just stay in the current state
				:: else -> skip;
			fi
	fi
}

#define printtimer(_timer, _name) 	if	:: ((_timer==1) || (_timer == 3)) -> printf("Timer "); printf(_name); printf(" running\n"); :: ((_timer==2) || (_timer == 4)) -> printf("Timer "); printf(_name); printf(" expired\n"); :: else -> skip;	fi
#define printtimerx(_timer, _name, _idx, _type) if	:: ((_timer==1) || (_timer == 3)) -> printf("Timer "); printf(_name); printf(" for "); printf(_type); printf("%d", _idx); printf(" running\n"); :: ((_timer==2) || (_timer == 4)) -> printf(_name); printf (" for "); printf(_type); printf("%d", _idx); printf(" expired\n"); :: else -> skip;	fi



proctype trackside() {
	do
	// trackside process runs just if it is scheduled
	::schedule == TRACKSIDE ->
		byte i;
		byte j

		byte mutetimer[2];
		byte disconnecttimer[VSSCOUNT];
		byte integritylosstimer[VSSCOUNT];
		byte ghosttimer;

		byte ti;
		bool trainpresentonttd;
		bool trainpresentonpreviousttd;
		bool freeorunknown;
		bool freeorunknown1;
		bool freeorunknown0;
		bool freeorunknownint1;
		bool freeorunknownint0;
		bool freeorunknownghost1;//only train 1 can be ghost
		byte trainidonvss;
		byte trainidonpreviousttd;
		bool freeinfrontofunknown;
		bool freeinfrontofunknownthisttd;
		
		mutetimer[0] = 1;
		mutetimer[1] = 1;	


#ifdef sce
		mutetimer[0] = scenarios[sce].step[st].mutetimer[0];
		mutetimer[1] = scenarios[sce].step[st].mutetimer[1];
		//disconnecttimer[0] = scenarios[sce].step[st].disconnecttimer[0];
		//disconnecttimer[1] = scenarios[sce].step[st].disconnecttimer[1];
		//integritylosstimer[0] = scenarios[sce].step[st].integritylosstimer[0];
		//integritylosstimer[1] = scenarios[sce].step[st].integritylosstimer[1];
		for ( ti : 0 .. VSSCOUNT - 1) {
			disconnecttimer[ti] = scenarios[sce].step[st].disconnecttimer[ti];
			integritylosstimer[ti] = scenarios[sce].step[st].integritylosstimer[ti];
		}

		for ( ti : 0 .. TTDCOUNT - 1) {
			shadowtimerA[ti] = scenarios[sce].step[st].shadowtimerA[ti];
			shadowtimerB[ti] = scenarios[sce].step[st].shadowtimerB[ti];
		}

		
		ghosttimer = scenarios[sce].step[st].ghosttimer;
#else

		for ( ti : 0 .. TRAINCOUNT - 1) {
			setrnd();
			if 
				:: trains[ti].hasreported || !trains[ti].alive -> mutetimer[ti] = 1;
				:: !trains[ti].hasreported && trains[ti].alive && mutetimer[ti] < 2 -> mutetimer[ti] = rnd + 1;
				:: else -> mutetimer[ti] = 2; 
			fi
		}

		// the semantics here is: 0, 1, 2  - not running, running, expired for train 0 and 0, 3, 4 for train 1
		for ( ti : 0 .. VSSCOUNT - 1) {
			setrnd();
			if 
				:: (mutetimer[0] == 2) && (!trains[0].connected) && (trains[0].reportedposition == ti) && (disconnecttimer[ti] == 0) -> disconnecttimer[ti] = 1;   
				:: (mutetimer[1] == 2) && (!trains[1].connected) && (trains[1].reportedposition == ti) && (disconnecttimer[ti] == 0) -> disconnecttimer[ti] = 3;
				:: (mutetimer[0] == 2) && (!trains[0].connected) && disconnecttimer[ti] == 1 -> disconnecttimer[ti] + rnd;  
				:: (mutetimer[1] == 2) && (!trains[1].connected) && disconnecttimer[ti] == 3 -> disconnecttimer[ti] + rnd;
				:: trains[0].connected && disconnecttimer[ti] <= 2 -> disconnecttimer[ti] = 0;
				:: trains[1].connected && disconnecttimer[ti] >= 3 -> disconnecttimer[ti] = 0;			
				:: else -> skip;
			fi
		}

		for ( ti : 0 .. VSSCOUNT - 1 ) {
			setrnd();
			if
				:: (trains[0].reportedposition == ti) && (vss[ti].state == OCCUPIED) && (integritylosstimer[ti] < 2) &&
					 ((!trains[0].reportedinteger) || (rnd) || (trains[0].reportedchangedlength == 2)) -> setrnd(); integritylosstimer[ti] = 1 + rnd;
				:: (trains[1].reportedposition == ti) && (vss[ti].state == OCCUPIED) && (integritylosstimer[ti] > 2) && (integritylosstimer[ti] < 4)
					 ((!trains[1].reportedinteger) || (rnd) || (trains[1].reportedchangedlength == 2)) -> setrnd(); integritylosstimer[ti] = 3 + rnd;
				:: (vss[ti].state == FREE) -> integritylosstimer[ti] = 0;
				:: (trains[0].reportedinteger) && (trains[0].reportedchangedlength == 0) && (integritylosstimer[ti] <= 2) -> integritylosstimer[ti] = 0;
				:: (trains[1].reportedinteger) && (trains[1].reportedchangedlength == 0) && (integritylosstimer[ti] >= 3) -> integritylosstimer[ti] = 0;
				:: (integritylosstimer[ti] == 1) && (!trains[0].reportedinteger) -> integritylosstimer[ti] = integritylosstimer[ti] + rnd;
				:: (integritylosstimer[ti] == 3) && (!trains[1].reportedinteger) -> integritylosstimer[ti] = integritylosstimer[ti] + rnd;
				:: else -> skip;				  
			fi
		}
	
		setrnd();
		if 
			:: !ttd[0].ghost && !ttd[1].ghost && !ttd[2].ghost -> ghosttimer = 0;
			:: ttd[0].ghost | ttd[1].ghost | ttd[2].ghost -> ghosttimer = rnd + ghosttimer;
			:: else -> ghosttimer = 2; 
		fi
		
		// shadowtimers started at the reality process and at VSS transitions #10
		for ( ti : 0 .. TTDCOUNT - 1 ) {		
			setrnd();
			if
				:: shadowtimerA[ti] == 1 && rnd -> shadowtimerA[ti] = 2;
				:: else -> skip;
			fi
		}

		for ( ti : 0 .. TTDCOUNT - 1 ) {		
			setrnd();
			if
				:: shadowtimerB[ti] == 1 && rnd -> shadowtimerB[ti] = 2;
				:: else -> skip;
			fi
		}
#endif

		if 
			:: (ghosttimer == 1) && (!ttd[real[trains[1].front].ttd].ghost) -> ttd[real[trains[1].front].ttd].ghost = true;
			:: else -> skip;
		fi
		
		d_step {
		
		printtimer(mutetimer[0], "mutetimer for train 0");
		printtimer(mutetimer[1], "mutetimer for train 1");
		printtimer(ghosttimer, "ghosttimer");
		for ( ti : 0 .. TTDCOUNT - 1 ) {		
			printtimerx(shadowtimerA[ti], "shadowtimerA", ti, "TTD");
		}
		
		for ( ti : 0 .. TTDCOUNT - 1 ) {		
			printtimerx(shadowtimerB[ti], "shadowtimerB", ti, "TTD");
		}

		for ( ti : 0 .. VSSCOUNT - 1 ) {		
			printtimerx(integritylosstimer[ti], "integritylosspropagationtimer", ti, "VSS");
		}

		for ( ti : 0 .. VSSCOUNT - 1 ) {		
			printtimerx(disconnecttimer[ti], "disconnectpropagationtimer", ti, "VSS");
		}

		}


		atomic {
			for (i : 0 .. VSSCOUNT - 1) {
				updateVSS(i);
			}
		}

	// Move the EoMA in front of the first non-free VSS
#if defined(sce)
		for (i : 0 .. TRAINCOUNT - 1) {
			if
				:: scenarios[sce].step[st].eoma[i] != 0 -> trains[i].eoma = scenarios[sce].step[st].eoma[i];
				:: else -> skip; 
			fi
		}

		for (i : 0 .. TRAINCOUNT - 1) {
			if
				:: scenarios[sce].step[st].eom[i] != 0 -> trains[i].eom = scenarios[sce].step[st].eom[i];
				:: else -> skip; 
			fi
		}
		
#elif defined(dsl)
		for (i : 0 .. TRAINCOUNT - 1) {
			if
				:: step[st].eoma[i] != 0 -> trains[i].eoma = step[st].eoma[i];
				:: else -> skip; 
			fi
		}

		for (i : 0 .. TRAINCOUNT - 1) {
			if
				:: step[st].eom[i] != 0 -> trains[i].eom = step[st].eom[i];
				:: else -> skip; 
			fi
		}

#else
		for (i : 0 .. TRAINCOUNT - 1) {
			if 
				:: (trains[i].alive) && (trains[i].eom > trains[i].eoma) && (trains[i].reportedposition != 255) -> 
						for ( j : trains[i].reportedposition + 1 .. VSSCOUNT - 1 ) {
							if 
								:: (j <= trains[i].eom) && ((vss[j].state == FREE)) &&
									//NEW the chasing train cannot have an eoma after the end of the chased train
									!(i > 0 && trains[i-1].alive && ((trains[i-1].reportedposition - trains[i-1].reportedlength)<=j)) ->
									trains[i].eoma = j;
								//:: j > trains[i].eom -> break;
								:: else -> break;
							fi
						}								
					:: else -> skip;
				fi
			}
#endif					

	  // at the end yield (or not) the execution to Reality
//	  if 
	  printreal();
#if defined(sce) || defined(dsl)
		st++;
	// check whether the simulation is over
		if
			:: st >= SIMULATIONSTEPS -> break;
			:: else -> skip;
		fi			
#endif
	  schedule = REALITY;
//	  	:: true -> skip;
//	  fi
	  	
	
	:: timeout -> break;
	od;	
}

//////////////////////////////////////////
// Reality
//////////////////////////////////////////


inline spawntrain(id) {
	printf("Train %c spawned\n", id + 'A');
	d_step {
			real[0].state = OCCUPIED;
			ttd[0].state = TTDOCCUPIED;
			trains[id].front = 0;
			trains[id].rear = 0;
			trains[id].hasreported = false;
			trains[id].eoma = 0;
			trains[id].reportedchangedlength = 0;
			if 
				:: trains[id].eom = VSSCOUNT - 1;
				:: trains[id].eom = VSSCOUNT;						
			fi 
		}
			//setrnd();
			//trains[id].connected = rnd;
			trains[id].connected = true;
			//setrnd();
	d_step{
			//trains[id].integer = rnd;
			trains[id].integer = true;
			trains[id].reportedlength = 0;
			trains[id].alive = true;
			trains[id].reportedintegrity = 0;
			trains[id].reportedposition = 255;
			trains[id].reportedinteger = true;
			trains[id].reportedleftvss = 255;
			trains[id].hasreported = false;
			trains[id].reportedchangedconnection = 0;
			trains[id].vssstateafterlastreport = OCCUPIED;
		}
}

inline trainreport(_id) {
	if
		::
#ifdef sce
				((scenarios[sce].step[st].train[_id] & 16) == 16) &&
#elif defined(dsl)
				((step[st].train[_id] & REPORTS) == REPORTS) &&
#endif
		    trains[_id].alive && trains[_id].connected ->
			if
				:: trains[_id].reportedchangedlength > 0 ->
					trains[_id].reportedchangedlength = (trains[_id].reportedchangedlength + 1) % 3;
				:: else -> skip; 
			fi
			
			if
				:: trains[_id].reportedchangedconnection > 0 -> 
				   trains[_id].reportedchangedconnection = (trains[_id].reportedchangedconnection + 1) % 3;
				:: else -> skip; 
			fi

			//setting the reportedleftvss has to be done when leaving the vss, not here, otherwise double reporting occurs
			if 
				:: trains[_id].reportedleftvss != 255  ->
					printf("Train %c reported having left VSS%d\n",  _id + 'A', trains[_id].reportedleftvss); 
				:: else -> skip;
			fi
			if 
				:: trains[_id].hasreported ->
					trains[_id].vssstateafterlastreport = vss[trains[_id].reportedposition].state;
					
				:: else -> skip;
			fi

			trains[_id].reportedposition = trains[_id].front;
						

			if
				::
#if defined(sce)
				((scenarios[sce].step[st].train[_id] & 32) == 32) -> 
					trains[_id].integer = true;
#elif defined(dsl)
				((step[st].train[_id] & REPORTSINT) == REPORTSINT) ->
					trains[_id].integer = true;

#else
				trains[_id].integer ->
#endif 
					trains[_id].reportedintegrity = trains[_id].front;
					trains[_id].reportedlength = trains[_id].front - trains[_id].rear;
					trains[_id].reportedinteger = true;
					printf("Train %c reported with integrity\n",  _id + 'A');

				:: else -> 
					trains[_id].reportedinteger = false;
					//trains[_id].reportedintegrity = trains[_id].front;
					
					//trains[_id].reportedintegrity = 255;
					//trains[_id].reportedlength = 255;
					printf("Train %c reported with NO integrity\n", _id + 'A');
			fi
			trains[_id].hasreported = true;


		:: 
#if defined(sce)
				((scenarios[sce].step[st].train[_id] & 16) == 0) &&

#elif defined(dsl)
				((step[st].train[_id] & REPORTS) == 0) &&
				
#endif
// non-deterministically not reporting		  
				trains[_id].alive -> 
				  trains[_id].hasreported = false;
				  trains[_id].reportedinteger = false;
			    printf("Train %c NOT reported\n", _id + 'A');
			
		:: else -> skip;
	fi
}

inline movingfront(id) {

#if !defined(sce) && !defined(dsl)
					// asserting the trains are not crashing into one another				
					assert(real[trains[id].front+1].state == FREE);
					
					// no moving beyond neither the EOMA nor EOM
					assert(trains[id].eoma > trains[id].front);
					assert(trains[id].eom > trains[id].front);
					assert(trains[id].eom >= trains[id].eoma);
#endif

					trains[id].front++;
					real[trains[id].front].state = OCCUPIED;
					ttd[real[trains[id].front].ttd].state = TTDOCCUPIED;
					
}

inline movingrear(id) {
					trains[id].rear++;
					trains[id].reportedleftvss = trains[id].rear - 1; 
					if
						// there is no chasing train just separated from this train on the same vss
						:: id < TRAINCOUNT - 1 && ((trains[id + 1].alive && trains[id + 1].front < trains[id].rear - 1) || !(trains[id + 1].alive)) ->
							real[trains[id].rear - 1].state = FREE;
							if
								:: ttd[real[trains[id].rear].ttd].firstVSS == trains[id].rear &&  real[trains[id].rear].ttd > 0 && ((trains[id + 1].alive && real[trains[id + 1].front].ttd < real[trains[id].rear - 1].ttd) || !(trains[id + 1].alive)) ->
										ttd[real[trains[id].rear - 1].ttd].state = TTDFREE;
										// shadowtimer A
#ifndef sce											
										if
											:: vss[trains[id].rear - 1].state == AMBIGUOUS -> 
											shadowtimerA[real[trains[id].rear - 1].ttd] = 1;
											:: else -> skip;
										fi
#endif
										
										
								:: else -> skip;
							fi 	

						:: id == TRAINCOUNT - 1 -> 
								real[trains[id].rear - 1].state = FREE;
								if 
									:: real[trains[id].rear - 1].ttd < real[trains[id].rear].ttd ->	ttd[real[trains[id].rear - 1].ttd].state = TTDFREE;
								:: else -> skip;
							fi
						:: else -> skip;
					fi
	
}

// assuming that the train can span over two VSS at most, i.e. train[id].front <= train[id].rear + 1
inline move(id) {

////////////////////////////////////////////////////////////////
#if defined(sce)

		if
		
		  // the train is allowed to move forward
		  ::
			((scenarios[sce].step[st].train[id] & 15) == 2) &&
			(trains[id].eoma > trains[id].front) &&  
			(trains[id].front < VSSCOUNT - 1) && (trains[id].front == trains[id].rear) ->
progress1:
					movingfront(id);
					printf("Moving front of train %c forward\n", id + 'A');

			// the real end of the train moves forward
			:: ((scenarios[sce].step[st].train[id]  & 15) == 3) &&
			trains[id].rear < trains[id].front ->
progress2:
					movingrear(id);
					printf("Moving rear of train %c forward\n", id + 'A');
					
			// both beginning and end move
			::
				((scenarios[sce].step[st].train[id] & 15) == 8) &&

 				(trains[id].front < VSSCOUNT - 1) ->
progress25:
					movingfront(id);
					movingrear(id);
										
					printf("Moving both front and rear of train %c forward\n", id + 'A');
					
			// the train moves outside the modeled railway, it disappears		
			:: ((scenarios[sce].step[st].train[id] & 15) == 4) ->
progress3:

					if
						:: ((trains[1 - id].alive && real[trains[1 - id].front].ttd < real[trains[id].rear].ttd) || !(trains[1 - id].alive)) ->
								ttd[real[trains[id].rear].ttd].state = TTDFREE;
						:: else -> skip;
					fi 	

					trains[id].alive = false;					
					real[trains[id].front].state = FREE;
					real[trains[id].rear].state = FREE;
					trains[id].front = VSSCOUNT;
					trains[id].rear = VSSCOUNT;


					printf("Train %c disappears\n", id + 'A');


			// the train disconnects
			:: ((scenarios[sce].step[st].train[id] & 15) == 5) && (trains[id].connected) ->
progress4:
					trains[id].connected = false;
					printf("Train %c disconnects\n", id + 'A');

			// the train reconnects
			:: ((scenarios[sce].step[st].train[id] & 15) == 6) && (!trains[id].connected) ->
progress5:			 			 
				trains[id].connected = true;
				trains[id].reportedchangedconnection = 1;
				printf("Train %c reconnects\n", id + 'A');
						
			// the train splits...
			::			
			((scenarios[sce].step[st].train[id] & 15) == 7) && (id == 0) && (alive < TRAINCOUNT) ->
progress6:			 								
					spawntrain(1);
					alive++;
					trains[0].reportedchangedlength = 1;
					trains[1].reportedchangedlength = 1;

					if 
						// different options to split the train
						:: trains[0].front > trains[0].rear ->
								if
									:: trains[0].rear = trains[0].front ->
											trains[1].rear = trains[0].rear;
											trains[1].front = trains[0].rear;
									:: trains[1].rear = trains[0].rear ->
											trains[1].front = trains[1].rear;
								fi;
						:: else ->
							trains[1].front = trains[0].front;
							trains[1].rear = trains[0].rear;
					fi;
					
					// we assume this from the scenario 5 - mention that it is not specified when a train looses its integrity
					trains[0].integer = false;
					trains[1].integer = false; 
					trains[1].connected = false;
					//trains[0].reportedintegrity = trains[0].reportedposition;
					trains[1].reportedintegrity = trains[0].reportedintegrity;
					trains[1].reportedposition = trains[0].rear;
					printf("Train splits\n");
					
		
			// losing integrity
			::
				((scenarios[sce].step[st].train[id] & 15) == 9) ->
progress7:
					trains[id].integer = false;

			// re-gaining integrity
			::
				((scenarios[sce].step[st].train[id] & 15) == 10) ->
progress8:
					trains[id].integer = true;

				// the train stays still
			:: else -> skip;
		fi


////////////////////////////////////////////////////////////////
#elif defined(dsl)

		if
			
		  // the train is allowed to move forward
			:: ((step[st].train[id] & (MOVESFRONT | MOVESREAR)) == MOVESFRONT) && (trains[id].front < VSSCOUNT - 1) && (trains[id].front == trains[id].rear) ->
progress1:
					movingfront(id);
					printf("Moving front of train %c forward\n", id + 'A');

			// the real end of the train moves forward
			:: ((step[st].train[id] & (MOVESFRONT | MOVESREAR)) == MOVESREAR) &&	trains[id].rear < trains[id].front ->
progress2:
					movingrear(id);
					printf("Moving rear of train %c forward\n", id + 'A');
					
			// both beginning and end move
			:: ((step[st].train[id] & (MOVESFRONT | MOVESREAR)) == (MOVESFRONT | MOVESREAR)) && (trains[id].front < VSSCOUNT - 1) ->
progress25:
					movingfront(id);
					movingrear(id);
										
					printf("Moving both front and rear of train %c forward\n", id + 'A');
					
			// the train moves outside the modeled railway, it disappears		
			:: ((step[st].train[id] & 7) == DISAPPEARS) ->
progress3:

					if
						:: ((trains[1 - id].alive && real[trains[1 - id].front].ttd < real[trains[id].rear].ttd) || !(trains[1 - id].alive)) ->
								ttd[real[trains[id].rear].ttd].state = TTDFREE;
						:: else -> skip;
					fi 	

					trains[id].alive = false;					
					real[trains[id].front].state = FREE;
					real[trains[id].rear].state = FREE;
					trains[id].front = VSSCOUNT;
					trains[id].rear = VSSCOUNT;


					printf("Train %c disappears\n", id + 'A');
					
			:: else -> skip;

		fi
		
		if
			// the train disconnects
			:: 
				((step[st].train[id] & 7) == DISCONNECTS) && trains[id].connected ->
progress4:
					trains[id].connected = false;
					printf("Train %c disconnects\n", id + 'A');

			// the train reconnects
			:: 	((step[st].train[id] & 7) == RECONNECTS) && !trains[id].connected ->
progress5:			 			 
				trains[id].connected = true;
				trains[id].reportedchangedconnection = 1;
				printf("Train %c reconnects\n", id + 'A');
						
			// the train splits - not supported in DSL mode

			// losing integriry
			:: ((step[st].train[id] & 7) == LOOSESINT) ->
progress7:
					trains[id].integer = false;

			// re-gaining integrity
			:: ((step[st].train[id] & 7) == GAINSINT) ->
progress8:
					trains[id].integer = true;

			// the train stays still
			:: else -> skip;
		fi



////////////////////////////////////////////////////////////////
#else
		if
		
		  // the train is allowed to move forward
		  :: (trains[id].eoma > trains[id].front) && (trains[id].front < VSSCOUNT - 1) && (trains[id].front == trains[id].rear) ->
progress1:
					movingfront(id);
					printf("Moving front of train %c forward\n", id + 'A');

			// the real end of the train moves forward
			:: trains[id].rear < trains[id].front ->
progress2:
					movingrear(id);
					printf("Moving rear of train %c forward\n", id + 'A');
					
			// both beginning and end move
			:: (trains[id].eoma > trains[id].front) && (trains[id].front < VSSCOUNT - 1) ->
progress25:
					movingfront(id);
					movingrear(id);
										
					printf("Moving both front and rear of train %c forward\n", id + 'A');
					
			// the train moves outside the modeled railway, it disappears		
			:: (trains[id].front == trains[id].rear) && (trains[id].front == VSSCOUNT - 1) ->
progress3:

					if
						:: ((trains[1 - id].alive && real[trains[1 - id].front].ttd < real[trains[id].rear].ttd) || !(trains[1 - id].alive)) ->
								ttd[real[trains[id].rear].ttd].state = TTDFREE;
						:: else -> skip;
					fi 	

					trains[id].alive = false;					
					real[trains[id].front].state = FREE;
					real[trains[id].rear].state = FREE;
					trains[id].front = VSSCOUNT;
					trains[id].rear = VSSCOUNT;


					printf("Train %c disappears\n", id + 'A');


			// the train disconnects
			:: trains[id].connected ->
progress4:
					trains[id].connected = false;
					printf("Train %c disconnects\n", id + 'A');

			// the train reconnects
			:: !trains[id].connected ->
progress5:			 			 
				trains[id].connected = true;
				trains[id].reportedchangedconnection = 1;
				printf("Train %c reconnects\n", id + 'A');
						
			// the train splits...
			::	(id == 0) && (alive < TRAINCOUNT) ->
progress6:			 								
					spawntrain(1);
					alive++;
					trains[0].reportedchangedlength = 1;
					trains[1].reportedchangedlength = 1;

					if 
						// different options to split the train
						:: trains[0].front > trains[0].rear ->
								if
									:: trains[0].rear = trains[0].front ->
											trains[1].rear = trains[0].rear;
											trains[1].front = trains[0].rear;
									:: trains[1].rear = trains[0].rear ->
											trains[1].front = trains[1].rear;
								fi;
						:: else ->
							trains[1].front = trains[0].front;
							trains[1].rear = trains[0].rear;
					fi;
					
					// we assume this from the scenario 5 - mention that it is not specified when a train looses its integrity
					trains[0].integer = false;
					trains[1].integer = false; 
					trains[1].connected = false;
					//trains[0].reportedintegrity = trains[0].reportedposition;
					trains[1].reportedintegrity = trains[0].reportedintegrity;
					trains[1].reportedposition = trains[0].rear;
					printf("Train splits\n");
			
			// losing integrity
			:: true ->
progress7:
					trains[id].integer = false;

			// re-gaining integrity
			:: true ->
progress8:
					trains[id].integer = true;

				// the train stays still
			:: else -> skip;
		

		fi
		
#endif
}

proctype reality() {

	
///////////////////////////////////////////////////////////////////////////////	
#if defined(sce)
	byte _i;

	do 
	// reality process runs just if it is scheduled
	::schedule == REALITY ->

	// check whether the simulation is over
		if
			:: st >= SIMULATIONSTEPS -> break;
			:: else -> skip;
		fi
			
		printf("Step %d of scenario %d\n", st, sce);

        if
			// spawning a new train at the beginning			
			::
			if
			   :: (alive < TRAINCOUNT) && ((scenarios[sce].step[st].train[alive] & 15) == 1) &&
				(vss[0].state == FREE) && (alive < TRAINCOUNT) ->
				spawntrain(alive);
				alive++;

				:: else -> skip;
			fi;

			
			// moving a train
			for (_i : 0 .. TRAINCOUNT - 1) {
			     if
			     	:: trains[_i].alive -> skip; move(_i);
			     	:: else -> skip;
				 fi;
			}
			

		fi;
		for (_i : 0 .. TRAINCOUNT - 1) {
			trainreport(_i); // train _i can either report or not
		}

		// at the end yield the execution to trackside
		schedule = TRACKSIDE;
	od;

///////////////////////////////////////////////////////////////////////////////	
#elif defined(dsl)
	byte _i;

	bool _allfinished = true;
	
	do 
	// reality process runs just if it is scheduled
	::schedule == REALITY ->
	
	// check whether the simulation is over
		if
			:: st >= SIMULATIONSTEPS -> schedule = TRACKSIDE; break;
			:: else -> skip;
		fi
			
		printf("Step %d of scenario\n", st);

        if
			// spawning a new train at the beginning			
			::
			if
			   :: (alive < TRAINCOUNT) && ((step[st].train[alive] & SPAWNS) == SPAWNS) &&
				(vss[0].state == FREE) && (alive < TRAINCOUNT) ->
				spawntrain(alive);
				alive++;
				:: else -> skip;
			fi;

			// moving a train
			for (_i : 0 .. TRAINCOUNT - 1) {
				if 
				 	:: trains[_i].alive -> move(_i);
				 	:: else -> skip;
				 fi
			}

		fi;
		for (_i : 0 .. TRAINCOUNT - 1) {
			trainreport(_i); // train _i can either report or not
		}

		if
			:: ((alive > 1) && _allfinished) ->
				schedule = TRACKSIDE; 
				break;
			:: else -> skip;
		fi
		
		// at the end yield the execution to trackside

		_allfinished = true;
		for (_i : 0 .. alive - 1) {
			if 
				:: trains[_i].alive -> _allfinished = false; break;
				:: else -> skip;
			fi
		}
		
		if 
			::_allfinished -> schedule = TRACKSIDE; break;
			::else -> skip;
		fi
		
		schedule = TRACKSIDE;
	od;



///////////////////////////////////////////////////////////////////////////////	
#else
	byte _i;	
	bool _allfinished;
	do 
	// reality process runs just if it is scheduled
	::schedule == REALITY ->

        if
			// spawning a new train at the beginning			
			::
				(vss[0].state == FREE) && (alive < TRAINCOUNT) ->
				spawntrain(alive);
				alive++;

			// moving a train
			:: for (_i : 0 .. TRAINCOUNT - 1) {
				if
					:: trains[_i].alive -> move(_i);	
					:: skip;
				fi;
			}

			// no more alive trains left
				
		fi;
		for (_i : 0 .. TRAINCOUNT - 1) {
			trainreport(_i); // train _i can either report or not
		}
		
		_allfinished = true;
		for (_i : 0 .. alive - 1) {
			if 
				:: trains[_i].alive -> _allfinished = false; break;
				:: else -> skip;
			fi
		}

		if
			:: ((alive > 1) && _allfinished) ->
				schedule = TRACKSIDE; 
				break;
			:: else -> skip;
		fi


		// at the end yield the execution to trackside
		schedule = TRACKSIDE;
	od;

#endif
	

}


init {
#ifndef dsl
	//At the start-up of the trackside system all VSS are in state UNKNOWN (5.1.1.4)
	vss[0].state = FREE;
	vss[0].ttd = 0; //the information about TTD is correct also in vss
	vss[1].state = FREE;
	vss[1].ttd = 0;	
	vss[2].state = FREE;
	vss[2].ttd = 1;	
	vss[3].state = FREE;
	vss[3].ttd = 1;	
	vss[4].state = FREE;
	vss[4].ttd = 1;	
	vss[5].state = FREE;
	vss[5].ttd = 2;	
	vss[6].state = FREE;
	vss[6].ttd = 2;	
	vss[7].state = FREE;
	vss[7].ttd = 2;	
	vss[8].state = FREE;
	vss[8].ttd = 3;	
	vss[9].state = FREE;
	vss[9].ttd = 3;

	real[0].state = FREE;
	real[0].ttd = 0;
	real[1].state = FREE;
	real[1].ttd = 0;
	real[2].state = FREE;
	real[2].ttd = 1;
	real[3].state = FREE;
	real[3].ttd = 1;
	real[4].state = FREE;
	real[4].ttd = 1;
	real[5].state = FREE;
	real[5].ttd = 2;
	real[6].state = FREE;
	real[6].ttd = 2;
	real[7].state = FREE;
	real[7].ttd = 2;
	real[8].state = FREE;
	real[8].ttd = 3;
	real[9].state = FREE;
	real[9].ttd = 3;
	
	ttd[0].state = TTDFREE;
	ttd[0].firstVSS = 0;
	ttd[0].ghost = false;
	ttd[1].state = TTDFREE;
	ttd[1].firstVSS = 2;
	ttd[1].ghost = false;
	ttd[2].state = TTDFREE;
	ttd[2].firstVSS = 5;
	ttd[2].ghost = false;
	ttd[3].state = TTDFREE;
	ttd[3].firstVSS = 8;
	ttd[3].ghost = false;
#endif
	
#ifdef sce
	st = 0;
	initScenarios();
#endif	

#ifdef dsl
	st = 0;
	initScenario();
#endif 
	atomic {
	run reality(); 
	run trackside();
	}
}

