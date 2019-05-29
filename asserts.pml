inline checkUnique(i) {
	int count = 0;
	
	count = count + (i & 1);
	count = count + ((i & 2) >> 1);
	count = count + ((i & 4) >> 2);
	count = count + ((i & 8) >> 3);
	count = count + ((i & 16) >> 4);
	count = count + ((i & 32) >> 5);
	count = count + ((i & 64) >> 6);
	count = count + ((i & 128) >> 7);
	count = count + ((i & 256) >> 8);
	count = count + ((i & 512) >> 9);
	count = count + ((i & 1024) >> 10);
	count = count + ((i & 2048) >> 11);
	
	if
		:: count > 1 -> printf("NON-DETERMINISM: %d\n", i); //assert(false);
		:: else -> skip; 
	fi
	
}

inline assertFREE(i) {
	int nondet = 0;
			if
				// #1A
				:: ((ttdstate == TTDOCCUPIED) &&
					//(no FS MA is issued or no train is located on this TTD)
					((trains[0].alive && trains[0].eoma < 10 && vss[trains[0].eoma].ttd < vss[i].ttd && trains[1].eoma < 10 && vss[trains[1].eoma].ttd < vss[i].ttd)
					||
					!trainpresentonttd)) ->
						nondet = nondet | 1;
				:: else -> skip;
			fi
			if
				// #1B
				:: ((ttdstate == TTDOCCUPIED) &&
					//TODO: probably "trains[0].reportedposition <= i" not needed as implied by eoma
					((trains[0].alive && !trains[0].hasreported && trains[0].reportedposition <= i && trains[0].eoma >= i && mutetimer[0] == 2) || 
					 (trains[1].alive && !trains[1].hasreported && trains[1].reportedposition <= i && trains[1].eoma >= i && mutetimer[1] == 2)) &&
					//VSS is located in advance of the VSS where the train was last reported - have to check both trains
					(((trains[0].alive && trains[0].reportedposition < i) && (trains[0].eoma >= i) && (!trains[0].hasreported)) || ((trains[1].alive && trains[1].reportedposition < i) && (trains[1].eoma >= i) && !trains[1].hasreported))
					) 
					-> 
						nondet = nondet | 1;
				:: else -> skip;
				fi
				
				if
				// #1C
				:: ((ttdstate == TTDOCCUPIED) &&			
					((!trains[0].connected && disconnecttimer[i] == 2 &&
					//VSS is located on the same TTD as the VSS for which the timer is expired
					(trains[0].alive && trains[0].reportedposition != 255 ) &&
					(vss[i].ttd == vss[trains[0].reportedposition].ttd || (trains[0].reportedlength != 255 && vss[i].ttd == vss[trains[0].reportedposition - trains[0].reportedlength].ttd)) &&
					freeorunknown0) ||  
					(trains[1].alive && !trains[1].connected && disconnecttimer[i] == 4 &&
					(trains[1].reportedposition != 255) &&
					(vss[i].ttd == vss[trains[1].reportedposition].ttd || (trains[1].reportedlength != 255 && vss[i].ttd == vss[trains[1].reportedposition - trains[1].reportedlength].ttd)) &&
					freeorunknown1)))  ->	
						nondet = nondet | 1;
				:: else -> skip;
				fi
				
				if
				// #1D
				:: ((ttdstate == TTDOCCUPIED) &&
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
					(trains[0].eoma < i || (trains[0].reportedposition - trains[0].reportedlength) > i) && (trains[1].eoma < i || (trains[1].reportedposition - trains[1].reportedlength) > i)
					) 
					->	
						nondet = nondet | 1;
				:: else -> skip;
				fi
				
				if
				// #1E
				:: ((ttdstate == TTDOCCUPIED) &&
					//"reportedintegrity == 255" for modeling integrity loss
					((trains[0].alive && !trains[0].reportedinteger && 
					//VSS is located on the same TTD as the VSS for which the "integrity loss propagation timer" is expired
					(vss[trains[0].reportedintegrity].ttd == vss[i].ttd) &&
					freeorunknownint0) ||
					(trains[1].alive && !trains[1].reportedinteger &&					
					//VSS is located on the same TTD as the VSS for which the "integrity loss propagation timer" is expired
					(vss[trains[1].reportedintegrity].ttd == vss[i].ttd) &&
					freeorunknownint1))) ->
						nondet = nondet | 1;
				:: else -> skip;
				fi

				if
				// #1F
				:: ((ttdstate == TTDOCCUPIED) &&
					ghosttimer == 2 &&
					freeorunknownghost1 && trains[1].alive // &&
					// trains[1].reportedposition < VSSCOUNT // && //TODO: this is not correct, we should remember the timer VSS as well
					//VSS is not located on the TTD for which the timer is expired
					//(vss[i].ttd != vss[trains[1].reportedposition].ttd && vss[i].ttd != vss[trains[1].reportedposition - trains[1].reportedlength].ttd)
					)
						->
						nondet = nondet | 1;
				:: else -> skip;
				fi
				
				if
				// #2A
				:: rule2A ->
						nondet = nondet | 2;
				:: else -> skip;
				fi

				if
				// #2B
				:: rule2B ->
						nondet = nondet | 2;
				:: else -> skip;
				fi

				if
				// #3A
				:: ((ttdstate == TTDOCCUPIED) &&
					//train is located on the VSS
					trainidonvss != 255 &&
					//lower priority than #2: !(#2A || #2B)
					!(rule2A || rule2B)) ->
						nondet = nondet | 4;
				:: else -> skip;
				fi

				if
				// #3B
				:: ((ttdstate == TTDOCCUPIED) &&
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
					!(rule2A || rule2B))  ->
						nondet = nondet | 4;
				:: else -> skip;
				fi

		checkUnique(nondet);				

}


inline assertOCCUPIED(i) {
	int nondet = 0;

			if
				// #6A
				:: (ttdstate == TTDFREE) ->
					nondet = nondet | 8;
				:: else -> skip;
			fi
			
			if
				// #6B
					//integer train has reported to have left the VSS
				:: trains[0].hasreported && trains[0].reportedinteger && trains[0].reportedleftvss >= i && trains[0].reportedleftvss != 255 &&
				   (!trains[1].alive || (real[trains[1].front].ttd < real[i].ttd))
						-> 					nondet = nondet | 8;
				:: else -> skip;
			fi
			
			if
				:: trains[1].hasreported && trains[1].reportedinteger && trains[1].reportedleftvss >= i && trains[1].reportedleftvss != 255 ->
					nondet = nondet | 8;
				:: else -> skip;
			fi
			
			if
				// #7A
				::	rule7A ->
					nondet = nondet | 16;
				:: else -> skip;
			fi
			
			if

				// #7B
				:: rule7B ->
					nondet = nondet | 16;
				:: else -> skip;
			fi
			
			if


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
					nondet = nondet | 32;
				:: else -> skip;
			fi
			
			if

				// #8B
					//train is located on the VSS
				::	trainidonvss != 255 &&
					//VSS in rear is UNKNOWN
					i > 0 && vss[i-1].state == UNKNOWN &&
					//lower priority than #7: !(#7A || #7B)
					!(rule7A || rule7B) ->
					nondet = nondet | 32;
				:: else -> skip;
			fi
			
			if

				// #8C
					//another train is located on the VSS
				::	trainidonvss != 255 &&
					(trains[1-trainidonvss].alive && ((trains[1-trainidonvss].reportedposition == i) || (trains[1-trainidonvss].reportedposition - trains[1-trainidonvss].reportedlength == i))) &&
					//lower priority than #7: !(#7A || #7B)
					!(rule7A || rule7B) ->
					nondet = nondet | 32;
				:: else -> skip;
			fi
			
		checkUnique(nondet);			
}

inline assertAMBIGUOUS(i) {
	int nondet = 0;
			if
				// #9A
				:: ttd[vss[i].ttd].state == TTDFREE ->
					nondet = nondet | 64;
				:: else -> skip;
			fi
			
			if

					::	//integer train has reported to have left the VSS
						//TODO: or "trains[0].reportedleftvss == i"?
						(trains[0].hasreported &&
						trains[0].reportedinteger && trains[0].reportedlength != 255 &&
						trains[0].reportedleftvss != 255 && trains[0].reportedleftvss >= i &&
						shadowtimerA[vss[i].ttd] == 1 &&
						trains[1].alive && trains[1].reportedposition < i) ||
						(trains[1].alive && trains[1].hasreported &&
						trains[1].reportedinteger && trains[1].reportedlength != 255 &&
						trains[1].reportedleftvss != 255 && trains[1].reportedleftvss >= i &&
						shadowtimerA[vss[i].ttd] == 1)
						 -> nondet = nondet | 64;
				:: else -> skip;
			fi
			
			if
					// #10A
					::	//VSS is left by all reporting trains //TODO: is it correct? - hopefuly - the train either has not reported or has left the vss
						//(!trains[0].connected || vss[trains[0].reportedposition].ttd < vss[i].ttd || (trains[0].hasreported && trains[0].reportedleftvss >= i && trains[0].reportedleftvss != 255)) &&
						//(!trains[1].connected || vss[trains[1].reportedposition].ttd < vss[i].ttd || (trains[1].hasreported && trains[1].reportedleftvss >= i && trains[1].reportedleftvss != 255)) 
						(!trains[0].connected || trains[0].reportedposition < i || (trains[0].hasreported && trains[0].reportedleftvss >= i && trains[0].reportedleftvss != 255)) &&
						(!trains[1].connected || trains[1].reportedposition < i || (trains[1].hasreported && trains[1].reportedleftvss >= i && trains[1].reportedleftvss != 255)) 
						//trainidonvss == 255
												
						 -> nondet = nondet | 128;
				:: else -> skip;
			fi
						 
			if
					// #10B
					:: trainidonvss != 255 &&
						// mute timer expired or end of mission reached //TODO: to check
						((trainidonvss == 0 && mutetimer[0] == 2) || (trainidonvss == 1 && mutetimer[1] == 2) || (trains[trainidonvss].eom == i && trains[trainidonvss].reportedlength == 0))
						 -> nondet = nondet | 128;
				:: else -> skip;
			fi

				if
				// #11A
				::	//(integer train located on the VSS reported to have left the TTD in rear)
					trainidonvss != 255 &&
					trains[trainidonvss].hasreported &&
					trains[trainidonvss].reportedleftvss == ttd[vss[i].ttd].firstVSS - 1 &&
					//(trains[trainidonvss].reportedlength == 0 || ttd[vss[i].ttd].firstVSS != i) &&
				  // vss[trains[trainidonvss].reportedleftvss].ttd < vss[i].ttd &&
					 // the shadow train timer expiration if the TTD in rear was not expired at the moment of the position report  
					 // && the reported min-safe-rear-end of this train is within the distance.....
					 (vss[i].ttd > 0) &&
					 shadowtimerA[vss[i].ttd - 1] == 1
						-> nondet = nondet | 256;
				:: else -> skip;
			fi

			if
				// #11B
				:: ((vss[i].ttd > 0 && ttd[vss[i].ttd-1].state == TTDFREE) || (vss[i].ttd == 0)) &&
					trainidonvss != 255 &&
				   (vss[i].ttd > 0) && (trains[trainidonvss].reportedleftvss >= ttd[vss[i].ttd].firstVSS - 1) && trains[trainidonvss].hasreported &&
				   (vss[i].ttd > 0) &&
					 (shadowtimerB[vss[i].ttd - 1] == 1)  
						-> nondet = nondet | 256;
				:: else -> skip;
			fi

		checkUnique(nondet);			
	
}

inline assertUNKNOWN(i) {
	int nondet = 0;
			if 
			// #4A
			:: ttdstate == TTDFREE ->
					nondet = nondet | 2048;
					:: else -> skip;
			fi
			
			if 
			// #4B train 0
			::	rule4B(0) ->
					nondet = nondet | 2048;
					:: else -> skip;
			fi
			
			if 

			// #4B train 1
			:: 	rule4B(1) ->
					nondet = nondet | 2048;
					:: else -> skip;
			fi
			
			if 

			// #4C train 0
			:: rule4C(0) ->
					nondet = nondet | 2048;
					:: else -> skip;
			fi
			
			if 
			// #4C train 1
			:: rule4C(1) ->
					nondet = nondet | 2048;
					:: else -> skip;
			fi

			if 
				// #12A
				:: rule12A &&
					//lower priority than #4: !(#4B || #4C)
					!(rule4B(0) || rule4B(1) || rule4C(0) || rule4C(1)) ->
						nondet = nondet | 512;
				:: else -> skip;
			fi

			if
				// #12B
				:: rule12B &&
					//lower priority than #4: !(#4B || #4C)
					!(rule4B(0) || rule4B(1) || rule4C(0) || rule4C(1)) ->
						nondet = nondet | 512;
				:: else -> skip;
			fi

			if
				// #5A
				 ::	trainidonvss != 255 && //NEW to model "train is located on the VSS": is it correct?
					(trains[trainidonvss].hasreported)  && //NEW 11/01/2018
					//lower priority than #12
					(!(rule12A || rule12B)) &&
					// not #4A - ASSUMPTION - this is not in the spec. table
					ttdstate != TTDFREE &&
					//lower priority than #4: !(#4B || #4C)
					!(rule4B(0) || rule4B(1) || rule4C(0) || rule4C(1)) ->
						nondet = nondet | 1024;
				:: else -> skip;
			fi
		checkUnique(nondet);
}
