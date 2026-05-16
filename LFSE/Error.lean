namespace LFSE

inductive LFSEError where
  | missingObservable (name : String)
  | invalidInput (message : String)
  | cycleDetected (nodeId : Nat)
  | duplicateNodeId (nodeId : Nat) (first second : String)
  | unsupportedMonteCarlo (instrument : String)
  | evaluationFailed (message : String)
  | cliError (message : String)
  | dataError (message : String)
  deriving Repr, BEq, Inhabited

def LFSEError.message : LFSEError → String
  | .missingObservable name => s!"missing observable `{name}`"
  | .invalidInput message => s!"invalid input: {message}"
  | .cycleDetected nodeId => s!"cycle detected while forcing node {nodeId}"
  | .duplicateNodeId nodeId first second =>
      s!"duplicate node id {nodeId} has conflicting labels `{first}` and `{second}`"
  | .unsupportedMonteCarlo instrument => s!"unsupported Monte Carlo instrument: {instrument}"
  | .evaluationFailed message => s!"evaluation failed: {message}"
  | .cliError message => s!"cli error: {message}"
  | .dataError message => s!"data error: {message}"

instance : ToString LFSEError where
  toString := LFSEError.message

abbrev LFSEExcept α := Except LFSEError α

end LFSE
