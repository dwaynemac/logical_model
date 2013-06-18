class LogicalModel
  module Hydra

    def self.included(base)
      base.send(:extend, ClassMethods)
    end

    module ClassMethods

      # Set which Hydra this class should use for calls.
      # @param hydra [Typhoues::Hydra]
      def use_hydra(hydra)
        self.hydra=(hydra)
      end

      def hydra
        @@hydra
      end

      def hydra=(hydra)
        @@hydra = hydra
      end
    end
  end
end