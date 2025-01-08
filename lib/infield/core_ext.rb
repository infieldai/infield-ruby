# frozen_string_literal: true

module Infield
  module Core
    def warn(*messages, **xargs)
      super

      callstack = caller_locations(1 + xargs[:uplevel].to_i)
      Infield::DeprecationWarning.log(*messages, callstack: callstack, validated: xargs[:category] == :deprecated)
    end
  end

  module InfieldWarningCapture
    if Gem::Version.new(RUBY_VERSION) >= Gem::Version.new("3.0")
      # Ruby 3.0+ supports warn(msg, category: nil, **kwargs)
      def warn(msg, category: nil, **kwargs)
        super

        Infield::DeprecationWarning.log(msg, callstack: caller_locations, validated: category == :deprecated)
      end
    else
      # Ruby < 3.0 only provides a single argument to warn
      def warn(msg)
        super

        Infield::DeprecationWarning.log(msg, callstack: caller_locations, validated: false)
      end
    end
  end

  Kernel.extend(Core)
  Warning.extend(InfieldWarningCapture)
end
