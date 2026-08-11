# Inputs are built once so Benchee measures codec work rather than fixture setup.
payload_size = 64 * 1024
payload_pattern = <<1, 35, 69, 103, 137, 171, 205, 239, 16, 50, 84, 118, 152, 186, 220, 254>>
payload = IO.iodata_to_binary(:lists.duplicate(div(payload_size, byte_size(payload_pattern)), payload_pattern))

bitstring_encoded = CrockfordBase32.encode(payload)
bitstring_checked = CrockfordBase32.encode(payload, checksum: true)
bitstring_hyphenated = CrockfordBase32.encode(payload, split_size: 4)

integer = :binary.decode_unsigned(payload)
integer_encoded = CrockfordBase32.encode(integer)
integer_checked = CrockfordBase32.encode(integer, checksum: true)

Benchee.run(
  %{
    "bitstring encode 64 KiB" => fn -> CrockfordBase32.encode(payload) end,
    "bitstring encode 64 KiB with checksum" => fn -> CrockfordBase32.encode(payload, checksum: true) end,
    "bitstring decode 64 KiB" => fn -> CrockfordBase32.decode_to_bitstring(bitstring_encoded) end,
    "bitstring decode 64 KiB with checksum" => fn ->
      CrockfordBase32.decode_to_bitstring(bitstring_checked, checksum: true)
    end,
    "bitstring decode 64 KiB with hyphens" => fn ->
      CrockfordBase32.decode_to_bitstring(bitstring_hyphenated)
    end,
    "integer encode 64 KiB" => fn -> CrockfordBase32.encode(integer) end,
    "integer encode 64 KiB with checksum" => fn -> CrockfordBase32.encode(integer, checksum: true) end,
    "integer decode 64 KiB" => fn -> CrockfordBase32.decode_to_integer(integer_encoded) end,
    "integer decode 64 KiB with checksum" => fn ->
      CrockfordBase32.decode_to_integer(integer_checked, checksum: true)
    end
  },
  memory_time: 1,
  print: [fast_warning: false],
  time: 3,
  warmup: 1
)
