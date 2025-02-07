# frozen_string_literal: true

module Infield
  class Railtie < Rails::Railtie
    initializer 'infield.deprecation_warnings', after: 'active_support.deprecation_behavior' do |_app|
      ActiveSupport::Notifications.subscribe('deprecation.rails') do |_name, _start, _finish, _id, payload|

        Infield::DeprecationWarning.log(payload[:message], callstack: payload[:callstack], validated: true)
      end
    end
  end
end
