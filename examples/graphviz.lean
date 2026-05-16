import LFSE

open LFSE

def graphScenario : LazyScenario :=
  #scenario base => forward("ACME", 95.0, 1.0)

#eval IO.println (exportDot graphScenario)
