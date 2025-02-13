# frozen_string_literal: true

module Infield
  class Railtie < Rails::Railtie
    initializer 'infield.deprecation_warnings', after: 'active_support.deprecation_behavior' do |_app|
      infield_lambda = lambda do |message, callstack, *args|
        Infield::DeprecationWarning.log(message, callstack: callstack, validated: true)
      end

      # Rails >= 7.0 makes it so that there are named deprecators that can have their own behavior
      if Rails.application.respond_to?(:deprecators)
        Rails.application.deprecators.each do |deprecator|
          current    = Array(deprecator.behavior)
          deprecator.behavior = [infield_lambda, *current].uniq
        end
      else
        current_behaviors = Array(ActiveSupport::Deprecation.behavior)
        ActiveSupport::Deprecation.behavior = [infield_lambda, *current_behaviors].uniq
      end
    end
  end
end
