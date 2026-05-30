import LFSE.Test.Reference.BinomialTree

open LFSE.Test.Reference

/-!
# Basic Test for Binomial Tree Oracle (B5a support)

Exercises the oracle on one of the classic LS Table 1 cases for sanity.
-/

def main : IO Unit := do
  IO.println "Binomial Oracle Sanity (B5)"

  -- One of the published LS Table 1 cases (S=36, sigma=0.2, T=1, K=40, r=0.06)
  -- Expected around 4.478 per the spec.
  let price := binomialAmericanPut 36.0 40.0 0.06 0.2 1.0 100
  IO.println s!"  Binomial American Put (36,40,0.06,0.2,1.0,100 steps) ≈ {price}"

  let reasonable := price > 3.0 && price < 6.0
  if reasonable then
    IO.println "Binomial oracle sanity: PASS"
  else
    IO.println "Binomial oracle sanity: REVIEW (value outside loose band)"
    IO.Process.exit 1

#eval main
