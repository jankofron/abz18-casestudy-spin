We used the following versions of the tools:  

<pre>Spin Version 6.4.8 -- 2 March 2018
cc (GCC) 7.3.1 20180130
</pre>

We have used the following arguments when compiling and running the model:  

<pre># spin -a model.pml
# cc -DBITSTATE -DPUTPID -DP_RAND -DT_RAND -DREVERSE -DT_REVERSE -O2 -DSAFETY -o pan pan.c
# ./pan -k1  -w29 -m10000 -h93 -RS2745
</pre>

The output of the verification identifies a situation when a train crashes into the one in front of it:  

<pre>
error: max search depth too small
Depth=    9999 States=    1e+06 Transitions= 1.21e+06 Memory=    65.566	t=     1.59 R=   6e+05
pan:1: assertion violated (real[(trains[i].front+1)].state==6) (at depth 9990)
pan: wrote model.pml_pan1_16408.trail

(Spin Version 6.4.8 -- 2 March 2018)
Warning: Search not completed
	+ Partial Order Reduction
	+ Reverse Depth-First Search Order
	+ Reverse Transition Ordering
	+ Randomized Transition Ordering
	+ Randomized Process Ordering

Bit statespace search for:
	never claim         	- (none specified)
	assertion violations	+
	cycle checks       	- (disabled by -DSAFETY)
	invalid end states	+

State-vector 196 byte, depth reached 9999, errors: 1
  1202159 states, stored
   250984 states, matched
  1453143 transitions (= stored+matched)
  8221247 atomic steps

hash factor: 446.589 (best if > 100.)

bits set per state: 1 (-k1)
random seed used: 2744

Stats on memory usage (in Megabytes):
  247.637	equivalent memory usage for states (stored*(State-vector + overhead))
   64.000	memory used for hash array (-w29)
    0.076	memory used for bit stack
    0.687	memory used for DFS stack (-m10000)
   65.566	total actual memory usage

pan: elapsed time 1.97 seconds
pan: rate 610232.99 states/second
</pre>

This corresponds to the following scenario:  

<pre>Train A spawned
Train A reported with integrity
Timer mutetimer for train 0 running
Timer mutetimer for train 1 running
VSS0: transition #2A taken
Train A - eoma: 9

A
O	F	F	F	F	F	F	F	F	F	
O	O	F	F	F	F	F	F	F	F	
0	0	1	1	1	2	2	2	3	3	
____________________________________________________________________________

Moving front of train A forward
Train A reported with integrity
Timer mutetimer for train 0 running
Timer mutetimer for train 1 running
VSS1: transition #2A taken
Train A - eoma: 9

A	A
O	O	F	F	F	F	F	F	F	F	
O	O	F	F	F	F	F	F	F	F	
0	0	1	1	1	2	2	2	3	3	
____________________________________________________________________________

Moving rear of train A forward
Train A reported having left VSS0
Train A reported with integrity
Timer mutetimer for train 0 running
Timer mutetimer for train 1 running
integritylosspropagationtimer for VSS1 expired
VSS0: transition #6B taken
Train A - eoma: 9

	A
F	O	F	F	F	F	F	F	F	F	
O	O	F	F	F	F	F	F	F	F	
0	0	1	1	1	2	2	2	3	3	
____________________________________________________________________________

Moving front of train A forward
Train A NOT reported
Timer mutetimer for train 0 running
Timer mutetimer for train 1 running
integritylosspropagationtimer for VSS1 expired
VSS0: transition #1E taken
VSS1: transition #8B taken
Train A - eoma: 9

	A	A
U	A	F	F	F	F	F	F	F	F	
O	O	O	O	O	F	F	F	F	F	
0	0	1	1	1	2	2	2	3	3	
____________________________________________________________________________

Moving rear of train A forward
Train A reported having left VSS1
Train A reported with integrity
Timer mutetimer for train 0 running
Timer mutetimer for train 1 running
shadowtimerA for TTD0 expired
VSS0: transition #4A taken
NON-DETERMINISM: 192
VSS1: transition #9A taken
VSS2: transition #2A taken
Train A - eoma: 9

		A
F	F	O	F	F	F	F	F	F	F	
F	F	O	O	O	F	F	F	F	F	
0	0	1	1	1	2	2	2	3	3	
____________________________________________________________________________

Moving front of train A forward
Train A NOT reported
Timer mutetimer for train 0 running
Timer mutetimer for train 1 running
shadowtimerA for TTD0 expired
Timer integritylosspropagationtimer for VSS2 running
Train A - eoma: 9

		A	A
F	F	O	F	F	F	F	F	F	F	
F	F	O	O	O	F	F	F	F	F	
0	0	1	1	1	2	2	2	3	3	
____________________________________________________________________________

Train B spawned
Train splits
Train B reconnects
Train A NOT reported
Train B reported with NO integrity
Timer mutetimer for train 0 running
Timer mutetimer for train 1 running
shadowtimerA for TTD0 expired
Timer integritylosspropagationtimer for VSS2 running
VSS0: transition #1A taken
VSS1: transition #1A taken
VSS2: transition #8B taken
Train A - eoma: 9
Train B - eoma: 9

		BA	A
U	U	A	F	F	F	F	F	F	F	
O	O	O	O	O	F	F	F	F	F	
0	0	1	1	1	2	2	2	3	3	
____________________________________________________________________________

Moving both front and rear of train A forward
Train B disconnects
Train A reported having left VSS2
Train A reported with NO integrity
Train B NOT reported
Timer mutetimer for train 0 running
Timer mutetimer for train 1 expired
shadowtimerA for TTD0 expired
Timer integritylosspropagationtimer for VSS2 running
Timer disconnectpropagationtimer for VSS2 running
VSS2: transition #10A taken
VSS4: transition #2A taken
Train A - eoma: 9
Train B - eoma: 9

		b	A	A
U	U	U	F	O	F	F	F	F	F	
O	O	O	O	O	F	F	F	F	F	
0	0	1	1	1	2	2	2	3	3	
____________________________________________________________________________

Train A disconnects
spin: model.pml:1178, Error: assertion violated
spin: text of failed assertion: assert((real[(trains[i].front+1)].state==FREE))
Exit-Status 0

</pre>
