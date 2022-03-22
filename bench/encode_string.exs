Benchee.run(
  %{
    "self encode small string" => fn -> CrockfordBase32.encode("abcdefg") end,
    "other encode small string" => fn -> :base32_crockford.encode("abcdefg") end
  },
  print: [fast_warning: false]
)
Benchee.run(
  %{
    "self encode small string with checksum" => fn -> CrockfordBase32.encode("abcdefg", checksum: true) end,
    "other encode small string with checksum" => fn -> :base32_crockford.encode_check("abcdefg") end
  },
  print: [fast_warning: false]
)

string_128 = "Y2Wfub8SfiN_EHa9gvc4IIVH3RJ1NFm3UJpjovqGiOIMyDSuUOgBAIjHyWlSyref5rw4Jxo8ewLPXsB-e1jUXQCzH4TL5KBjBXFXnO4KEfZrbVs1qK6Qod1rEkIL0N-P"

Benchee.run(
  %{
    "self encode 128 size string" => fn -> CrockfordBase32.encode(string_128) end,
    "other encode 128 size string" => fn -> :base32_crockford.encode(string_128) end
  },
  print: [fast_warning: false]
)

Benchee.run(
  %{
    "self encode 128 size string with checksum" => fn -> CrockfordBase32.encode(string_128, checksum: true) end,
    "other encode 128 size string with checksum" => fn -> :base32_crockford.encode_check(string_128) end
  },
  print: [fast_warning: false]
)

bytes = <<System.system_time(:millisecond)::unsigned-size(48)>>

Benchee.run(
  %{
    "self encode 48 size bytes" => fn -> CrockfordBase32.encode(bytes) end,
    "other encode 48 size bytes" => fn -> :base32_crockford.encode(bytes) end
  },
  print: [fast_warning: false]
)
