defmodule CrockfordBase32FixedEncodingTest do
  use ExUnit.Case

  alias CrockfordBase32.Encoding

  test "encode 8-bits" do
    assert Encoding.Fixed8.encode("b") == CrockfordBase32.encode("b")
    assert Encoding.Fixed8.encode("c") == CrockfordBase32.encode("c")
    assert Encoding.Fixed8.encode("z") == CrockfordBase32.encode("z")
  end

  test "decode 8-bits" do
    assert Encoding.Fixed8.decode("C8") == CrockfordBase32.decode_to_binary("C8")
    assert Encoding.Fixed8.decode("C8") == CrockfordBase32.decode_to_binary("c8")
    assert Encoding.Fixed8.decode("DM") == CrockfordBase32.decode_to_binary("DM")
    assert Encoding.Fixed8.decode("f0") == CrockfordBase32.decode_to_binary("F0")
  end

  test "encode 128-bits" do
    data = <<1, 127, 155, 239, 108, 123, 101, 162, 98, 133, 136, 76, 221, 14, 158, 253>>
    assert bit_size(data) == 128
    encoded = Encoding.Fixed128.encode(data)
    assert encoded == "05ZSQVVCFDJT4RM5H16DT3MYZM"
    assert encoded == CrockfordBase32.encode(data)
  end

  test "decode 128-bits" do
    data = "abcdefghighlmlio"
    {:ok, decoded} = data |> Encoding.Fixed128.encode() |> Encoding.Fixed128.decode()
    assert data == decoded
  end

  test "encode invalid" do
    assert Encoding.Fixed8.encode("abc") == {:error, "invalid"}
    assert Encoding.Fixed128.encode("abcdefgh") == {:error, "invalid"}
  end

  test "decode invalid" do
    assert Encoding.Fixed8.decode("c?") == {:error, "invalid"}
    assert Encoding.Fixed8.decode(<<1, 2, 3>>) == {:error, "invalid"}
    assert Encoding.Fixed128.decode(<<1>>) == {:error, "invalid"}
    assert Encoding.Fixed128.decode("abcdef") == {:error, "invalid"}
  end
end
