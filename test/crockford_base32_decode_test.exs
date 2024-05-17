defmodule CrockfordBase32DecodeTest do
  use ExUnit.Case

  test "decode string without padding" do
    # keep the input string size is 5 (or multiples of 5) 
    # can make this test case
    items = ["YPgeI`r^yD", "abcdefghij", "IhOkH", "EuftlDISMiPbjNLywRvpT`WQY"]
    assert_encode_and_decode_binary(items)
  end

  test "decode string with padding" do
    items = ["sMGVjkvqKJdf", "_yqdSLBtQRMNZ", "U[bV]\\sBlEXoNpwvDIfMx"]
    assert_encode_and_decode_binary(items)
  end

  test "decode string with checksum" do
    items = ["abc", "1234567", "CFT[Gf\\LHXcWqQYPAbr]", "zwsvcyrbgknletaxji"]
    assert_encode_and_decode_binary(items, checksum: true)
  end

  test "decode integer" do
    items = [123, 1, 6_490_587_123, 5111]
    assert_encode_and_decode_integer(items)
  end

  test "decode integer with checksum" do
    items = [1_234_567, 0, 8_612_493_570, 5111]
    assert_encode_and_decode_integer(items, checksum: true)
  end

  test "input invalid to decode binary" do
    assert CrockfordBase32.decode_to_bitstring("C5H66") == {:ok, "abc"}
    assert CrockfordBase32.decode_to_bitstring("C5H66C", checksum: true) == {:ok, "abc"}
    assert CrockfordBase32.decode_to_bitstring("C5H66C") == {:ok, <<97, 98, 99, 3::size(4)>>}
    assert CrockfordBase32.decode_to_bitstring("C5H66", checksum: true) == :error_checksum
    assert CrockfordBase32.decode_to_bitstring("C5H66D", checksum: true) == :error_checksum

    assert CrockfordBase32.decode_to_bitstring(<<>>) == :error
  end

  test "invalid checksum when decode integer" do
    assert CrockfordBase32.decode_to_integer("16J") == {:ok, 1234}
    assert CrockfordBase32.decode_to_integer("16JD", checksum: true) == {:ok, 1234}
    assert CrockfordBase32.decode_to_integer("16JD") == {:ok, 39501}

    assert CrockfordBase32.decode_to_integer("16J1", checksum: true) == :error_checksum
  end

  test "decode with zero pad leading" do
    assert CrockfordBase32.decode_to_bitstring("05ZSQZWDJ0") == {:ok, <<1, 127, 155, 255, 141, 144>>}
    assert CrockfordBase32.decode_to_bitstring("04106") == {:ok, <<1, 2, 3>>}
  end

  test "invalid to decode" do
    assert CrockfordBase32.decode_to_bitstring(<<>>) == :error
    assert CrockfordBase32.decode_to_bitstring(<<1, 2, 3>>) == :error
    assert CrockfordBase32.decode_to_integer(<<>>) == :error
    assert CrockfordBase32.decode_to_integer(<<1, 2, 3>>) == :error
  end

  test "encode and decode a bitstring" do
    bits = <<1, 143, 130, 122, 250, 181, 117, 248, 153, 23, 163, 155, 135, 78, 106, 99>>
    bits2 = <<0::size(2), bits::bitstring>>
    input = CrockfordBase32.encode(bits2)
    assert input == "01HY17NYNNEQW9J5X3KE3MWTK3"
    {:ok, bitstring} = CrockfordBase32.decode_to_bitstring(input) 
    assert bitstring == bits2
    
    input = <<0::size(2), 1, 2, 3>>
    encoded = CrockfordBase32.encode(input)
    {:ok, res} = CrockfordBase32.decode_to_bitstring(encoded)
    assert input == res
  end

  defp assert_encode_and_decode_binary(items, opts \\ []) do
    Enum.map(items, fn item ->
      {:ok, decoded} =
        CrockfordBase32.encode(item, opts) |> CrockfordBase32.decode_to_bitstring(opts)

      assert item == decoded
    end)
  end

  defp assert_encode_and_decode_integer(items, opts \\ []) do
    Enum.map(items, fn item ->
      {:ok, decoded} =
        CrockfordBase32.encode(item, opts) |> CrockfordBase32.decode_to_integer(opts)

      assert item == decoded
    end)
  end
end
