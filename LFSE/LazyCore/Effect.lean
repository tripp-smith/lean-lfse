import LFSE.LazyCore.Node

namespace LFSE
namespace LazyCore

structure EffectHandler where
  name : String
  run : Context -> IO (LFSEExcept Float)

def EffectHandler.toNode (id : NodeId) (label : String) (ctx : Context) (handler : EffectHandler) : LazyNode :=
  .effect id label do
    match <- handler.run ctx with
    | .ok value => pure value
    | .error err => throw (IO.userError err.message)

def constantEffect (name : String) (value : Float) : EffectHandler :=
  { name := name, run := fun _ => pure (.ok value) }

end LazyCore
end LFSE
