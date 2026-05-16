import LFSE

open LFSE

def mcScenario : LazyScenario :=
  #scenario base => callOption("ACME", 100.0, 1.0, 0.20)

#eval forceMonteCarlo 100 42 mcScenario
