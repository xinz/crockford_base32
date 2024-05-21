defmodule Fixed128 do
  use CrockfordBase32,
    bits_size: 128
end

Benchee.run(
  %{
    "decode_to_binary" => fn -> CrockfordBase32.decode_to_bitstring("05ZV1G43W81HS41V10MT4Z1WMC", []) end,
    "fixed" => fn -> Fixed128.decode("05ZV1G43W81HS41V10MT4Z1WMC") end
  },
  print: [fast_warning: false]
)
