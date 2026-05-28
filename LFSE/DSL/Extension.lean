import LFSE.Registry.Basic
import LFSE.DSL.Syntax

namespace LFSE
namespace DSL

structure ExtensionSpec where
  name : String
  moduleName : String
  syntaxName : String
  expandsTo : String
  description : String := ""
  deriving Repr, BEq

def ExtensionSpec.toRegistryEntry (spec : ExtensionSpec) : Registry.DslExtensionEntry := {
  descriptor := {
    kind := .dslExtension,
    name := spec.name,
    version := "2.1.0",
    description := spec.description
  },
  implementationKey := spec.moduleName ++ ":" ++ spec.syntaxName,
  moduleName := spec.moduleName,
  syntaxName := spec.syntaxName,
  expandsTo := spec.expandsTo,
  expandPreview := fun source => .ok s!"{spec.syntaxName} => {spec.expandsTo}: {source}"
}

def registerExtension (registry : Registry) (spec : ExtensionSpec) : LFSEExcept Registry :=
  Registry.registerDslExtensionEntry registry spec.toRegistryEntry

end DSL
end LFSE
