# frozen_string_literal: true

module Infield
  class Railtie < Rails::Railtie
    initializer 'infield.enable_report_deprecations', before: 'active_support.deprecation_behavior' do |app|
      app.config.active_support.report_deprecations = true
    end

    initializer 'infield.deprecation_warnings', after: 'active_support.deprecation_behavior' do |app|
      infield_logger = lambda do |message, callstack, *_args|
        Infield::DeprecationWarning.log(message, callstack: callstack, validated: true)
      end

      # Rails >= 7.0 makes it so that there are named deprecators that can have their own behavior
      if app.respond_to?(:deprecators)
        app.deprecators.each do |deprecator|
          current_behaviors = Array(deprecator.behavior)
          deprecator.behavior = [infield_logger, *current_behaviors].uniq
        end
      else
        current_behaviors = Array(ActiveSupport::Deprecation.behavior)
        ActiveSupport::Deprecation.behavior = [infield_logger, *current_behaviors].uniq
      end
    end
  end
end
