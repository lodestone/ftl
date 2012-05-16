module Methadone
  module ExecutionStrategy
    # <b>Methadone Internal - treat as private</b>
    #
    # Implementation for modern Rubies that uses the built-in Open3 library
    class Open_3 < MRI
      def run_command(command)
        stdout,stderr,status = Open3.capture3(command)
        [stdout.chomp,stderr.chomp,status]
      end
    end
  end
end
