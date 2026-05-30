import LFSE.Finance.LSMC.Algorithm
import LFSE.Finance.LSMC.Config
import LFSE.Test.Reference.BinomialTree

open LFSE.Finance.LSMC
open LFSE.Test.Reference

/-!
# Direct Comparison Test: LSMC (B3) vs Binomial Oracle (B5)

Runs the current B3 implementation against the binomial oracle on one of the
LS Table 1 cases for verification progress.

This is part of the infrastructure for the final Phase B verification package.
-/

def main : IO Unit := do
  IO.println "LSMC (B3) vs Binomial (B5) Comparison"

  -- One of the published cases: S=36, K=40, r=0.06, sigma=0.2, T=1
  -- Published value ~4.478
  let spot := 36.0
  let strike := 40.0
  let rate := 0.06
  let vol := 0.2
  let maturity := 1.0

  let cfg : Config := {
    paths := 50000
    seed := 123456
    style := .american 100   -- 100 steps discretization for American
    basis := .monomial 3
    antithetic := true
    ridge := 1e-8
  }

  let lsmcNPV := lsmcPrice cfg (fun S => max 0.0 (strike - S)) spot rate vol maturity
  let binomNPV := binomialAmericanPutAccurate spot strike rate vol maturity

  IO.println s!"  LSMC (B3, 50k paths, monomial3): {lsmcNPV}"
  IO.println s!"  Binomial (500 steps):            {binomNPV}"
  IO.println s!"  Difference: { (lsmcNPV - binomNPV).abs }"

  -- For Phase B, we accept larger tolerance during development
  let reasonable := (lsmcNPV - binomNPV).abs < 2.0   -- loose during active development
  if reasonable then
    IO.println "Comparison: Within loose development tolerance (continuing work on accuracy)"
  else
    IO.println "Comparison: Large difference - needs algorithm improvement"

#eval main
