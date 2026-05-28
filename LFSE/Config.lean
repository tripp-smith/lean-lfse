import LFSE.Error

namespace LFSE

structure Config where
  paths : Nat := 10000
  seed : UInt64 := 42
  traceLevel : Nat := 0
  output : String := "json"
  profile : String := "default"
  authToken : Option String := none
  maxInputBytes : Nat := 1048576
  serverHost : String := "127.0.0.1"
  serverPort : Nat := 8080
  deriving Repr, BEq

namespace Config

def default : Config := {}

def parseNatField (name value : String) : LFSEExcept Nat :=
  match value.trimAscii.toNat? with
  | some n => .ok n
  | none => .error (.configError s!"expected natural number for {name}, got `{value}`")

def parseLine (cfg : Config) (line : String) : LFSEExcept Config :=
  let trimmed := line.trimAscii.toString
  if trimmed = "" || trimmed.startsWith "#" then
    .ok cfg
  else
    match trimmed.splitOn ":" with
    | key :: rest =>
        let value := String.intercalate ":" rest |>.trimAscii.toString
        match key.trimAscii.toString with
        | "paths" => parseNatField "paths" value |>.map (fun n => { cfg with paths := n })
        | "seed" => parseNatField "seed" value |>.map (fun n => { cfg with seed := UInt64.ofNat n })
        | "traceLevel" => parseNatField "traceLevel" value |>.map (fun n => { cfg with traceLevel := n })
        | "trace_level" => parseNatField "trace_level" value |>.map (fun n => { cfg with traceLevel := n })
        | "output" => .ok { cfg with output := value }
        | "profile" => .ok { cfg with profile := value }
        | "authToken" => .ok { cfg with authToken := some value }
        | "auth_token" => .ok { cfg with authToken := some value }
        | "maxInputBytes" => parseNatField "maxInputBytes" value |>.map (fun n => { cfg with maxInputBytes := n })
        | "serverHost" => .ok { cfg with serverHost := value }
        | "serverPort" => parseNatField "serverPort" value |>.map (fun n => { cfg with serverPort := n })
        | other => .error (.configError s!"unknown config key `{other}`")
    | [] => .ok cfg

def parseYamlLike (content : String) (base : Config := {}) : LFSEExcept Config :=
  content.splitOn "\n" |>.foldl
    (fun acc line =>
      match acc with
      | .error err => .error err
      | .ok cfg => parseLine cfg line)
    (.ok base)

def applyEnv (env : List (String × String)) (cfg : Config) : LFSEExcept Config :=
  env.foldl
    (fun acc entry =>
      match acc with
      | .error err => .error err
      | .ok c =>
          match entry with
          | ("LFSE_PATHS", v) => parseNatField "LFSE_PATHS" v |>.map (fun n => { c with paths := n })
          | ("LFSE_SEED", v) => parseNatField "LFSE_SEED" v |>.map (fun n => { c with seed := UInt64.ofNat n })
          | ("LFSE_TRACE_LEVEL", v) => parseNatField "LFSE_TRACE_LEVEL" v |>.map (fun n => { c with traceLevel := n })
          | ("LFSE_OUTPUT", v) => .ok { c with output := v }
          | ("LFSE_AUTH_TOKEN", v) => .ok { c with authToken := some v }
          | ("LFSE_SERVER_HOST", v) => .ok { c with serverHost := v }
          | ("LFSE_SERVER_PORT", v) => parseNatField "LFSE_SERVER_PORT" v |>.map (fun n => { c with serverPort := n })
          | _ => .ok c)
    (.ok cfg)

def applyCli (overrides : List (String × String)) (cfg : Config) : LFSEExcept Config :=
  overrides.foldl
    (fun acc entry =>
      match acc with
      | .error err => .error err
      | .ok c => parseLine c (entry.fst ++ ": " ++ entry.snd))
    (.ok cfg)

def merge (yaml : Option String) (env cli : List (String × String)) : LFSEExcept Config := do
  let fromYaml ←
    match yaml with
    | some content => parseYamlLike content default
    | none => .ok default
  let fromEnv ← applyEnv env fromYaml
  applyCli cli fromEnv

def loadConfig (path : Option System.FilePath := none) (cli : List (String × String) := []) : IO (LFSEExcept Config) := do
  let yaml ←
    match path with
    | none => pure none
    | some p =>
        if ← System.FilePath.pathExists p then
          pure (some (← IO.FS.readFile p))
        else
          pure none
  pure (merge yaml [] cli)

end Config

def loadConfig := Config.loadConfig

end LFSE
