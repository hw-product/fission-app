module Fission
  module App
    class Backgroundable

      attr_reader :endpoint

      def initialize(endpoint=nil)
        @endpoint = endpoint || LocalExecution.new
      end

      def trigger!(args={})
        endpoint.transmit(args)
      end

      class LocalExecution

        def transmit(args={})
          job = args[:job]
          require "fission-app-jobs/utils/#{job}"
          Fission::App::Jobs::Utils.const_get(job.classify).new.run!(args)
        end

      end
    end
  end
end
