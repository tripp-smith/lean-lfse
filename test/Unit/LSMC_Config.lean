import LFSE.Finance.LSMC.Config

open LFSE.Finance.LSMC

/-!
# Unit Tests for LSMC Config (B2)
-/

def main : IO Unit := do
  IO.println "LSMC Config Validation Tests (B2)"

  -- Valid bermudan
  let validBermudan : Config := { style := .bermudan #[0.25, 0.5, 1.0] }
  let res1 := Config.validate validBermudan
  let test1 := res1.isOk
  IO.println s!"  Valid bermudan config: {test1}"

  -- Invalid: non-increasing dates
  let badDates : Config := { style := .bermudan #[1.0, 0.5] }
  let res2 := Config.validate badDates
  let test2 := res2.isError
  IO.println s!"  Rejects non-increasing bermudan dates: {test2}"

  -- Invalid: american with 1 step
  let badAmerican : Config := { style := .american 1 }
  let res3 := Config.validate badAmerican
  let test3 := res3.isError
  IO.println s!"  Rejects american with < 2 steps: {test3}"

  -- Invalid: negative ridge
  let badRidge : Config := { ridge := -0.1 }
  let res4 := Config.validate badRidge
  let test4 := res4.isError
  IO.println s!"  Rejects negative ridge: {test4}"

  if test1 && test2 && test3 && test4 then
    IO.println "B2 Config Tests: OK"
  else
    IO.println "B2 Config Tests: FAIL"
    IO.Process.exit 1

#eval main
