import LFSE.Finance.Scenario

namespace LFSE

syntax "#scenario " ident " => " term : term
syntax "obsSpot(" str ")" : term
syntax "obsRate(" str ")" : term
syntax "callOption(" str ", " term ", " term ", " term ")" : term
syntax "putOption(" str ", " term ", " term ", " term ")" : term
syntax "forward(" str ", " term ", " term ")" : term
syntax "swap(" term ", " term ", " term ", " term ")" : term

-- Phase A: Early-exercise instruments (LSMC-powered Bermudan / American)
syntax "bermudanCall(" str ", " term ", " term ", " term ", " "[" term,* "]" ")" : term
syntax "bermudanPut(" str ", " term ", " term ", " term ", " "[" term,* "]" ")" : term
syntax "americanCall(" str ", " term ", " term ", " term ", " term ")" : term
syntax "americanPut(" str ", " term ", " term ", " term ", " term ")" : term

def scenarioOf (name : String) (instrument : Finance.Instrument) : Finance.Scenario :=
  { name := name, ctx := Finance.baseContext, instrument := instrument }

end LFSE
