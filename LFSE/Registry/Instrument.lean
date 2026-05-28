import LFSE.Registry.Basic

namespace LFSE
namespace Registry

structure InstrumentDescriptor where
  name : String
  payoffFamily : String
  supportsMonteCarlo : Bool := false
  supportsGreeks : Bool := false
  deriving Repr, BEq

instance : Registerable InstrumentDescriptor where
  descriptor d := {
    kind := .instrument,
    name := d.name,
    version := "2.1.0",
    description := d.payoffFamily
  }

def instrumentDescriptorOnly (d : InstrumentDescriptor) : Descriptor := {
  kind := .instrument,
  name := d.name,
  version := "2.1.0",
  description := d.payoffFamily
}

def registerInstrumentDescriptorOnly (r : Registry) (d : InstrumentDescriptor) : LFSEExcept Registry :=
  registerDescriptor r (instrumentDescriptorOnly d)

end Registry
end LFSE
