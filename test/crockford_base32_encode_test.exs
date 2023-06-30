defmodule CrockfordBase32EncodeTest do
  use ExUnit.Case

  test "encode integer" do
    assert CrockfordBase32.encode(0) == "0"
    assert CrockfordBase32.encode(1234) == "16J"
    assert CrockfordBase32.encode(5111) == "4ZQ"
    assert CrockfordBase32.encode(Integer.pow(100, 10)) == "2PQHTY5NHH0000"
    assert CrockfordBase32.encode(Integer.pow(10, 9)) == "XSNJG0"
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

  test "encode string with split_size" do
    assert CrockfordBase32.encode("0", split_size: 1) == "6-0"
    assert CrockfordBase32.encode("0", split_size: 1, checksum: true) == "6-0-B"
    assert CrockfordBase32.encode("0", split_size: 2) == "60"
    assert CrockfordBase32.encode("0", split_size: 2, checksum: true) == "60-B"
    assert CrockfordBase32.encode("abc", split_size: 3, checksum: true) == "C5H-66C"
    assert CrockfordBase32.encode("abc", split_size: 6, checksum: true) == "C5H66C"
    assert CrockfordBase32.encode("abc", split_size: 7, checksum: true) == "C5H66C"
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
