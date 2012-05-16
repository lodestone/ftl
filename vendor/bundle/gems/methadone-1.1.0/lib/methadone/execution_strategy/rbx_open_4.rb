module Methadone
  module ExecutionStrategy
    # <b>Methadone Internal - treat as private</b>
    #
    # For RBX; it throws a different exception when a command isn't found, so we override that here.
    class RBXOpen_4 < Open_4
      def exception_meaning_command_not_found
        [Errno::EINVAL] + Array(super)
      end
    end
  end
end
