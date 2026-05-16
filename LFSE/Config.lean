namespace LFSE

structure Config where
  paths : Nat := 10000
  seed : UInt64 := 42
  traceLevel : Nat := 0
  output : String := "json"
  deriving Repr, BEq

end LFSE
