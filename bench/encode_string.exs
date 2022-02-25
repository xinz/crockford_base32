Benchee.run(
  %{
    "this lib encode small string" => fn -> CrockfordBase32.encode("abcdefg") end,
    "other lib encode small string" => fn -> :base32_crockford.encode("abcdefg") end
  }
)
Benchee.run(
  %{
    "this lib encode small string with checksum" => fn -> CrockfordBase32.encode("abcdefg", checksum: true) end,
    "other lib encode small string with checksum" => fn -> :base32_crockford.encode_check("abcdefg") end
  }
)

string_128 = "Y2Wfub8SfiN_EHa9gvc4IIVH3RJ1NFm3UJpjovqGiOIMyDSuUOgBAIjHyWlSyref5rw4Jxo8ewLPXsB-e1jUXQCzH4TL5KBjBXFXnO4KEfZrbVs1qK6Qod1rEkIL0N-P"

Benchee.run(
  %{
    "this lib encode 128 size string" => fn -> CrockfordBase32.encode(string_128) end,
    "other lib encode 128 size string" => fn -> :base32_crockford.encode(string_128) end
  }
)

Benchee.run(
  %{
    "this lib encode 128 size string with checksum" => fn -> CrockfordBase32.encode(string_128, checksum: true) end,
    "other lib encode 128 size string with checksum" => fn -> :base32_crockford.encode_check(string_128) end
  }
)
