require 'iconv'

# Class encapsulating encodong converters to and from two character sets.
# Simplifies two way encoding.
class EncodingConverter

  # @param [Symbol] from_enc Iconv eatable encoding as symbol.
  # @param [Symbol] to_enc
  def initialize(from_enc, to_enc)
    @from_conv = Iconv.new(to_enc.to_s, from_enc.to_s)
    @to_conv = Iconv.new(from_enc.to_s, to_enc.to_s)
  end

  # Converts from from_enc to to_enc.
  #
  # @param [String] str
  # @return [String]
  def from(str)
    @from_conv.conv(str)
  end

  # Converts from to_enc to from_enc.
  #
  # @param [String] str
  # @return [String]
  def to(str)
    @to_conv.conv(str)
  end
end

# Dummy class doing no conversion.
# Used when no encoding conversion necessary.
class DummyEncodingConverter

  # @param [String] str
  # @return [String]
  def from(str)
    str
  end

  # @param [String] str
  # @return [String]
  def to(str)
    str
  end
end
