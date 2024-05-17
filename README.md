# CrockfordBase32

An Elixir Implementation of Douglas Crockford's Base32 encoding.

Please see [https://www.crockford.com/base32.html](https://www.crockford.com/base32.html).

This library can encode an integer or a bitstring in Crockford's Base32, and also provide the way to decode the corresponding encoding.

## Installation

```elixir
def deps do
  [
    {:crockford_base32, "~> 0.7"}
  ]
end
```

## Usage

### Encode

Encode an integer:

```elixir
iex> CrockfordBase32.encode(1234)
"16J"
```

Encode an integer with `checksum: true`:

```elixir
iex> CrockfordBase32.encode(1234, checksum: true)
"16JD"
```

Encode an inetger, and insert hyphens (-) per the step size(via `split_size`) in encoded result:

```elixir
iex> CrockfordBase32.encode(1234, split_size: 2)
"16-J"
iex> CrockfordBase32.encode(1234, split_size: 1)
"1-6-J"
iex> CrockfordBase32.encode(1234, split_size: 1, checksum: true)
"1-6-J-D"
```

Encode a bitstring, and optional `split_size` and `checksum` options are both working:

```elixir
iex> CrockfordBase32.encode(<<12345678::size(48)>>)
"00001F319R"
iex> CrockfordBase32.encode("abc")
"C5H66"
iex> CrockfordBase32.encode("abc", checksum: true)
"C5H66C"
iex> CrockfordBase32.encode("abc", checksum: true, split_size: 3)
"C5H-66C"
iex> CrockfordBase32.encode(<<5::size(3)>>)
"M"
```

### Decode

There will internally remove all hyphen(s) before decoding.

Decode the encoded to an integer:

```elixir
iex> CrockfordBase32.decode_to_integer("16J")
{:ok, 1234}
iex> CrockfordBase32.decode_to_integer("16-J")
{:ok, 1234}
iex> CrockfordBase32.decode_to_integer("16-j")
{:ok, 1234}
```

With a check symbol, and decode the encoded to an integer:

```elixir
iex> CrockfordBase32.decode_to_integer("16JD", checksum: true)
{:ok, 1234}
iex> CrockfordBase32.decode_to_integer("16J1", checksum: true)
:error_checksum
```

Decode the encoded to a bitstring:

```elixir
iex> CrockfordBase32.decode_to_bitstring("00001F319R")
{:ok, <<0, 0, 0, 188, 97, 78>>}
iex> CrockfordBase32.decode_to_bitstring("C5H66")
{:ok, "abc"}
iex> CrockfordBase32.decode_to_bitstring("C5H-66")
{:ok, "abc"}
iex> CrockfordBase32.decode_to_bitstring("c5H-66")
{:ok, "abc"}
iex> CrockfordBase32.decode_to_bitstring("c5h-66")
{:ok, "abc"}
iex> CrockfordBase32.decode_to_bitstring("c5h66")
{:ok, "abc"}
iex> CrockfordBase32.decode_to_bitstring("M")
{:ok, <<5::size(3)>>}
```

With a check symbol, and decode the encoded to a bitstring:

```elixir
iex> CrockfordBase32.decode_to_bitstring("C5H66C", checksum: true)
{:ok, "abc"}
iex> CrockfordBase32.decode_to_bitstring("C5H66D", checksum: true)
:error_checksum
```

Some invalid cases:

```elixir
iex> CrockfordBase32.decode_to_bitstring(<<1, 2, 3>>)
:error
iex> CrockfordBase32.decode_to_bitstring(<<>>)
:error
iex> CrockfordBase32.decode_to_integer(<<1, 2, 3>>)
:error
iex> CrockfordBase32.decode_to_integer(<<>>)
:error
```

### Fixed Size Encoding

In some cases, you may want to encode the fixed size bytes, we can do this be with a better performance leverages the benefit of the pattern match of Elixir/Erlang. I use this feature to implement a [ULID](https://github.com/xinz/elixir_ulid) in Elixir.

Refer [ULID specification](https://github.com/ulid/spec#specification), a ULID concatenates a UNIX timestamp in milliseconds(a 48 bit integer) and a randomness in 80-bit, since an integer in bits are padded with some `<<0::1>>` leading when needed, and a ULID in 128-bit after encoded its length is 26 (can be divisible by 5), apply the fixed size encoding with `type: :integer` can efficiently encode/decode a ULID, for example:

```elixir
defmoule ULID do

  defmoule Base32.Bits128 do
    use CrockfordBase32,
      bits_size: 128,
      type: :integer # Optional, defaults to `:bitstring`
  end

end
```

Then we can use `ULID.Base32.Bits128` to encode/decode a 128-bit bitstring which concatenates an integer (as UNIX timestamp in millisecond) in 48-bit and a random generated in 80-bit.

## Credits

These libraries or tools are very helpful in understanding and reference, thanks!

- [TheRealReal/ecto-ulid](https://github.com/TheRealReal/ecto-ulid)
- [shiguredo/base32_clockwork](https://github.com/shiguredo/base32_clockwork)
- [voldy/base32_crockford](https://github.com/voldy/base32_crockford)
- [levinalex/base32](https://github.com/levinalex/base32)
- [jbittel/base32-crockford](https://github.com/jbittel/base32-crockford)
- [dcode.fr's crockford-base32 encoding](https://www.dcode.fr/crockford-base-32-encoding)
