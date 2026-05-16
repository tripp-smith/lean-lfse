import LFSE

open LFSE

def waterfallScenario : Finance.Scenario :=
  { name := "waterfall", ctx := Finance.baseContext, instrument := .swap 1000000.0 0.04 0.052 5.0 }

#eval forceNPV waterfallScenario
