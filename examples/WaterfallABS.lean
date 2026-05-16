import LFSE

open LFSE

def absPayments : List Finance.Payment :=
  Finance.allocateWaterfall 100.0 [
    { name := "Senior", balance := 1000.0, rate := 0.05 },
    { name := "Mezz", balance := 500.0, rate := 0.08 }
  ]

#eval absPayments
