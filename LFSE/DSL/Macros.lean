import LFSE.DSL.Syntax

namespace LFSE

macro_rules
  | `(obsSpot($name:str)) => `(LFSE.Finance.Observable.spot $name)
  | `(obsRate($name:str)) => `(LFSE.Finance.Observable.rate $name)
  | `(callOption($u:str, $k:term, $t:term, $v:term)) =>
      `(LFSE.Finance.Instrument.option LFSE.Finance.OptionKind.call $u $k $t $v)
  | `(putOption($u:str, $k:term, $t:term, $v:term)) =>
      `(LFSE.Finance.Instrument.option LFSE.Finance.OptionKind.put $u $k $t $v)
  | `(forward($u:str, $k:term, $t:term)) =>
      `(LFSE.Finance.Instrument.forward $u $k $t)
  | `(swap($n:term, $fixed:term, $float:term, $t:term)) =>
      `(LFSE.Finance.Instrument.swap $n $fixed $float $t)
  -- Phase A early-exercise (use the convenience constructors in Scenario)
  | `(bermudanCall($u:str, $k:term, $t:term, $v:term, [ $dates:term,* ])) =>
      `(LFSE.Finance.Scenario.bermudanCall $u $k $t $v #[$dates,*])
  | `(bermudanPut($u:str, $k:term, $t:term, $v:term, [ $dates:term,* ])) =>
      `(LFSE.Finance.Scenario.bermudanPut $u $k $t $v #[$dates,*])
  | `(americanCall($u:str, $k:term, $t:term, $v:term, $steps:term)) =>
      `(LFSE.Finance.Scenario.americanCall $u $k $t $v $steps)
  | `(americanPut($u:str, $k:term, $t:term, $v:term, $steps:term)) =>
      `(LFSE.Finance.Scenario.americanPut $u $k $t $v $steps)
  | `(#scenario $name:ident => $body:term) =>
      `(LFSE.scenarioOf $(Lean.quote (toString name.getId.eraseMacroScopes)) $body)

end LFSE
