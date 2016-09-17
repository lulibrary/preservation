module Preservation

  # Conversion
  #
  module Conversion
    # Binary to hexadecimal
    #
    # @param [Binary String]
    # @return [Hexadecimal String]
    def self.bin_to_hex(s)
      s.each_byte.map { |b| b.to_s(16) }.join
    end

    # Hexadecimal to binary
    #
    # @param [Hexadecimal String]
    # @return [Binary String]
    def self.hex_to_bin(s)
      s.scan(/../).map { |x| x.hex.chr }.join
    end

  end

end
