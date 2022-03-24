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

  test "encoding bytes size is 5-multiple" do
    data = <<100::size(25)>>
    encoded = Encoding.Fixed25.encode(data)
    assert String.starts_with?(encoded, "0") == true
    assert Encoding.Fixed25.decode(encoded) == {:ok, data}
  end

  test "encode integer as 48 bits" do
    data = 1648103085
    encoded = Encoding.Fixed48Integer.encode(data)
    assert String.starts_with?(encoded, "0") == true
    size = String.length(encoded)
    assert encoded == String.pad_leading(CrockfordBase32.encode(data), size, "0")
  end

  test "decode integer as 48 bits" do
    data = 12345
    encoded = Encoding.Fixed48Integer.encode(data)
    assert encoded == "0000000C1S"
    assert Encoding.Fixed48Integer.decode(encoded) == {:ok, data}
  end

  test "encode integer as 15 bits (5-multiple)" do
    data = 1001
    encoded = Encoding.Fixed15Integer.encode(data)
    assert String.trim_leading(encoded, "0") == CrockfordBase32.encode(data)
  end

  test "decode integer as 15 bits (5-multiple)" do
    # integer exceed case
    data = 987654
    encoded = Encoding.Fixed15Integer.encode(data)
    assert encoded == "4G6"
    assert Encoding.Fixed15Integer.decode(encoded) == {:ok, 4614}
    assert <<987654::size(15)>> == <<4614::size(15)>>

    data = 1001
    encoded = Encoding.Fixed15Integer.encode(data)
    assert encoded == "0Z9"
    assert Encoding.Fixed15Integer.decode(encoded) == {:ok, data}
  end
 
end
