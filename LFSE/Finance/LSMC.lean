import LFSE.Finance.LSMC.Config
import LFSE.Finance.LSMC.Algorithm

namespace LFSE
namespace Finance

/--
Legacy `LSMCConfig` + thin compatibility shims.

This module exists solely for backward compatibility during the Phase A transition.
New code should import `LFSE.Finance.LSMC.Config` (for `Config`) and/or
`LFSE.Finance.LSMC.Algorithm` (for `lsmcPrice` and the modern `priceBermudan*` helpers)
and use the rich `ExerciseStyle` / `BasisFamily` configuration directly.

All pricing functions here convert the legacy shape and delegate to the
authoritative implementation in the LSMC modules.
-/
structure LSMCConfig where
  paths : Nat := 1000
  seed : UInt64 := 42
  exerciseDates : List Float := [0.25, 0.5, 0.75, 1.0]
  deriving Repr, BEq

/-- Convert legacy flat config to the modern `LSMC.Config` (Phase B+). -/
def legacyConfigToModern (old : LSMCConfig) : LSMC.Config :=
  { paths := old.paths
  , seed  := old.seed
  , style := .bermudan old.exerciseDates.toArray
  -- All other fields (basis, antithetic, itmOnly, ridge, twoPass) take modern defaults.
  }

def priceBermudanPut (cfg : LSMCConfig) (spot strike rate vol maturity : Float) : IO Float := do
  LSMC.priceBermudanPut (legacyConfigToModern cfg) spot strike rate vol maturity

def priceBermudanCall (cfg : LSMCConfig) (spot strike rate vol maturity : Float) : IO Float := do
  LSMC.priceBermudanCall (legacyConfigToModern cfg) spot strike rate vol maturity

def priceAmericanPut (cfg : LSMCConfig) (spot strike rate vol maturity : Float) : IO Float := do
  LSMC.priceAmericanPut (legacyConfigToModern cfg) spot strike rate vol maturity

def priceAmericanCall (cfg : LSMCConfig) (spot strike rate vol maturity : Float) : IO Float := do
  LSMC.priceAmericanCall (legacyConfigToModern cfg) spot strike rate vol maturity

end Finance
end LFSE
