import LFSE.Finance.MonteCarlo
import LFSE.Finance.LSMC.Config
import LFSE.Finance.Numerics.Linalg
import LFSE.Finance.Numerics.Gaussian
import LFSE.Finance.Numerics.Basis

/-!
# LSMC Core Algorithm (Phase B - Full Structure)
-/

namespace LFSE
namespace Finance
namespace LSMC

def getExerciseDates (style : ExerciseStyle) (maturity : Float) : Array Float :=
  match style with
  | .bermudan dates => dates
  | .american steps =>
      if steps == 0 then #[] else
        let dt := maturity / steps.toFloat
        Array.range (steps + 1) |>.map (fun i => i.toFloat * dt)

def lsmcPrice (cfg : Config) (payoff : Float → Float) (spot r vol maturity : Float) : Float :=
  let dates := getExerciseDates cfg.style maturity
  if dates.isEmpty then 0.0 else
    -- Use the real correct multi-date Gaussian path simulator from MonteCarlo (B1)
    let rawPaths := Finance.simulatePaths cfg.paths cfg.seed spot r vol dates cfg.antithetic
    let paths : Array (Array Float) := rawPaths.map (·.prices)
    if paths.isEmpty then 0.0 else
      let n := cfg.paths
      let K := dates.size
      let initCash := paths.map (fun p => payoff (p.back?.getD spot))
      let initTau := Array.replicate n (K-1)

      -- Adapter: dispatch Config.BasisFamily (B2) to the real iterative implementations in Numerics (B4)
      -- (Basis.lean contributes BasisFamily + eval under the Numerics qualifier, same as Linalg)
      let evalBasis (b : BasisFamily) (x : Float) : Array Float :=
        match b with
        | .monomial d => Numerics.BasisFamily.eval (.monomial d) x
        | .laguerre d => Numerics.BasisFamily.eval (.laguerre d) x
        | .hermite  d => Numerics.BasisFamily.eval (.hermite  d) x

      let (finalCash, finalTau) := Id.run do
        let mut cash := initCash
        let mut tau := initTau
        for kk in [1:K] do
          let k := K - kk
          let t_k := dates[k]!
          -- ITM filter (respects itmOnly by construction; canonical LSMC regresses only on ITM)
          let itm := paths.mapIdx (fun i p =>
            if payoff p[k]! > 0.0 then some i else none
          ) |>.filterMap id
          if itm.size < 2 then continue
          let basis := cfg.basis
          let Phi := itm.map (fun i => evalBasis basis paths[i]![k]!)
          let y := itm.map (fun i =>
            let t_future := dates[tau[i]!]!
            cash[i]! * Float.exp (-r * (t_future - t_k))
          )
          -- Use the documented robust entry point (B4)
          let beta? := Numerics.normalEqSolveSafePure Phi y cfg.ridge
          match beta? with
          | none => continue
          | some beta =>
              let (newCash, newTau) := itm.foldl (fun (c, t) i =>
                let S := paths[i]![k]!
                let imm := payoff S
                let cont := (Array.zip (evalBasis basis S) beta).foldl (fun s (b,co) => s + b*co) 0.0
                if imm > cont then
                  (c.set! i imm, t.set! i k)
                else
                  (c, t)
              ) (cash, tau)
              cash := newCash
              tau := newTau
        (cash, tau)

      let total := (Array.zip finalCash finalTau).foldl (fun acc (cf, t_idx) =>
        acc + cf * Float.exp (-r * dates[t_idx]!)
      ) 0.0
      total / n.toFloat

def priceBermudanPut (cfg : Config) (spot strike rate vol maturity : Float) : IO Float := do
  pure (lsmcPrice cfg (fun S => max 0.0 (strike - S)) spot rate vol maturity)

def priceAmericanPut (cfg : Config) (spot strike rate vol maturity : Float) : IO Float := do
  priceBermudanPut cfg spot strike rate vol maturity

def priceBermudanCall (cfg : Config) (spot strike rate vol maturity : Float) : IO Float := do
  pure (lsmcPrice cfg (fun S => max 0.0 (S - strike)) spot rate vol maturity)

def priceAmericanCall (cfg : Config) (spot strike rate vol maturity : Float) : IO Float := do
  priceBermudanCall cfg spot strike rate vol maturity

end LSMC
end Finance
end LFSE
