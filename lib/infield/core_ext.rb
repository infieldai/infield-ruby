# frozen_string_literal: true

module Infield
  module Core
    def warn(*messages, **xargs)
      super

      callstack = caller_locations(1 + xargs[:uplevel].to_i)
      Infield::DeprecationWarning.log(*messages, callstack: callstack, validated: xargs[:category] == :deprecated)
    end
  end

  Kernel.prepend(Core)
end
