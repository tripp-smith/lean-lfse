import LFSE

open LFSE

def showReport (r : Finance.Synthetic.ScenarioReport) : String :=
  s!"{r.name}: npv={r.npv}, traceNodes={r.traceNodes}"

#eval do
  match ← Finance.Synthetic.runStressGrid with
  | .error err => IO.println s!"stress grid failed: {err}"
  | .ok reports =>
      IO.println "Multi-asset portfolio macro stress grid"
      reports.forM fun report => IO.println (showReport report)

#eval do
  match ← Finance.Synthetic.mcRiskReport 1000 20260516 with
  | .ok (base, recession) =>
      IO.println s!"ACME call MC base={base}, recession={recession}"
  | .error err =>
      IO.println s!"ACME call MC failed: {err}"

#eval do
  IO.println "ABS base waterfall"
  Finance.Synthetic.absBasePayments.forM fun p =>
    IO.println s!"{p.tranche}: {p.amount}"
  IO.println "ABS stressed waterfall"
  Finance.Synthetic.absStressPayments.forM fun p =>
    IO.println s!"{p.tranche}: {p.amount}"
