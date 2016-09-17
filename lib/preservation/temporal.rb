module Preservation

  # Temporal
  #
  module Temporal

    # time_to_preserve?
    #
    # @param start_utc [String]
    # @param delay [Integer] days to wait (after start date) before preserving
    # @return [Boolean]
    def self.time_to_preserve?(start_utc, delay)
      now = DateTime.now
      start_datetime = DateTime.parse(start_utc)
      days_since_start = (now - start_datetime).to_i # result in days
      days_since_start >= delay ? true : false
    end

  end

end