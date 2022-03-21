Benchee.run(
  %{
    "self encode small int" => fn -> CrockfordBase32.encode(1234) end,
    "other encode small int" => fn -> Base32Crockford.encode(1234) end
  }
)
Benchee.run(
  %{
    "self encode small int with checksum" => fn -> CrockfordBase32.encode(1234, checksum: true) end,
    "other encode small int with checksum" => fn -> Base32Crockford.encode(1234, checksum: true) end
  }
)
Benchee.run(
  %{
    "self encode small int with hyphen" => fn -> CrockfordBase32.encode(1234, chunk_size: 1) end,
    "other encode small int with hyphen" => fn -> Base32Crockford.encode(1234, partitions: 3) end
  }
)
Benchee.run(
  %{
    "self encode big int" => fn -> CrockfordBase32.encode(1_000_000_000_000) end,
    "other encode big int" => fn -> Base32Crockford.encode(1_000_000_000_000) end
  }
)
Benchee.run(
  %{
    "self encode big int with checksum" => fn -> CrockfordBase32.encode(1_000_000_000_000, checksum: true) end,
    "other encode big int with checksum" => fn -> Base32Crockford.encode(1_000_000_000_000, checksum: true) end
  }
)
Benchee.run(
  %{
    "self encode big int with hyphen" => fn -> CrockfordBase32.encode(1_000_000_000_000, chunk_size: 4) end,
    "other encode big int with hyphen" => fn -> Base32Crockford.encode(1_000_000_000_000, partitions: 2) end
  }
)
