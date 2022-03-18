defmodule CrockfordBase32FixedEncodingTest do
  use ExUnit.Case

  alias CrockfordBase32.Encoding

  test "encode 8-bits" do
    assert Encoding.Fixed8.encode("b")  == CrockfordBase32.encode("b")
    assert Encoding.Fixed8.encode("c")  == CrockfordBase32.encode("c")
    assert Encoding.Fixed8.encode("z")  == CrockfordBase32.encode("z")
  end

  test "encode 128-bits" do
    data = <<1, 127, 155, 239, 108, 123, 101, 162, 98, 133, 136, 76, 221, 14, 158, 253>>
    assert bit_size(data) == 128
    assert Encoding.Fixed128.encode(data) == "05ZSQVVCFDJT4RM5H16DT3MYZM"
  end
end
