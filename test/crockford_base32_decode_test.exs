defmodule CrockfordBase32DecodeTest do
  use ExUnit.Case

  test "decode string without padding" do
    # keep the input string size is 5 (or multiples of 5) 
    # can make this test case
    items = ["YPgeI`r^yD", "abcdefghij", "IhOkH", "EuftlDISMiPbjNLywRvpT`WQY"]
    assert_encode_and_decode_string(items)
  end

  test "decode string with padding" do
    items = ["sMGVjkvqKJdf", "_yqdSLBtQRMNZ", "U[bV]\\sBlEXoNpwvDIfMx"]
    assert_encode_and_decode_string(items)
  end

  test "decode string with checksum" do
    items = ["abc", "1234567", "CFT[Gf\\LHXcWqQYPAbr]", "zwsvcyrbgknletaxji"]
    assert_encode_and_decode_string(items, checksum: true)
  end

  test "decode integer" do
    items = [123, 1, 6490587123, 5111]
    assert_encode_and_decode_integer(items)
  end

  test "decode integer with checksum" do
    items = [1234567, 0, 8612493570, 5111]
    assert_encode_and_decode_integer(items, checksum: true)
  end

  test "input invalid to decode string" do
    assert CrockfordBase32.decode_to_string("C5H66") == {:ok, "abc"}
    assert CrockfordBase32.decode_to_string("C5H66C", checksum: true) == {:ok, "abc"}
    assert CrockfordBase32.decode_to_string("C5H66C") == {:error, "invalid"}
    assert CrockfordBase32.decode_to_string("C5H66", checksum: true) == {:error, "invalid"}
    assert CrockfordBase32.decode_to_string("C5H66D", checksum: true) == {:error, "invalid_checksum"}
    assert CrockfordBase32.decode_to_string(<<>>) == {:error, "invalid"}
  end

  test "input invalid to decode integer" do
    assert CrockfordBase32.decode_to_integer("16J") == {:ok, 1234}
    assert CrockfordBase32.decode_to_integer("16JD", checksum: true) == {:ok, 1234}
    assert CrockfordBase32.decode_to_integer("16JD") == {:ok, 39501}
    assert CrockfordBase32.decode_to_integer("16J1", checksum: true) == {:error, "invalid_checksum"}
    assert CrockfordBase32.decode_to_integer(<<>>) == {:error, "invalid"}
  end

  test "decode with zero pad leading" do
    assert CrockfordBase32.decode_to_string("05ZSQZWDJ0") == {:ok, <<1, 127, 155, 255, 141, 144>>}
    assert CrockfordBase32.decode_to_string("04106") == {:ok, <<1, 2, 3>>}
  end

  defp assert_encode_and_decode_string(items, opts \\ []) do
    Enum.map(items, fn item ->
      {:ok, decoded} = CrockfordBase32.encode(item, opts) |> CrockfordBase32.decode_to_string(opts)
      assert item == decoded
    end)
  end

  defp assert_encode_and_decode_integer(items, opts \\ []) do
    Enum.map(items, fn item ->
      {:ok, decoded} = CrockfordBase32.encode(item, opts) |> CrockfordBase32.decode_to_integer(opts)
      assert item == decoded
    end)
  end

end
