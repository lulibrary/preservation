module Preservation

  # String utilities
  #
  module StringUtil
    # Binary to hexadecimal
    #
    def self.bin_to_hex(s)
      s.each_byte.map { |b| b.to_s(16) }.join
    end

    # Hexadecimal to binary
    def self.hex_to_bin(s)
      s.scan(/../).map { |x| x.hex.chr }.join
    end

  end

end
