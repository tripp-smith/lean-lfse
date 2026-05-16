import Lean
import Std.Data.HashMap
import LFSE.Error
import LFSE.Config

namespace LFSE

abbrev Amount := Float
abbrev Time := Nat

structure MarketPoint where
  name : String
  value : Float
  deriving Repr, BEq

structure Context where
  valuationDate : Nat := 0
  market : Std.HashMap String Float := {}
  metadata : Std.HashMap String String := {}
  deriving Repr

def Context.withMarket (ctx : Context) (name : String) (value : Float) : Context :=
  { ctx with market := ctx.market.insert name value }

def Context.lookup (ctx : Context) (name : String) : LFSEExcept Float :=
  match ctx.market.get? name with
  | some value => .ok value
  | none => .error (.missingObservable name)

structure TraceEvent where
  nodeId : Nat
  label : String
  value : Option Float := none
  deriving Repr, BEq

structure Result where
  scenario : String
  npv : Float
  greeks : List (String × Float) := []
  trace : List TraceEvent := []
  deriving Repr

def escapeJson (s : String) : String :=
  "\"" ++ s.foldl (fun acc c =>
    acc ++ match c with
    | '"' => "\\\""
    | '\\' => "\\\\"
    | '\n' => "\\n"
    | '\r' => "\\r"
    | '\t' => "\\t"
    | _ =>
        if c.toNat < 0x20 then
          "\\u00" ++ String.singleton (hexDigit (c.toNat / 16)) ++ String.singleton (hexDigit (c.toNat % 16))
        else
          String.singleton c) "" ++ "\""
where
  hexDigit (n : Nat) : Char :=
    if n < 10 then
      Char.ofNat ('0'.toNat + n)
    else
      Char.ofNat ('a'.toNat + (n - 10))

def pairJson (p : String × Float) : String :=
  "{" ++ "\"name\":" ++ escapeJson p.fst ++ ",\"value\":" ++ toString p.snd ++ "}"

def TraceEvent.toJson (ev : TraceEvent) : String :=
  let value :=
    match ev.value with
    | some v => ",\"value\":" ++ toString v
    | none => ""
  "{" ++ "\"nodeId\":" ++ toString ev.nodeId ++ ",\"label\":" ++ escapeJson ev.label ++ value ++ "}"

def Result.toJson (r : Result) : String :=
  let greeks := String.intercalate "," (r.greeks.map pairJson)
  let trace := String.intercalate "," (r.trace.map TraceEvent.toJson)
  "{" ++ "\"scenario\":" ++ escapeJson r.scenario ++
    ",\"npv\":" ++ toString r.npv ++
    ",\"greeks\":[" ++ greeks ++
    "],\"trace\":[" ++ trace ++ "]}"

def Result.toYaml (r : Result) : String :=
  let greeks :=
    if r.greeks.isEmpty then "greeks: []\n"
    else "greeks:\n" ++ String.intercalate "" (r.greeks.map (fun p => s!"  - name: {p.fst}\n    value: {p.snd}\n"))
  let trace :=
    if r.trace.isEmpty then "trace: []\n"
    else "trace:\n" ++ String.intercalate "" (r.trace.map (fun ev => s!"  - nodeId: {ev.nodeId}\n    label: {ev.label}\n"))
  s!"scenario: {r.scenario}\nnpv: {r.npv}\n{greeks}{trace}"

end LFSE
