import Lake
open Lake DSL

package «lean-lfse» where
  version := v!"0.1.0"
  keywords := #["finance", "lazy", "scenario", "monte-carlo", "dsl"]
  description := "Lazy Financial Scenario Engine for verifiable financial scenario evaluation in Lean 4"
  license := "MIT"
  readmeFile := "README.md"

require leancontracts from git
  "git@github.com:tripp-smith/leancontracts.git" @ "b9fc2e85897774decd01126f1b2e6a943adabd91"
require columnar from git
  "git@github.com:tripp-smith/lean-columnar.git" @ "788a42222d0112f3fab43f96825ac14a2297e4da"
require «lean-yaml» from git
  "git@github.com:tripp-smith/lean-yaml.git" @ "13c10e8b34a37945b4f89069a1f681f0031c0e9e"

@[default_target]
lean_lib LFSE where
  roots := #[`LFSE]

lean_exe lfse where
  root := `Main

@[test_driver]
lean_exe test where
  root := `Test

lean_exe bench where
  root := `Benchmarks

script benchmarks := do
  let out ← IO.Process.output { cmd := "lake", args := #["exe", "bench"] }
  IO.print out.stdout
  IO.eprint out.stderr
  return out.exitCode
