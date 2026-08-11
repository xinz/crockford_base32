# CrockfordBase32

[![Module Version](https://img.shields.io/hexpm/v/crockford_base32.svg)](https://hex.pm/packages/crockford_base32)
[![Hex Docs](https://img.shields.io/badge/hex-docs-lightgreen.svg)](https://hexdocs.pm/crockford_base32)

Crockford Base32 encoding and decoding for Elixir. It supports non-negative
integers, arbitrary bitstrings, optional check symbols, and fixed-width encoders.

See [Crockford's Base32 specification](https://www.crockford.com/base32.html)
for the format.

## Installation

```elixir
def deps do
  [
    {:crockford_base32, "~> 0.8"}
  ]
end
```

## Quick start

```elixir
iex> CrockfordBase32.encode(1234)
"16J"
iex> CrockfordBase32.encode("abc", checksum: true, split_size: 3)
"C5H-66C"
iex> CrockfordBase32.decode_to_integer("16-j")
{:ok, 1234}
iex> CrockfordBase32.decode_to_bitstring("C5H66C", checksum: true)
{:ok, "abc"}
iex> CrockfordBase32.encode(<<5::size(3)>>)
"M"
```

## Options and decoding

- `checksum: true` appends a Crockford check symbol when encoding. Pass the
  same option when decoding to require and validate the final symbol.
- `split_size` inserts hyphens between groups when encoding. Decoders ignore
  hyphens.
- Default decoding is case-insensitive; `I` and `L` decode as `1`, and `O`
  decodes as `0`.
- Invalid input returns `:error`; a failed check symbol returns
  `:error_checksum`.

The default output alphabet is `0123456789ABCDEFGHJKMNPQRSTVWXYZ`. Check
symbols additionally use `*~$=U`.

## Fixed-width encoders

Use a generated encoder when the bit length must be preserved exactly, such as for ULIDs, UUID-derived identifiers, or TypeID suffixes:

```elixir
defmodule MyApp.ULIDBase32 do
  use CrockfordBase32,
    bits_size: 128,
    type: :integer
end

value = <<1, 127, 155, 239, 108, 123, 101, 162, 98, 133, 136, 76, 221, 14, 158, 253>>
encoded = MyApp.ULIDBase32.encode(value)
{:ok, ^value} = MyApp.ULIDBase32.decode(encoded)
```

Generated modules expose `encode/1` and `decode/1`:

- `type: :bitstring` is the default and accepts only a bitstring with the
  configured size.
- `type: :integer` also accepts a non-negative integer. `decode/1` still
  returns the configured-width bitstring. Validate the integer range in your
  application when truncation would be unacceptable.

A custom alphabet must be a charlist:

```elixir
defmodule MyApp.TypeIDBase32 do
  use CrockfordBase32,
    bits_size: 130,
    alphabet: '0123456789abcdefghjkmnpqrstvwxyz'
end
```

## Bit-length note

Variable-length Base32 encoding pads the final group with zero bits. During
decoding, trailing zero data bits cannot always be distinguished from that
padding. Use a fixed-width encoder when every bit must round-trip exactly.

## Credits

Thanks to these implementations and references:

- [TheRealReal/ecto-ulid](https://github.com/TheRealReal/ecto-ulid)
- [shiguredo/base32_clockwork](https://github.com/shiguredo/base32_clockwork)
- [voldy/base32_crockford](https://github.com/voldy/base32_crockford)
- [levinalex/base32](https://github.com/levinalex/base32)
- [jbittel/base32-crockford](https://github.com/jbittel/base32-crockford)
- [dcode.fr's Crockford Base32 encoder](https://www.dcode.fr/crockford-base-32-encoding)
