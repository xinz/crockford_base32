defmodule Bench.Bits8 do
  use CrockfordBase32, bits_size: 8
end

defmodule Bench.Bits128 do
  use CrockfordBase32, bits_size: 128
end

Benchee.run(
  %{
    "common encode small string" => fn -> CrockfordBase32.encode("b") end,
    "fix size to encode small string" => fn -> Bench.Bits8.encode("b") end
  }
)

data = <<System.system_time(:millisecond)::unsigned-size(48), :crypto.strong_rand_bytes(10)::binary>>

Benchee.run(
  %{
    "common encode 128 bits string" => fn -> CrockfordBase32.encode(data) end,
    "fix size to encode 128 bits string" => fn -> Bench.Bits128.encode(data) end
  }
)
