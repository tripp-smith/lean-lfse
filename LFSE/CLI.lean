import LFSE.CLI.Commands

namespace LFSE
namespace CLI

def main (args : List String) : IO UInt32 :=
  Commands.run args

end CLI
end LFSE
