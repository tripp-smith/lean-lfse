import Columnar
import LFSE.Data.Columnar
import LFSE.Registry.Basic

namespace LFSE
namespace Data

inductive ProviderKind where
  | csvLike
  | parquet
  | parquetMmap
  | arrowIpc
  | inMemory
  deriving Repr, BEq

structure MarketDataProvider where
  name : String
  kind : ProviderKind
  source : String
  deriving Repr, BEq

def loadCsvProvider (source : String) : IO (LFSEExcept Context) := do
  if ← System.FilePath.pathExists source then
    loadMarketFile source
  else
    pure ((loadCsvLikeMarket source).map ColumnarMarket.toContext)

def tableContextStub (provider : MarketDataProvider) (rows cols : Nat) : Context :=
  ({} : Context)
    |>.withMarket "provider.rows" rows.toFloat
    |>.withMarket "provider.columns" cols.toFloat
    |>.withMarket "provider.kind" (match provider.kind with | .parquet => 1.0 | .parquetMmap => 2.0 | .arrowIpc => 3.0 | _ => 0.0)

def loadParquetProvider (provider : MarketDataProvider) : IO (LFSEExcept Context) := do
  match ← readParquet (System.FilePath.mk provider.source) with
  | Except.ok table => pure (.ok (tableContextStub provider (Columnar.Table.rowCount table) table.columns.size))
  | Except.error err => pure (.error (.dataError err))

def loadParquetMmapProvider (provider : MarketDataProvider) : IO (LFSEExcept Context) := do
  match ← readParquetMmap (System.FilePath.mk provider.source) with
  | Except.ok table => pure (.ok (tableContextStub provider (Columnar.Table.rowCount table) table.columns.size))
  | Except.error err => pure (.error (.dataError err))

def loadArrowProvider (provider : MarketDataProvider) : IO (LFSEExcept Context) := do
  match ← readArrowIpcStreamFile (System.FilePath.mk provider.source) with
  | Except.ok table => pure (.ok (tableContextStub provider (Columnar.Table.rowCount table) table.columns.size))
  | Except.error err => pure (.error (.dataError err))

def loadMarketProvider (provider : MarketDataProvider) : IO (LFSEExcept Context) := do
  match provider.kind with
  | .csvLike => loadCsvProvider provider.source
  | .inMemory => loadCsvProvider provider.source
  | .parquet => loadParquetProvider provider
  | .parquetMmap => loadParquetMmapProvider provider
  | .arrowIpc => loadArrowProvider provider

def providerEntry (name : String) (kind : ProviderKind) : Registry.DataProviderEntry := {
  descriptor := {
    kind := .dataProvider,
    name := name,
    version := "2.1.0",
    description := s!"Registered {repr kind} market data provider"
  },
  implementationKey := "lfse-data.provider." ++ name,
  load := fun req => do
    let res <- loadMarketProvider { name := name, kind := kind, source := req.source }
    pure (res.map Registry.ProviderResult.context)
}

def csvProviderEntry : Registry.DataProviderEntry :=
  providerEntry "csv" .csvLike

def parquetProviderEntry : Registry.DataProviderEntry :=
  providerEntry "parquet" .parquet

def parquetMmapProviderEntry : Registry.DataProviderEntry :=
  providerEntry "parquet-mmap" .parquetMmap

def arrowIpcProviderEntry : Registry.DataProviderEntry :=
  providerEntry "arrow-ipc" .arrowIpc

def registerBuiltInProviders (registry : Registry) : LFSEExcept Registry := do
  let registry <- Registry.registerProviderEntry registry csvProviderEntry
  let registry <- Registry.registerProviderEntry registry parquetProviderEntry
  let registry <- Registry.registerProviderEntry registry parquetMmapProviderEntry
  Registry.registerProviderEntry registry arrowIpcProviderEntry

end Data

abbrev MarketDataProvider := Data.MarketDataProvider
def loadMarketProvider := Data.loadMarketProvider

end LFSE
