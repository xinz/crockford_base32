defmodule CrockfordBase32EncodeTest do
  use ExUnit.Case

  test "encode integer" do
    assert CrockfordBase32.encode(0) == "0"
    assert CrockfordBase32.encode(1234) == "16J"
    assert CrockfordBase32.encode(5111) == "4ZQ"
    assert CrockfordBase32.encode(Integer.pow(100, 10)) == "2PQHTY5NHH0000"
    assert CrockfordBase32.encode(Integer.pow(10, 9)) == "XSNJG0"
  end

  test "encode integers across five-symbol chunk boundaries" do
    chunk_base = Integer.pow(2, 25)

    assert CrockfordBase32.encode(chunk_base - 1) == "ZZZZZ"
    assert CrockfordBase32.encode(chunk_base) == "100000"
    assert CrockfordBase32.encode(chunk_base + 1) == "100001"
    assert CrockfordBase32.encode(Integer.pow(2, 30) - 1) == "ZZZZZZ"
    assert CrockfordBase32.encode(Integer.pow(2, 31)) == "2000000"
    assert CrockfordBase32.encode(Integer.pow(2, 34)) == "G000000"
    assert CrockfordBase32.encode(Integer.pow(2, 50)) == "10000000000"
  end

  test "encode integer with checksum" do
    assert CrockfordBase32.encode(0, checksum: true) == "00"
    assert CrockfordBase32.encode(1234, checksum: true) == "16JD"
    assert CrockfordBase32.encode(5111, checksum: true) == "4ZQ5"
    assert CrockfordBase32.encode(Integer.pow(100, 10), checksum: true) == "2PQHTY5NHH0000T"
    assert CrockfordBase32.encode(Integer.pow(10, 9), checksum: true) == "XSNJG01"
  end

  test "encode integer with split_size" do
    assert CrockfordBase32.encode(0, split_size: 1) == "0"
    assert CrockfordBase32.encode(1234, split_size: 1) == "1-6-J"
    assert CrockfordBase32.encode(1234, split_size: 2) == "16-J"
    assert CrockfordBase32.encode(1234, split_size: 3) == "16J"
    assert CrockfordBase32.encode(1234, split_size: 4) == "16J"
    assert CrockfordBase32.encode(Integer.pow(10, 9), split_size: 3) == "XSN-JG0"
    assert CrockfordBase32.encode(Integer.pow(100, 10), split_size: 2) == "2P-QH-TY-5N-HH-00-00"
  end

  test "encode string" do
    assert CrockfordBase32.encode("abc") == "C5H66"
    assert CrockfordBase32.encode("base") == "C9GQ6S8"
    assert CrockfordBase32.encode("HelloTest123") == "91JPRV3FAHJQ6X1H68SG"
    assert CrockfordBase32.encode("z0VtEaUte3MR_901zB4cM") == "F8R5CX25C5AQ8S9K9N95YE9G65X44D339M"

    assert CrockfordBase32.encode("mS_hVej7Fa1yzCn_qaH5dgnBU9F8dobt") ==
             "DN9NYT2PCNN3EHK165WQMGVEBXRP2J1NCHKPWGJN7533GS3FC9T0"

    assert CrockfordBase32.encode("测试") == "WTTRQT5FJM"
    assert CrockfordBase32.encode("テスト") == "WE1RDRW2Q7HR720"
    assert CrockfordBase32.encode("測試") == "WTWAST59MR"
  end

  test "encode string with checksum" do
    assert CrockfordBase32.encode("0", checksum: true) == "60B"
    assert CrockfordBase32.encode("base", checksum: true) == "C9GQ6S8J"
    assert CrockfordBase32.encode("abc", checksum: true) == "C5H66C"

    assert CrockfordBase32.encode(
             "9PfOBEizSF58uAvY1qo_3_xWgsqs06LND99HPFZsEWtd5oOpFoQqWa6LY_mpe5Hv",
             checksum: true
           ) ==
             "7586CKT28NMQMMT66MW7AGBPB4RQ2VTZ6DFQGNV7EDRQ6C1P9H748E9S9184CPKK8NBQ8S1NDX7Q0HKFA5RNER9P9HCNYVBGCMTMGXGB"

    assert CrockfordBase32.encode(
             "7Bs0pzuNyEYLhkQ9fXI76-quEhpn9MRHfUViVAVQXR3AaRdWMR7K--8MLOL64vipDkPpZ1x3jrxRi6crIDzO4iXkYMn5fAjKWV1ApH5svrFmCdMj_dXBscgRuEIWSwiL",
             checksum: true
           ) ==
             "6X176C3GF9TMWYA5B566GTTH75K5GJ9Q6RPQ2XA5D1R6WEADA946CNAPD5B42NJHB1936GB1A9J5EKAJ6X5JTB9R9N64YK1P6HV6JW24DD870PHHF0SPMWKRA9MKCRVJ9527MKSMD5C6PPADDRTPCGBA9DBNCCA1E143AWVPE936TGV49NN5YS2R89SP6STJEN2MJNTKEXMMR*"

    assert CrockfordBase32.encode("测试", checksum: true) == "WTTRQT5FJMM"
  end

  test "calculate bitstring checksums across 20-bit boundaries" do
    Enum.each([19, 20, 21, 39, 40, 41], fn size ->
      Enum.each([Integer.pow(2, size - 1), Integer.pow(2, size - 1) + 1], fn value ->
        input = <<value::size(size)>>
        checksum = expected_bitstring_checksum(input)
        encoded = CrockfordBase32.encode(input, checksum: true)

        assert encoded == CrockfordBase32.encode(input) <> <<checksum>>
      end)
    end)
  end

  test "decode byte-aligned checksums across 20-bit boundaries" do
    Enum.each([<<1, 2, 3>>, <<1, 2, 3, 4, 5>>, <<1, 2, 3, 4, 5, 6, 7>>], fn input ->
      encoded = CrockfordBase32.encode(input, checksum: true)
      assert {:ok, ^input} = CrockfordBase32.decode_to_bitstring(encoded, checksum: true)
    end)
  end

  test "encode string with split_size" do
    assert CrockfordBase32.encode("0", split_size: 1) == "6-0"
    assert CrockfordBase32.encode("0", split_size: 1, checksum: true) == "6-0-B"
    assert CrockfordBase32.encode("0", split_size: 2) == "60"
    assert CrockfordBase32.encode("0", split_size: 2, checksum: true) == "60-B"
    assert CrockfordBase32.encode("abc", split_size: 3, checksum: true) == "C5H-66C"
    assert CrockfordBase32.encode("abc", split_size: 6, checksum: true) == "C5H66C"
    assert CrockfordBase32.encode("abc", split_size: 7, checksum: true) == "C5H66C"
  end

  test "encode non-byte-aligned bitstrings" do
    cases = [
      {<<>>, "", "0"},
      {<<1::size(1)>>, "G", "G1"},
      {<<1::size(2)>>, "8", "81"},
      {<<1::size(3)>>, "4", "41"},
      {<<1::size(4)>>, "2", "21"},
      {<<1::size(5)>>, "1", "11"},
      {<<1::size(6)>>, "0G", "0G1"},
      {<<1::size(7)>>, "08", "081"}
    ]

    Enum.each(cases, fn {input, encoded, encoded_with_checksum} ->
      assert CrockfordBase32.encode(input) == encoded
      assert CrockfordBase32.encode(input, checksum: true) == encoded_with_checksum
    end)
  end

  test "encode and decode a large bitstring with checksum" do
    payload = IO.iodata_to_binary(:lists.duplicate(512, <<0, 1, 2, 3, 4, 5, 6, 7>>))
    checksum = rem(:binary.decode_unsigned(payload), 37)
    expected_checksum = Enum.at(~c"0123456789ABCDEFGHJKMNPQRSTVWXYZ*~$=U", checksum)

    encoded = CrockfordBase32.encode(payload, checksum: true)

    assert encoded == CrockfordBase32.encode(payload) <> <<expected_checksum>>
    assert {:ok, ^payload} = CrockfordBase32.decode_to_bitstring(encoded, checksum: true)
  end

  defp expected_bitstring_checksum(bitstring) do
    checksum = expected_bitstring_checksum(bitstring, 0)
    Enum.at(~c"0123456789ABCDEFGHJKMNPQRSTVWXYZ*~$=U", checksum)
  end

  defp expected_bitstring_checksum(<<>>, checksum), do: checksum

  defp expected_bitstring_checksum(<<bit::size(1), rest::bitstring>>, checksum) do
    expected_bitstring_checksum(rest, rem(checksum * 2 + bit, 37))
  end

  test "encode binary with zero pad leading" do
    # from <<System.system_time(:millisecond)::unsigned-size(48)>>
    bytes = <<1, 127, 155, 255, 141, 144>>
    assert CrockfordBase32.encode(bytes) == "05ZSQZWDJ0"
    bytes = <<1, 2, 3>>
    assert CrockfordBase32.encode(bytes) == "04106"
    bytes = <<0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0>>
    assert CrockfordBase32.encode(bytes) == "00000000000000000000000000"
    bytes = <<0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0>>
    assert CrockfordBase32.encode(bytes, checksum: true) == "000000000000000000000000000"
    bytes = <<8, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0>>
    assert CrockfordBase32.encode(bytes) == "10000000000000000000000000"
    bytes = <<0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1>>
    assert CrockfordBase32.encode(bytes) == "00000000000000000000000004"
  end
end
