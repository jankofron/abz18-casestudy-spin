// Codes reflect the following actions:
// 0 - no action for the train
// 1 - spawn the train
// 2 - move the front end
// 3 - move the rear end
// 4 - train disappears
// 64- train disconnects
//128- train reconnects
// 7 - train splits
// 8 - move both front and rear ends of the train
// 9 - train loses integrity
// 10 - train gets integrity
// 16 + code above - train reports
// 32 + code above - train reports integrity

#define NOOP 		0
#define DISAPPEARS	1
#define DISCONNECTS	2
#define RECONNECTS	3
#define SPLITS		4
#define LOOSESINT	5
#define GAINSINT	6
#define REPORTS		8
#define REPORTSINT	16
#define MOVESREAR	32
#define MOVESFRONT 	64
#define MOVES		MOVESREAR | MOVESFRONT
#define SPAWNS 		128

byte ___it;



	
#define CREATEINFRASTRUCTURE(_TTDCOUNT, _VSSCOUNT, _STEPS) \
	typedef Step {	\
		byte train[2]; \
		byte mutetimer[2]; \
		byte disconnecttimer[_VSSCOUNT]; \
		byte integritylosstimer[_VSSCOUNT]; \
		byte shadowtimerA[_TTDCOUNT]; \
		byte shadowtimerB[_TTDCOUNT]; \
		byte ghosttimer; \
		byte eoma[2]; \
		byte eom[2]; \
	} \
	\
	TTDSection ttd[_TTDCOUNT]; \
	byte __vsscounter = 0; \
	byte __ttdcounter = 0; \
	\
	VSS vss[_VSSCOUNT]; \
	VSS real[_VSSCOUNT]; \
	byte TTDCOUNT = _TTDCOUNT; \
	byte VSSCOUNT = _VSSCOUNT; \
	\
	Step step[_STEPS]; \
	byte SIMULATIONSTEPS = _STEPS; \
	byte shadowtimerA[_TTDCOUNT]; \
	byte shadowtimerB[_TTDCOUNT]
	
	
#define BEGINUSECASE inline initScenario() { \

#define ENDUSECASE \
for (___it : 0 .. VSSCOUNT - 1) {\
	printf("%d, %d\n", step[___it].train[0], step[___it].train[1]);\
	}\
} \


	
inline SETTTDLEN(_VSS, _LEN) {
	// initialize ttd, vss, real, as in model.pml
	if 
		::_VSS == 0 -> 
			for ( ___it : 0 .. _LEN - 1 ) { 
				vss[___it].state = FREE; 
				vss[___it].ttd = 0; 
				real[___it].state = FREE; 
				real[___it].ttd = 0; 
			} \
			ttd[0].state = TTDFREE; 
			ttd[0].firstVSS = 0; 
			ttd[0].ghost = false;
			ttd[0]._lastVSS = _LEN - 1;
		
		
		::else -> 
			for ( ___it : ttd[_VSS-1]._lastVSS + 1 .. ttd[_VSS-1]._lastVSS + _LEN ) { 
				vss[___it].state = FREE; 
				vss[___it].ttd = _VSS; 
				real[___it].state = FREE; 
				real[___it].ttd = _VSS; 
			} \
			ttd[_VSS].state = TTDFREE; 
			ttd[_VSS].firstVSS = ttd[_VSS-1]._lastVSS + 1; 
			ttd[_VSS].ghost = false;
			ttd[_VSS]._lastVSS = ttd[_VSS-1]._lastVSS + _LEN;
	fi
}



inline FASTTRAIN(_ID, _START) {
	if
		::_START > 0 ->
			for (___it : 0 .. _START - 1) { 
				step[___it].train[_ID] = NOOP; 
		} 
		:: else -> skip;
	fi
	
	step[_START].train[_ID] = SPAWNS | REPORTS | REPORTSINT; 
	
	for (___it : _START + 1 .. VSSCOUNT - 1) { 
		step[___it].train[_ID] = (MOVES | REPORTS | REPORTSINT);
	} 
	step[VSSCOUNT].train[_ID] = DISAPPEARS;
	
	step[0].eom[_ID] = VSSCOUNT;
	step[0].eoma[_ID] = VSSCOUNT;
}


inline rolldice() {
	if
		:: dice = 0;
		//:: dice = 1;
		//:: dice = 2;
		:: dice = 3;
	fi
}

inline SLOWTRAIN(_ID, _START) {
	byte dice;
	bool twovss = false;
	byte pos = 0;

	if
		::_START > 0 ->
			for (___it : 0 .. _START - 1) { 
				step[___it].train[_ID] = NOOP; 
			} 
		:: else -> skip;
	fi
	
	step[_START].train[_ID] = SPAWNS | REPORTS | REPORTSINT; 
	
	___it = _START + 1;
	
	do 
		::rolldice();
		if
			//:: (dice == 1) && (!twovss) -> step[___it].train[_ID] = (MOVESFRONT | REPORTS | REPORTSINT); twovss = true; pos = pos + 1;
			//:: (dice == 2) && (twovss) -> step[___it].train[_ID] = (MOVESREAR | REPORTS | REPORTSINT); twovss = false;
			:: dice == 3 -> step[___it].train[_ID] = (MOVES | REPORTS | REPORTSINT); pos = pos + 1;
			:: else -> step[___it].train[_ID] = REPORTS | REPORTSINT;
		fi
		
		___it = ___it + 1;
		
		if
			:: (pos == VSSCOUNT - 1) || (___it == SIMULATIONSTEPS - 1) -> break;
			:: else -> skip;
		fi
		
		
	od

	step[___it].train[_ID] = DISAPPEARS;
	
	step[0].eom[_ID] = VSSCOUNT;
	step[0].eoma[_ID] = VSSCOUNT;
}
	

	
	

inline CONNECT(ID, STEP) {
	step[STEP].train[ID] = step[STEP].train[ID] | RECONNECTS; 
	for (___it : STEP + 1 .. SIMULATIONSTEPS - 1) { 
		step[___it].train[ID] = (step[___it].train[ID] | REPORTSINT | REPORTS); 
	} 
}
	
inline DISCONNECT(ID, STEP) {
	step[STEP].train[ID] = step[STEP].train[ID] | DISCONNECTS; 
	for (___it : STEP + 1 .. SIMULATIONSTEPS - 1) { 
		step[___it].train[ID] = (step[___it].train[ID] ^ (REPORTSINT | REPORTS)); 
	} 
}

inline LOOSEINTEGRITY(ID, STEP) {
	step[STEP].train[ID] = step[STEP].train[ID] | LOOSESINT; 
	for (___it : STEP + 1 .. SIMULATIONSTEPS - 1) { 
		step[___it].train[ID] = (step[___it].train[ID] ^ (REPORTSINT)); 
	} 
}

inline GAININTEGRITY(ID, STEP) {
	step[STEP].train[ID] = step[STEP].train[ID] | GAINSINT; 
	for (___it : STEP + 1 .. SIMULATIONSTEPS - 1) { 
		step[___it].train[ID] = (step[___it].train[ID] | REPORTSINT); 
	} 
}



