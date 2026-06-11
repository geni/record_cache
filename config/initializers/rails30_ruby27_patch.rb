# Patch for Rails 3.0.20 to work with Ruby 2.7.8
# Fixes "circular argument reference" error in ActiveSupport::TimeZone

# We need to load time_zone early and reopen the class to fix the method
# This must run AFTER TimeZone is defined but BEFORE the circular reference error occurs

# Silence warnings about redefining the method
original_verbose = $VERBOSE
$VERBOSE = nil

require 'active_support/values/time_zone'

module ActiveSupport
  class TimeZone
    # Ruby 2.7+ doesn't allow circular argument references
    # Original: def now(now = ::Time.now)
    # Fixed version:
    def now(time_now = nil)
      time_now ||= ::Time.now
      utc_to_local(time_now.utc)
    end
  end
end

$VERBOSE = original_verbose
