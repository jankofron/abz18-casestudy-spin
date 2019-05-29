# Validation of the Hybrid ERTMS/ETCS Level 3 using Spin
## Supplementary material 


### ABZ'18 ERTMS/ETCS Case study in Promela
### Authors: Paolo Arcaini and Jan Kofron
This page contains the material to our case study of the [ERTMS/ETCS Level 3 specification in Promela](http://www.ertms.be/sites/default/files/2018-03/16E0421A_HL3.pdf). We aimed at modelling and verification of the scenarios contained in the specification as well as at the general verification of safety properties of the system. The following files contain the model of the system:

 * The main model file: model.pml
 * Scenarios: [scenarios.pml](scenarios.pml)
 * Assertions to check ambiguity of VSS state transitions: asserts.pml
 * Output of simulation of the specification scenarios: scenarios_output.zip
 * Error trail of the assetion violation – trains crash: assertion_violation.txt
