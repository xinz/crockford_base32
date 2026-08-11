# CrockfordBase32

[![Module Version](https://img.shields.io/hexpm/v/crockford_base32.svg)](https://hex.pm/packages/crockford_base32)
[![Hex Docs](https://img.shields.io/badge/hex-docs-lightgreen.svg)](https://hexdocs.pm/crockford_base32)

Crockford Base32 encoding and decoding for integers and bitstrings in Elixir. It supports non-negative integers, arbitrary bitstrings, optional check symbols, and fixed-width encoders.

See [Crockford's Base32 specification](https://www.crockford.com/base32.html) for the format.

## Installation

```elixir
def deps do
  [
    {:crockford_base32, "~> 0.9"}
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

## Fixed-width encoding

Generate fixed-width `encode/1` and `decode/1` functions when the input has a
known bit width. `decode/1` always returns a bitstring with the configured
width.

- `type: :bitstring` is the default and accepts only a bitstring with the configured size.
- `type: :integer` also accepts a non-negative integer. Validate the integer range in your application when fixed-width truncation would be unacceptable.

### ULID: a 128-bit integer

A [ULID](https://github.com/ulid/spec) combines a 48-bit Unix timestamp in
milliseconds with 80 bits of randomness. Use `type: :integer` to preserve the
numeric leading-zero padding required by its 26-character representation.

```elixir
defmodule MyApp.ULID.Base32 do
  use CrockfordBase32,
    bits_size: 128,
    type: :integer
end

timestamp_ms = 1_648_103_085_000
randomness = <<0::size(80)>>
ulid = <<timestamp_ms::unsigned-size(48), randomness::bitstring>>

encoded = MyApp.ULID.Base32.encode(ulid)
# "01FYX9JMY80000000000000000"

{:ok, ^ulid} = MyApp.ULID.Base32.decode(encoded)
```

### TypeID: a 130-bit bitstring

A [TypeID](https://github.com/jetify-com/typeid) suffix is 26 lowercase Base32
symbols. It represents two leading zero bits followed by a 128-bit UUID, so use
a fixed-width bitstring codec with TypeID's lowercase alphabet:

```elixir
defmodule MyApp.TypeID.Base32 do
  use CrockfordBase32,
    bits_size: 130,
    alphabet: ~c"0123456789abcdefghjkmnpqrstvwxyz"
end
```

The variable-length decoder cannot infer this 130-bit width and returns 128
bits for the sample suffix. The fixed-width decoder preserves all 130 bits:

```elixir
suffix = "01hy3b3hq5fmevjn8me7c4hzdm"

{:ok, variable_width} = CrockfordBase32.decode_to_bitstring(suffix)
bit_size(variable_width)
# 128

{:ok, type_id} = MyApp.TypeID.Base32.decode(suffix)
bit_size(type_id)
# 130

MyApp.TypeID.Base32.encode(type_id)
# "01hy3b3hq5fmevjn8me7c4hzdm"
```

## Credits

Thanks to these implementations and references:

- [TheRealReal/ecto-ulid](https://github.com/TheRealReal/ecto-ulid)
- [shiguredo/base32_clockwork](https://github.com/shiguredo/base32_clockwork)
- [voldy/base32_crockford](https://github.com/voldy/base32_crockford)
- [levinalex/base32](https://github.com/levinalex/base32)
- [jbittel/base32-crockford](https://github.com/jbittel/base32-crockford)
- [dcode.fr's Crockford Base32 encoder](https://www.dcode.fr/crockford-base-32-encoding)
