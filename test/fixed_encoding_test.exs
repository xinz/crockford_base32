defmodule CrockfordBase32FixedEncodingTest do
  use ExUnit.Case

  alias CrockfordBase32.Encoding

  test "encode 8-bits" do
    assert Encoding.Fixed8.encode("b") == CrockfordBase32.encode("b")
    assert Encoding.Fixed8.encode("c") == CrockfordBase32.encode("c")
    assert Encoding.Fixed8.encode("z") == CrockfordBase32.encode("z")
  end

  test "decode 8-bits" do
    assert Encoding.Fixed8.decode("C8") == CrockfordBase32.decode_to_bitstring("C8")
    assert Encoding.Fixed8.decode("C8") == CrockfordBase32.decode_to_bitstring("c8")
    assert Encoding.Fixed8.decode("DM") == CrockfordBase32.decode_to_bitstring("DM")
    assert Encoding.Fixed8.decode("f0") == CrockfordBase32.decode_to_bitstring("F0")
  end

  test "encode 128-bits" do
    data = <<1, 127, 155, 239, 108, 123, 101, 162, 98, 133, 136, 76, 221, 14, 158, 253>>
    assert bit_size(data) == 128
    encoded = Encoding.Fixed128.encode(data)
    assert encoded == "05ZSQVVCFDJT4RM5H16DT3MYZM"
    assert encoded == CrockfordBase32.encode(data)
  end

  test "encode 128-bits integer" do
    data = <<256, 143, 77, 98, 108, 55, 54, 32, 123, 234, 29, 55, 65, 200, 250, 217>>
    assert bit_size(data) == 128
    encoded = Encoding.Fixed128Integer.encode(data)
    assert encoded == "00HX6P4V1Q6RG7QTGX6X0WHYPS"
    assert {:ok, data} == Encoding.Fixed128Integer.decode(encoded)
  end

  test "decode 128-bits" do
    data = "abcdefghighlmlio"
    {:ok, decoded} = data |> Encoding.Fixed128.encode() |> Encoding.Fixed128.decode()
    assert data == decoded
  end

  test "size fixed case with i/l/o" do
    {:ok, bytes} = Encoding.Fixed130.decode("I23456789OL23456789OI23456")
    assert bytes == <<8, 134, 66, 152, 232, 72, 2, 33, 144, 166, 58, 18, 0, 136, 100, 41, 2::size(2)>>
    assert {:ok, ^bytes} = Encoding.Fixed130.decode("i23456789ol23456789oi23456")
  end

  test "encode invalid" do
    assert Encoding.Fixed8.encode("abc") == :error
    assert Encoding.Fixed128.encode("abcdefgh") == :error
  end

  test "decode invalid" do
    assert Encoding.Fixed8.decode("c?") == :error
    assert Encoding.Fixed8.decode(<<1, 2, 3>>) == :error
    assert Encoding.Fixed128.decode(<<1>>) == :error
    assert Encoding.Fixed128.decode("abcdef") == :error
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
    assert Encoding.Fixed48Integer.decode(encoded) == {:ok, <<data::48>>}
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
    assert Encoding.Fixed15Integer.decode(encoded) == {:ok, <<data::15>>}

    data = 1001
    encoded = Encoding.Fixed15Integer.encode(data)
    assert encoded == "0Z9"
    assert Encoding.Fixed15Integer.decode(encoded) == {:ok, <<data::15>>}
  end
 
  test "decode integer as bitstring" do
    data = 100
    encoded = Encoding.Fixed15Integer.encode(data)
    assert encoded == "034"
    assert Encoding.Fixed15Integer.decode(encoded) == {:ok, <<data::size(15)>>}
  end
end
