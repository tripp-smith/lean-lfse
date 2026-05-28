import LFSE.Registry.Basic

namespace LFSE
namespace Registry

structure EngineDescriptor where
  name : String
  deterministic : Bool := true
  description : String := ""
  deriving Repr, BEq

instance : Registerable EngineDescriptor where
  descriptor d := {
    kind := .engine,
    name := d.name,
    version := "2.1.0",
    description := d.description
  }

def engineDescriptorOnly (d : EngineDescriptor) : Descriptor := {
  kind := .engine,
  name := d.name,
  version := "2.1.0",
  description := d.description
}

def registerEngineDescriptorOnly (r : Registry) (d : EngineDescriptor) : LFSEExcept Registry :=
  registerDescriptor r (engineDescriptorOnly d)

end Registry
end LFSE
