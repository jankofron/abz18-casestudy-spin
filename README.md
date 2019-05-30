# ERTMS/ETCS Case study in Spin — supplementary material of:
## [Paolo Arcaini](http://group-mmm.org/~arcaini/) and [Jan Kofroň](https://d3s.mff.cuni.cz/~kofron): Validation of the Hybrid ERTMS/ETCS Level 3 using Spin

This page contains the material to our case study of the [ERTMS/ETCS Level 3 specification in Promela](http://www.ertms.be/sites/default/files/2018-03/16E0421A_HL3.pdf) in Promela. We refer to version 1A dated 14/07/2017. We aimed at modelling and verification of the scenarios contained in the specification as well as at the general verification of safety properties of the system. The following files contain the model of the system:


 * The main model file: [model.pml](model.pml)
 * Scenarios: [scenarios.pml](scenarios.pml)
 * Implementation of DSL language: [dsl.pml](dsl.pml)
 * A DSL example use case: [usecase.pml](usecase.pml)
 * Assertions to check ambiguity of VSS state transitions: [asserts.pml](asserts.pml)
 * Output of simulation of the specification scenarios: [scenarios_output.zip](scenarios_output.zip)

To run a DSL use case, the spin command line has to define the "dsl" symbol. We advise to use the "-X -B" argument as well:

``spin -X -B -Ddsl model.pml``

To run a particular scenario from the requirement specification document, the "sce" symbol has to be defined, e.g. for scenario 1:

``spin -X -B -Dsce=1 model.pml``

To run a random simulation, define neither "dsl" nor "sce":

``spin -X -B model.pml``

We have discovered a potential assertion violation corresponding to a situation when a train crashes into another one due to disconnection and a too-long mute timer time-out. The details can be found [here](violation.md).
The list of requirements covered by the VSS state machine can be found [here](reqs.md). 
