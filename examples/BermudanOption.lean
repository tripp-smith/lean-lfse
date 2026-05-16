import LFSE

open LFSE

def bermudanScenario : LazyScenario :=
  #scenario base => callOption("ACME", 100.0, 1.0, 0.20)

#eval forceNPV bermudanScenario
