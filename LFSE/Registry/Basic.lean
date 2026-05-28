import Std.Data.HashMap
import LFSE.LazyCore.Memo
import LFSE.LazyCore.GraphViz
import LFSE.LazyCore.Visualization

namespace LFSE
namespace Registry

inductive ComponentKind where
  | instrument
  | model
  | engine
  | dataProvider
  | dslExtension
  | graphExporter
  deriving Repr, BEq, Inhabited

def ComponentKind.asString : ComponentKind -> String
  | .instrument => "instrument"
  | .model => "model"
  | .engine => "engine"
  | .dataProvider => "dataProvider"
  | .dslExtension => "dslExtension"
  | .graphExporter => "graphExporter"

structure Descriptor where
  kind : ComponentKind
  name : String
  version : String := "1.0.0"
  description : String := ""
  deriving Repr, BEq

structure InstrumentEntry where
  descriptor : Descriptor
  implementationKey : String
  supportedEngineKeys : List String := []
  payoffBuilder : Nat -> LazyCore.LazyNode

structure PricingInput where
  scenarioName : String
  ctx : Context
  payoff : LazyCore.LazyNode
  instrumentKey : String
  fields : Std.HashMap String Float := {}
  text : String := ""

structure PricingEngineEntry where
  descriptor : Descriptor
  implementationKey : String
  price : PricingInput -> IO (LFSEExcept Result)

structure ProviderRequest where
  source : String
  options : List (String × String) := []
  deriving Repr, BEq

inductive ProviderResult where
  | context (ctx : Context)
  | metadata (items : List (String × String))
  deriving Repr

structure DataProviderEntry where
  descriptor : Descriptor
  implementationKey : String
  load : ProviderRequest -> IO (LFSEExcept ProviderResult)

structure DslExtensionEntry where
  descriptor : Descriptor
  implementationKey : String
  moduleName : String
  syntaxName : String
  expandsTo : String
  expandPreview : String -> LFSEExcept String

structure GraphExporterEntry where
  descriptor : Descriptor
  implementationKey : String
  render : LazyCore.LazyNode -> String

structure Registry where
  descriptors : Std.HashMap String Descriptor := {}
  instruments : Std.HashMap String InstrumentEntry := {}
  engines : Std.HashMap String PricingEngineEntry := {}
  providers : Std.HashMap String DataProviderEntry := {}
  dslExtensions : Std.HashMap String DslExtensionEntry := {}
  exporters : Std.HashMap String GraphExporterEntry := {}

def keyOf (kind : ComponentKind) (name : String) : String :=
  kind.asString ++ ":" ++ name

class Registerable (alpha : Type u) where
  descriptor : alpha -> Descriptor

def sameEntry (oldDesc newDesc : Descriptor) (oldKey newKey : String) : Bool :=
  oldDesc == newDesc && oldKey == newKey

def registerDescriptor (r : Registry) (d : Descriptor) : LFSEExcept Registry :=
  let key := keyOf d.kind d.name
  match r.descriptors.get? key with
  | none => .ok { r with descriptors := r.descriptors.insert key d }
  | some existing =>
      if existing == d then .ok r
      else .error (.registryError s!"duplicate descriptor for `{key}`")

def lookupDescriptor (r : Registry) (kind : ComponentKind) (name : String) : LFSEExcept Descriptor :=
  match r.descriptors.get? (keyOf kind name) with
  | some d => .ok d
  | none => .error (.registryError s!"missing descriptor `{keyOf kind name}`")

def containsDescriptor (r : Registry) (kind : ComponentKind) (name : String) : Bool :=
  r.descriptors.contains (keyOf kind name)

def contains (r : Registry) (kind : ComponentKind) (name : String) : Bool :=
  match kind with
  | .instrument => r.instruments.contains (keyOf kind name)
  | .engine => r.engines.contains (keyOf kind name)
  | .dataProvider => r.providers.contains (keyOf kind name)
  | .dslExtension => r.dslExtensions.contains (keyOf kind name)
  | .graphExporter => r.exporters.contains (keyOf kind name)
  | .model => r.descriptors.contains (keyOf kind name)

def empty : Registry := {}

def registerInstrumentEntry (r : Registry) (entry : InstrumentEntry) : LFSEExcept Registry := do
  if entry.descriptor.kind != .instrument then
    .error (.registryError s!"instrument entry `{entry.descriptor.name}` has wrong descriptor kind")
  else
    let key := keyOf .instrument entry.descriptor.name
    match r.instruments.get? key with
    | none =>
        let r <- registerDescriptor r entry.descriptor
        pure { r with instruments := r.instruments.insert key entry }
    | some existing =>
        if sameEntry existing.descriptor entry.descriptor existing.implementationKey entry.implementationKey then
          .ok r
        else
          .error (.registryError s!"duplicate instrument implementation for `{key}`")

def registerEngineEntry (r : Registry) (entry : PricingEngineEntry) : LFSEExcept Registry := do
  if entry.descriptor.kind != .engine then
    .error (.registryError s!"engine entry `{entry.descriptor.name}` has wrong descriptor kind")
  else
    let key := keyOf .engine entry.descriptor.name
    match r.engines.get? key with
    | none =>
        let r <- registerDescriptor r entry.descriptor
        pure { r with engines := r.engines.insert key entry }
    | some existing =>
        if sameEntry existing.descriptor entry.descriptor existing.implementationKey entry.implementationKey then
          .ok r
        else
          .error (.registryError s!"duplicate engine implementation for `{key}`")

def registerProviderEntry (r : Registry) (entry : DataProviderEntry) : LFSEExcept Registry := do
  if entry.descriptor.kind != .dataProvider then
    .error (.registryError s!"provider entry `{entry.descriptor.name}` has wrong descriptor kind")
  else
    let key := keyOf .dataProvider entry.descriptor.name
    match r.providers.get? key with
    | none =>
        let r <- registerDescriptor r entry.descriptor
        pure { r with providers := r.providers.insert key entry }
    | some existing =>
        if sameEntry existing.descriptor entry.descriptor existing.implementationKey entry.implementationKey then
          .ok r
        else
          .error (.registryError s!"duplicate provider implementation for `{key}`")

def registerDslExtensionEntry (r : Registry) (entry : DslExtensionEntry) : LFSEExcept Registry := do
  if entry.descriptor.kind != .dslExtension then
    .error (.registryError s!"DSL extension `{entry.descriptor.name}` has wrong descriptor kind")
  else
    let key := keyOf .dslExtension entry.descriptor.name
    match r.dslExtensions.get? key with
    | none =>
        let r <- registerDescriptor r entry.descriptor
        pure { r with dslExtensions := r.dslExtensions.insert key entry }
    | some existing =>
        if sameEntry existing.descriptor entry.descriptor existing.implementationKey entry.implementationKey then .ok r
        else .error (.registryError s!"duplicate DSL extension implementation for `{key}`")

def registerExporterEntry (r : Registry) (entry : GraphExporterEntry) : LFSEExcept Registry := do
  if entry.descriptor.kind != .graphExporter then
    .error (.registryError s!"exporter entry `{entry.descriptor.name}` has wrong descriptor kind")
  else
    let key := keyOf .graphExporter entry.descriptor.name
    match r.exporters.get? key with
    | none =>
        let r <- registerDescriptor r entry.descriptor
        pure { r with exporters := r.exporters.insert key entry }
    | some existing =>
        if sameEntry existing.descriptor entry.descriptor existing.implementationKey entry.implementationKey then
          .ok r
        else
          .error (.registryError s!"duplicate exporter implementation for `{key}`")

def lookupInstrument (r : Registry) (name : String) : LFSEExcept InstrumentEntry :=
  match r.instruments.get? (keyOf .instrument name) with
  | some entry => .ok entry
  | none => .error (.registryError s!"missing instrument implementation `{name}`")

def lookupEngine (r : Registry) (name : String) : LFSEExcept PricingEngineEntry :=
  match r.engines.get? (keyOf .engine name) with
  | some entry => .ok entry
  | none => .error (.registryError s!"missing engine implementation `{name}`")

def lookupProvider (r : Registry) (name : String) : LFSEExcept DataProviderEntry :=
  match r.providers.get? (keyOf .dataProvider name) with
  | some entry => .ok entry
  | none => .error (.registryError s!"missing data-provider implementation `{name}`")

def lookupDslExtension (r : Registry) (name : String) : LFSEExcept DslExtensionEntry :=
  match r.dslExtensions.get? (keyOf .dslExtension name) with
  | some entry => .ok entry
  | none => .error (.registryError s!"missing DSL extension `{name}`")

def lookupExporter (r : Registry) (name : String) : LFSEExcept GraphExporterEntry :=
  match r.exporters.get? (keyOf .graphExporter name) with
  | some entry => .ok entry
  | none => .error (.registryError s!"missing graph exporter `{name}`")

def analyticEngineEntry : PricingEngineEntry := {
  descriptor := { kind := .engine, name := "analytic", version := "2.1.0", description := "Analytic lazy graph pricing engine" },
  implementationKey := "lfse-core.engine.analytic.v1",
  price := fun input => do
    let (res, _stats, trace) <- LazyCore.force input.ctx input.payoff
    pure <| res.map fun npv => {
      scenario := input.scenarioName,
      npv := npv,
      trace := trace,
      lineage := LazyCore.exportLineage input.payoff
    }
}

def dotExporterEntry : GraphExporterEntry := {
  descriptor := { kind := .graphExporter, name := "dot", version := "2.1.0", description := "GraphViz DOT exporter" },
  implementationKey := "lfse-core.exporter.dot.v1",
  render := LazyCore.toDot
}

def mermaidExporterEntry : GraphExporterEntry := {
  descriptor := { kind := .graphExporter, name := "mermaid", version := "2.1.0", description := "Mermaid graph exporter" },
  implementationKey := "lfse-core.exporter.mermaid.v1",
  render := LazyCore.toMermaid
}

def graphJsonExporterEntry : GraphExporterEntry := {
  descriptor := { kind := .graphExporter, name := "json", version := "2.1.0", description := "Interactive graph JSON exporter" },
  implementationKey := "lfse-core.exporter.json.v1",
  render := LazyCore.toGraphJson
}

def defaultCore : LFSEExcept Registry := do
  let r <- registerEngineEntry empty analyticEngineEntry
  let r <- registerExporterEntry r dotExporterEntry
  let r <- registerExporterEntry r mermaidExporterEntry
  registerExporterEntry r graphJsonExporterEntry

end Registry

abbrev Registry := Registry.Registry
abbrev Registerable := Registry.Registerable

def registerInstrument (r : Registry) (entry : Registry.InstrumentEntry) : LFSEExcept Registry :=
  Registry.registerInstrumentEntry r entry

def registerEngine (r : Registry) (entry : Registry.PricingEngineEntry) : LFSEExcept Registry :=
  Registry.registerEngineEntry r entry

def registerDataProvider (r : Registry) (entry : Registry.DataProviderEntry) : LFSEExcept Registry :=
  Registry.registerProviderEntry r entry

def registerInstrumentDescriptor (r : Registry) (name : String) (description : String := "") : LFSEExcept Registry :=
  Registry.registerDescriptor r { kind := .instrument, name := name, version := "2.1.0", description := description }

def registerEngineDescriptor (r : Registry) (name : String) (description : String := "") : LFSEExcept Registry :=
  Registry.registerDescriptor r { kind := .engine, name := name, version := "2.1.0", description := description }

def registerDataProviderDescriptor (r : Registry) (name : String) (description : String := "") : LFSEExcept Registry :=
  Registry.registerDescriptor r { kind := .dataProvider, name := name, version := "2.1.0", description := description }

end LFSE
