defmodule CrockfordBase32 do
  @moduledoc """
  Encodes and decodes non-negative integers and bitstrings with
  [Crockford's Base32](https://www.crockford.com/base32.html).
  """

  use CrockfordBase32.Symbol

  import Bitwise, only: [band: 2, bsl: 2, bsr: 2]

  @integer_chunk_bits 25
  # Avoid binary staging for common identifiers while limiting direct shifts to 10 Base32 digits.
  @integer_binary_threshold Integer.pow(2, 50)
  @checksum_chunk_bits 20

  @doc """
  Generates fixed-width `encode/1` and `decode/1` functions in the calling module.

  `:bits_size` sets the exact bit length. `:type` is `:bitstring` (default) or
  `:integer`; `:alphabet` accepts an optional custom charlist.
  """
  defmacro __using__(opts \\ []) do
    alias CrockfordBase32.FixedEncoding
    opts = Macro.prewalk(opts, &Macro.expand(&1, __CALLER__))
    bits_size = Keyword.get(opts, :bits_size)
    type = Keyword.get(opts, :type, :bitstring)
    alphabet = Keyword.get(opts, :alphabet)

    if bits_size != nil do
      quote do
        require FixedEncoding
        FixedEncoding.generate(unquote(bits_size), unquote(type), unquote(alphabet))
      end
    end
  end

  @doc """
  Encodes a non-negative integer or bitstring.

  Bitstrings may have any bit length. Output uses the default Crockford alphabet,
  `"0123456789ABCDEFGHJKMNPQRSTVWXYZ"`.

  ## Checksums

  Setting `checksum: true` appends one Crockford check symbol after the payload.
  The symbol is calculated modulo 37; for bitstrings, the calculation uses the
  original, unpadded bits. It helps detect accidental transcription errors, but
  is not a cryptographic integrity or authentication mechanism.

  Check symbols extend the output alphabet with `"*~$=U"`. `split_size` is
  applied after the check symbol is appended, so it is grouped with the rest of
  the output.

  ## Options

    * `:checksum` - set to `true` to append a check symbol.
    * `:split_size` - a positive group size; groups are separated by hyphens.

  ## Examples

      iex> CrockfordBase32.encode(1234)
      "16J"
      iex> CrockfordBase32.encode(1234, checksum: true)
      "16JD"
      iex> CrockfordBase32.encode("abc", checksum: true, split_size: 3)
      "C5H-66C"
  """
  @spec encode(non_neg_integer() | bitstring(), Keyword.t()) :: String.t()
  def encode(value, opts \\ [])

  def encode(value, opts) when is_integer(value) do
    value
    |> prepare_integer_encoding(Keyword.get(opts, :checksum, false))
    |> encode_integer()
    |> insert_hyphens(Keyword.get(opts, :split_size))
  end

  def encode(value, opts) when is_bitstring(value) do
    value
    |> encode_bitstring(Keyword.get(opts, :checksum, false))
    |> insert_hyphens(Keyword.get(opts, :split_size))
  end

  @doc """
  Decodes a Crockford Base32 string to a non-negative integer.

  Decoding ignores hyphens and is case-insensitive. `I` and `L` are aliases for
  `1`, and `O` is an alias for `0`.

  ## Checksums

  With `checksum: true`, the final non-hyphen symbol is treated as a check
  symbol and excluded from the payload. A mismatched valid check symbol returns
  `:error_checksum`; malformed input returns `:error`.

  Use this option only for values encoded with `checksum: true`; otherwise the
  final payload symbol is interpreted as a check symbol.

  ## Examples

      iex> CrockfordBase32.decode_to_integer("16-j")
      {:ok, 1234}
      iex> CrockfordBase32.decode_to_integer("16-JD", checksum: true)
      {:ok, 1234}
      iex> CrockfordBase32.decode_to_integer("16J1", checksum: true)
      :error_checksum
  """
  @spec decode_to_integer(String.t(), Keyword.t()) :: {:ok, non_neg_integer()} | :error | :error_checksum
  def decode_to_integer(string, opts \\ [])

  def decode_to_integer(<<>>, _opts) do
    error_invalid()
  end

  def decode_to_integer(string, opts) when is_binary(string) do
    string
    |> remove_hyphens()
    |> split_payload_and_checksum(Keyword.get(opts, :checksum, false))
    |> decode_integer()
  catch
    _error ->
      error_invalid()
  end

  @doc """
  Decodes a Crockford Base32 string to a bitstring.

  Decoding ignores hyphens and is case-insensitive. Because final zero padding
  is ambiguous, use a fixed-width encoder when the original bit length must be
  preserved.

  ## Checksums

  With `checksum: true`, the final non-hyphen symbol is treated as a check
  symbol and excluded from the payload. A mismatched valid check symbol returns
  `:error_checksum`; malformed input returns `:error`.

  Use this option only for values encoded with `checksum: true`; otherwise the
  final payload symbol is interpreted as a check symbol.

  ## Examples

      iex> CrockfordBase32.decode_to_bitstring("C5H66")
      {:ok, "abc"}
      iex> CrockfordBase32.decode_to_bitstring("C5H-66C", checksum: true)
      {:ok, "abc"}
      iex> CrockfordBase32.decode_to_bitstring("C5H66D", checksum: true)
      :error_checksum
  """
  @spec decode_to_bitstring(bitstring(), Keyword.t()) :: {:ok, bitstring()} | :error | :error_checksum
  def decode_to_bitstring(input, opts \\ [])

  def decode_to_bitstring(<<>>, _opts) do
    error_invalid()
  end

  def decode_to_bitstring(input, opts) when is_bitstring(input) do
    input
    |> remove_hyphens()
    |> split_payload_and_checksum(Keyword.get(opts, :checksum, false))
    |> decode_bitstring()
  catch
    _error ->
      error_invalid()
  end

  defp split_payload_and_checksum(input, false), do: {input, nil}
  defp split_payload_and_checksum(<<>>, true), do: {<<>>, <<>>}

  defp split_payload_and_checksum(input, true) when is_binary(input) do
    if Regex.match?(~r/\A[0-9A-Za-z*~$=]*\z/, input) do
      payload_size = byte_size(input) - 1
      <<payload::binary-size(payload_size), checksum::binary-size(1)>> = input
      {payload, checksum}
    else
      String.split_at(input, -1)
    end
  end

  defp split_payload_and_checksum(input, true), do: {input, nil}

  defp remove_hyphens(input) when is_binary(input) do
    String.replace(input, "-", "")
  end
  defp remove_hyphens(input), do: input

  defp decode_integer({str, nil}) do
    {:ok, decode_integer_symbols(str)}
  end

  defp decode_integer({str, <<checksum::integer-size(8)>>}) do
    check_value = d(checksum)
    integer = decode_integer_symbols(str)

    if check_value != rem(integer, 37) do
      invalid_checksum()
    else
      {:ok, integer}
    end
  end

  defp decode_integer(_), do: error_invalid()

  defp decode_integer_symbols(<<>>), do: 0

  defp decode_integer_symbols(symbols) do
    case trim_leading_zero_integer_symbols(symbols) do
      {:ok, <<>>} ->
        0

      {:ok, payload} ->
        case decode_canonical_integer(payload) do
          {:ok, integer} -> integer
          nil -> decode_integer_chunks(symbols, 0)
        end

      nil ->
        decode_integer_chunks(symbols, 0)
    end
  end

  defp trim_leading_zero_integer_symbols(<<>>), do: {:ok, <<>>}

  defp trim_leading_zero_integer_symbols(
         <<byte::integer-size(8), rest::binary>> = input
       ) do
    case d(byte) do
      0 -> trim_leading_zero_integer_symbols(rest)
      digit when digit <= 31 -> {:ok, input}
      _ -> nil
    end
  end

  defp decode_canonical_integer(payload) do
    padding_size = rem(8 - rem(byte_size(payload) * 5, 8), 8)

    case pack_canonical_integer(payload, padding_size, 0, []) do
      {:ok, binary} -> {:ok, :binary.decode_unsigned(binary)}
      nil -> nil
    end
  end

  defp pack_canonical_integer(<<>>, 0, 0, reversed_bytes) do
    {:ok, :erlang.list_to_binary(Enum.reverse(reversed_bytes))}
  end

  defp pack_canonical_integer(
         <<byte::integer-size(8), rest::binary>>,
         bit_count,
         carry,
         reversed_bytes
       ) do
    digit = d(byte)

    if digit > 31 do
      nil
    else
      bit_count = bit_count + 5
      carry = bsl(carry, 5) + digit

      if bit_count >= 8 do
        remaining_bit_count = bit_count - 8
        output_byte = bsr(carry, remaining_bit_count)
        carry = band(carry, bsl(1, remaining_bit_count) - 1)

        pack_canonical_integer(rest, remaining_bit_count, carry, [output_byte | reversed_bytes])
      else
        pack_canonical_integer(rest, bit_count, carry, reversed_bytes)
      end
    end
  end

  defp decode_integer_chunks(<<>>, acc), do: acc

  defp decode_integer_chunks(
         <<i1::integer-size(8), i2::integer-size(8), i3::integer-size(8),
           i4::integer-size(8), i5::integer-size(8), rest::binary>>,
         acc
       ) do
    chunk =
      bsl(d(i1), 20) + bsl(d(i2), 15) + bsl(d(i3), 10) + bsl(d(i4), 5) +
        d(i5)

    decode_integer_chunks(rest, bsl(acc, @integer_chunk_bits) + chunk)
  end

  defp decode_integer_chunks(<<byte::integer-size(8), rest::binary>>, acc) do
    decode_integer_chunks(rest, bsl(acc, 5) + d(byte))
  end

  defp checksum_valid?(bitstring, input_checksum) do
    bitstring_checksum_symbol(bitstring) == input_checksum
  end

  defp verify_checksum(decoded, full_decoded, checksum) do
    # double checksum with two kinds of decoded bitstrings in sequence
    if checksum_valid?(decoded, checksum) || checksum_valid?(full_decoded, checksum) do
      :ok
    else
      invalid_checksum()
    end
  end

  defp decode_bitstring({bitstring, nil}) do
    case decode_bitstring_symbols(bitstring, <<>>) do
      {:ok, decoded, _} ->
        {:ok, decoded}
      :error ->
        :error
    end
  end

  defp decode_bitstring({bitstring, <<checksum::integer-size(8)>>}) do
    with {:ok, decoded, full_decoded} <- decode_bitstring_symbols(bitstring, <<>>),
         :ok <- verify_checksum(decoded, full_decoded, checksum) do
      {:ok, decoded}
    else
      error when is_atom(error) ->
        error
    end
  end

  defp invalid_checksum(), do: :error_checksum

  defp encode_integer({value, checksum}) do
    encode_integer(value, checksum)
  end

  defp encode_integer(0, []), do: "0"
  defp encode_integer(0, ["0"]), do: "00"
  defp encode_integer(0, encoded), do: IO.iodata_to_binary(encoded)

  defp encode_integer(value, encoded)
       when value > 0 and value < @integer_binary_threshold do
    encode_integer(bsr(value, 5), [e(band(value, 31)) | encoded])
  end

  defp encode_integer(value, checksum) when value > 0 do
    encoded =
      value
      |> :binary.encode_unsigned()
      |> drop_integer_leading_zero_bits()
      |> left_pad_to_base32_boundary()
      |> encode_integer_bitstring_symbols_reversed([])
      |> Enum.reverse()

    IO.iodata_to_binary([encoded, checksum])
  end

  defp drop_integer_leading_zero_bits(<<0::size(1), rest::bitstring>>) do
    drop_integer_leading_zero_bits(rest)
  end

  defp drop_integer_leading_zero_bits(bitstring), do: bitstring

  # Numeric Base32 aligns the most significant group, unlike bitstring tail padding.
  defp left_pad_to_base32_boundary(bitstring) do
    padding_size = rem(5 - rem(bit_size(bitstring), 5), 5)
    <<0::size(padding_size), bitstring::bitstring>>
  end

  defp encode_bitstring(bitstring, true) do
    checksum = <<bitstring_checksum_symbol(bitstring)::integer-size(8)>>
    encode_bitstring_to_binary(bitstring, <<>>, checksum)
  end
  defp encode_bitstring(bitstring, _with_checksum) do
    encode_bitstring_to_binary(bitstring, <<>>, <<>>)
  end

  defp encode_bitstring_to_binary(<<>>, acc, checksum), do: <<acc::binary, checksum::binary>>

  # Append complete output blocks directly to avoid a per-symbol reversed charlist.
  defp encode_bitstring_to_binary(
         <<v1::integer-size(5), v2::integer-size(5), v3::integer-size(5),
           v4::integer-size(5), v5::integer-size(5), v6::integer-size(5),
           v7::integer-size(5), v8::integer-size(5), v9::integer-size(5),
           v10::integer-size(5), v11::integer-size(5), v12::integer-size(5),
           v13::integer-size(5), v14::integer-size(5), v15::integer-size(5),
           v16::integer-size(5), rest::bitstring>>,
         acc,
         checksum
       ) do
    encode_bitstring_to_binary(
      rest,
      <<acc::binary, e(v1), e(v2), e(v3), e(v4), e(v5), e(v6), e(v7), e(v8),
        e(v9), e(v10), e(v11), e(v12), e(v13), e(v14), e(v15), e(v16)>>,
      checksum
    )
  end

  defp encode_bitstring_to_binary(<<value::integer-size(5), rest::bitstring>>, acc, checksum) do
    encode_bitstring_to_binary(rest, <<acc::binary, e(value)>>, checksum)
  end

  defp encode_bitstring_to_binary(<<value::integer-size(4)>>, acc, checksum),
    do: <<acc::binary, e(bsl(value, 1)), checksum::binary>>

  defp encode_bitstring_to_binary(<<value::integer-size(3)>>, acc, checksum),
    do: <<acc::binary, e(bsl(value, 2)), checksum::binary>>

  defp encode_bitstring_to_binary(<<value::integer-size(2)>>, acc, checksum),
    do: <<acc::binary, e(bsl(value, 3)), checksum::binary>>

  defp encode_bitstring_to_binary(<<value::integer-size(1)>>, acc, checksum),
    do: <<acc::binary, e(bsl(value, 4)), checksum::binary>>

  defp encode_integer_bitstring_symbols_reversed(<<>>, symbols), do: symbols

  defp encode_integer_bitstring_symbols_reversed(
         <<value::integer-size(5), rest::bitstring>>,
         symbols
       ) do
    encode_integer_bitstring_symbols_reversed(rest, [e(value) | symbols])
  end

  defp encode_integer_bitstring_symbols_reversed(<<value::integer-size(4)>>, symbols),
    do: [e(bsl(value, 1)) | symbols]

  defp encode_integer_bitstring_symbols_reversed(<<value::integer-size(3)>>, symbols),
    do: [e(bsl(value, 2)) | symbols]

  defp encode_integer_bitstring_symbols_reversed(<<value::integer-size(2)>>, symbols),
    do: [e(bsl(value, 3)) | symbols]

  defp encode_integer_bitstring_symbols_reversed(<<value::integer-size(1)>>, symbols),
    do: [e(bsl(value, 4)) | symbols]

  defp bitstring_checksum_symbol(bitstring) do
    bitstring
    |> bitstring_checksum_remainder(0)
    |> e()
  end

  defp bitstring_checksum_remainder(<<>>, remainder), do: remainder

  defp bitstring_checksum_remainder(
         <<value::integer-size(@checksum_chunk_bits), rest::bitstring>>,
         remainder
       ) do
    bitstring_checksum_remainder(rest, rem(bsl(remainder, @checksum_chunk_bits) + value, 37))
  end

  defp bitstring_checksum_remainder(<<value::integer-size(5), rest::bitstring>>, remainder) do
    bitstring_checksum_remainder(rest, rem(bsl(remainder, 5) + value, 37))
  end

  defp bitstring_checksum_remainder(<<value::integer-size(4)>>, remainder),
    do: rem(bsl(remainder, 4) + value, 37)

  defp bitstring_checksum_remainder(<<value::integer-size(3)>>, remainder),
    do: rem(bsl(remainder, 3) + value, 37)

  defp bitstring_checksum_remainder(<<value::integer-size(2)>>, remainder),
    do: rem(bsl(remainder, 2) + value, 37)

  defp bitstring_checksum_remainder(<<value::integer-size(1)>>, remainder),
    do: rem(bsl(remainder, 1) + value, 37)

  defp prepare_integer_encoding(value, true) when is_integer(value) do
    {value, [<<integer_checksum_symbol(value)::integer>>]}
  end

  defp prepare_integer_encoding(value, _) do
    {value, []}
  end

  defp integer_checksum_symbol(value) do
    value |> rem(37) |> e()
  end

  defp insert_hyphens(encoded, split_size)
       when is_integer(split_size) and split_size > 0 do
    insert_hyphens(encoded, split_size, [])
  end

  defp insert_hyphens(encoded, _), do: encoded

  defp insert_hyphens(str, size, chunks) when byte_size(str) > size do
    <<chunk::size(size)-binary, rest::binary>> = str
    insert_hyphens(rest, size, [chunk | chunks])
  end

  defp insert_hyphens(str, _size, []), do: str

  defp insert_hyphens(rest, _size, chunks) do
    Enum.reverse([rest | chunks]) |> Enum.join("-")
  end

  @doc false
  def error_invalid(), do: :error

  defp trim_trailing_padding_bits(bitstring, size) when size > 5 do
    for(<<x::size(1) <- bitstring>>, do: x)
    |> Enum.reverse()
    |> Enum.drop_while(fn
      0 -> true
      1 -> false
    end)
    |> Enum.reduce(<<>>, fn i, acc ->
      <<i::size(1), acc::bitstring>>
    end)
  end
  defp trim_trailing_padding_bits(bitstring, _size), do: bitstring

  defp decode_bitstring_symbols(<<>>, acc)
       when rem(bit_size(acc), 8) == 0 do
    {:ok, acc, acc}
  end

  defp decode_bitstring_symbols(<<>>, acc) do
    decoded_size = bit_size(acc)
    padding_size = rem(decoded_size, 8)
    data_size = decoded_size - padding_size
    case acc do
      <<decoded::bitstring-size(data_size), 0::size(padding_size)>> ->
        {:ok, decoded, acc}
      <<decoded::bitstring-size(data_size), rest::size(padding_size)>> ->
        trimmed = trim_trailing_padding_bits(<<rest::size(padding_size)>>, padding_size)
        {:ok, <<decoded::bitstring, trimmed::bitstring>>, acc}
      _ ->
        error_invalid()
    end
  end

  # also generate the alphabet(A-Z) in lowercase when decode with accumulator
  for {alphabet, index} <- Enum.with_index(CrockfordBase32.Symbol.alphabet_set()) do
    defp decode_bitstring_symbols(<<unquote(alphabet), rest::bitstring>>, acc) do
      decode_bitstring_symbols(rest, <<acc::bitstring, unquote(index)::5>>)
    end
    if alphabet in ?A..?Z do
      defp decode_bitstring_symbols(<<unquote(alphabet+32), rest::bitstring>>, acc) do
        decode_bitstring_symbols(rest, <<acc::bitstring, unquote(index)::5>>)
      end
    end
  end
  # I L O
  defp decode_bitstring_symbols(<<"I", rest::bitstring>>, acc), do: decode_bitstring_symbols(rest, <<acc::bitstring, 1::5>>)
  defp decode_bitstring_symbols(<<"L", rest::bitstring>>, acc), do: decode_bitstring_symbols(rest, <<acc::bitstring, 1::5>>)
  defp decode_bitstring_symbols(<<"O", rest::bitstring>>, acc), do: decode_bitstring_symbols(rest, <<acc::bitstring, 0::5>>)
  # i l o
  defp decode_bitstring_symbols(<<"i", rest::bitstring>>, acc), do: decode_bitstring_symbols(rest, <<acc::bitstring, 1::5>>)
  defp decode_bitstring_symbols(<<"l", rest::bitstring>>, acc), do: decode_bitstring_symbols(rest, <<acc::bitstring, 1::5>>)
  defp decode_bitstring_symbols(<<"o", rest::bitstring>>, acc), do: decode_bitstring_symbols(rest, <<acc::bitstring, 0::5>>)
  defp decode_bitstring_symbols(_input, _acc), do: throw :error

end
