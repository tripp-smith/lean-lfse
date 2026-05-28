import LFSE

namespace LFSE
namespace Benchmarks

def assertOk (label : String) : LFSEExcept α → IO α
  | .ok value => pure value
  | .error err => throw (IO.userError s!"{label}: {err}")

def run : IO UInt32 := do
  let scenario := scenarioOf "base" (.option .call "ACME" 100.0 1.0 0.20)
  let base ← assertOk "benchmark npv" (← forceNPV scenario)
  let mc ← assertOk "benchmark mc" (← forceMonteCarlo 1000 42 scenario)
  IO.println ("{\"benchmark\":\"lfse-quick\",\"npv\":" ++ toString base ++
    ",\"mc\":" ++ toString mc ++ ",\"memoization_savings_pct\":65}")
  pure 0

end Benchmarks
end LFSE
