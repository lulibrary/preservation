module Preservation

  # Temporal
  #
  module Temporal

    # time_to_preserve?
    #
    # @param start_utc [Time]
    # @param delay [Integer] days to wait (after start date) before preserving
    # @return [Boolean]
    def self.time_to_preserve?(start_utc, delay)
      now = Time.now
      days_since_start = (now - start_utc).to_i # result in days
      days_since_start >= delay ? true : false
    end

  end

end