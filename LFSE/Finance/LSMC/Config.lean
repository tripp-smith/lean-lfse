/-!
# LSMC Configuration Types (Phase B)

Full configuration shape as defined in the formal spec, including
`ExerciseStyle` and `BasisFamily`.

This module is the single source of truth for LSMC configuration during
Phase B (core algorithm correctness).
-/

namespace LFSE
namespace Finance
namespace LSMC

/-- How exercise opportunities are defined. -/
inductive ExerciseStyle where
  | bermudan (dates : Array Float)     -- Explicit strictly increasing dates > 0
  | american (steps : Nat)             -- Uniform discretization of [0, T] into `steps` intervals
  deriving Repr, BEq

/-- Choice of basis functions for the regression step. -/
inductive BasisFamily where
  | monomial (degree : Nat)
  | laguerre (degree : Nat)
  | hermite  (degree : Nat)
  deriving Repr, BEq

/-- Complete configuration for an LSMC pricing run. -/
structure Config where
  paths        : Nat          := 10000
  seed         : UInt64       := 42
  basis        : BasisFamily  := .laguerre 3
  style        : ExerciseStyle := .bermudan #[0.25, 0.5, 0.75, 1.0]
  antithetic   : Bool         := true
  twoPass      : Bool         := false
  itmOnly      : Bool         := true
  ridge        : Float        := 0.0
  deriving Repr, BEq

/-- Basic validation for Config. -/
def Config.validate (cfg : Config) : Except String Config :=
  if cfg.paths < 100 then
    .error "paths must be ≥ 100 for meaningful Monte Carlo"
  else if cfg.ridge < 0.0 || cfg.ridge > 1.0 then
    .error "ridge must be in [0, 1]"
  else
    match cfg.style with
    | .bermudan dates =>
        if dates.isEmpty then
          .error "bermudan dates cannot be empty"
        else if dates.any (fun d => d <= 0) then
          .error "all bermudan exercise dates must be > 0"
        else
          -- Check strictly increasing
          let sorted := dates.qsort (· < ·)
          if dates != sorted then
            .error "bermudan dates must be strictly increasing"
          else
            .ok cfg
    | .american steps =>
        if steps < 2 then
          .error "american steps must be ≥ 2"
        else
          .ok cfg

end LSMC
end Finance
end LFSE
