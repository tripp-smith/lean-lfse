import LFSE.Finance.Observable

namespace LFSE
namespace Data

structure ColumnarMarket where
  rows : List MarketPoint
  deriving Repr, BEq

def ColumnarMarket.toContext (m : ColumnarMarket) : Context :=
  m.rows.foldl (fun ctx p => ctx.withMarket p.name p.value) {}

def trim (s : String) : String :=
  s.trimAscii.toString

def parseUnsignedFloat? (s : String) : Option Float :=
  match trim s |>.splitOn "." with
  | [whole] => whole.toNat?.map (fun n => n.toFloat)
  | [whole, frac] =>
      match whole.toNat?, frac.toNat? with
      | some w, some f =>
          let denom := Nat.pow 10 frac.length
          some (w.toFloat + f.toFloat / denom.toFloat)
      | _, _ => none
  | _ => none

def parseFloat? (s : String) : Option Float :=
  if s.startsWith "-" then
    parseUnsignedFloat? (s.drop 1).toString |>.map (fun x => -x)
  else
    parseUnsignedFloat? s

def loadCsvLikeMarket (content : String) : LFSEExcept ColumnarMarket :=
  let lines := content.splitOn "\n" |>.filter (fun line => trim line != "")
  let parseLine (line : String) : LFSEExcept MarketPoint :=
    match line.splitOn "," with
    | [name, value] =>
        match parseFloat? value with
        | some v => .ok { name := trim name, value := v }
        | none => .error (.dataError s!"invalid float in market row `{line}`")
    | _ => .error (.dataError s!"invalid market row `{line}`")
  lines.foldl
    (fun acc line =>
      match acc, parseLine line with
      | .ok rows, .ok row => .ok (rows ++ [row])
      | .error err, _ => .error err
      | _, .error err => .error err)
    (Except.ok [])
  |>.map (fun rows => { rows := rows })

def loadMarketFile (path : System.FilePath) : IO (LFSEExcept Context) := do
  let content ← IO.FS.readFile path
  pure ((loadCsvLikeMarket content).map ColumnarMarket.toContext)

end Data
end LFSE
