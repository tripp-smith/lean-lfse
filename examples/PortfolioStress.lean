import LFSE

open LFSE

def stressScenarios : List Finance.Scenario :=
  Finance.portfolioStress

#eval stressScenarios.map (fun s => s.name)
