defmodule CrockfordBase32 do
  @moduledoc """
  The main module implements Douglas Crockford's [Base32](https://www.crockford.com/base32.html) encoding.
  """

  use CrockfordBase32.Symbol

  import Bitwise, only: [band: 2, bsl: 2, bsr: 2]

  @integer_chunk_bits 25
  @integer_binary_threshold 33_554_432
  @checksum_chunk_bits 20

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
  Encode an integer or a bitstring in Crockford's Base32.

  After encoded, the return string only contains these characters set(`"0123456789ABCDEFGHJKMNPQRSTVWXYZ"`, 10 digits and
  22 letters, excluding `"I"`, `"L"`, `"O"` and `"U"`), if set `checksum: true`, there would be with one of these check
  symbols(`"*~$=U"`) or the previous 10 digits and 22 letters as the last character.

  ## Example

      iex> CrockfordBase32.encode(1234567)
      "15NM7"
      iex> CrockfordBase32.encode(1234567, checksum: true)
      "15NM7S"
      iex> CrockfordBase32.encode(1234567, split_size: 3)
      "15N-M7"
      iex> CrockfordBase32.encode(1234567, split_size: 3, checksum: true)
      "15N-M7S"

  ## Options

    * `:checksum`, optional, a boolean, by defaults to `false`, if set it as `true` will calculate a check
      symbol and append it to the return string.
    * `:split_size`, optional, a positive integer, if set it will use it as a step size to split
      the return string with hyphen(s).

  """
  @spec encode(integer() | bitstring(), Keyword.t()) :: String.t()
  def encode(value, opts \\ [])

  def encode(value, opts) when is_integer(value) do
    value
    |> may_checksum(Keyword.get(opts, :checksum, false))
    |> integer_to_encode()
    |> may_split_by_split_size_with_hyphen(Keyword.get(opts, :split_size))
  end

  def encode(value, opts) when is_bitstring(value) do
    value
    |> bytes_to_encode(Keyword.get(opts, :checksum, false))
    |> may_split_by_split_size_with_hyphen(Keyword.get(opts, :split_size))
  end

  @doc """
  Decode the encoded string to an integer, all hyphen(s) are removed and ignore the encoded's case.

  If the encoded string be with a check symbol, require to use `checksum: true` in decoding.

  ## Example

      iex> CrockfordBase32.decode_to_integer("16JD", checksum: true)
      {:ok, 1234}
      iex> CrockfordBase32.decode_to_integer("16j")
      {:ok, 1234}
      iex> CrockfordBase32.decode_to_integer("16j*", checksum: true)
      :error_checksum

  ## Options

    * `:checksum`, optional, a boolean, by defaults to `false` means expect input the encoded string without a check symbol in its tail,
      if set it as `true`, please ensure input encoded is a string be with a check symbol, or return  `:error_checksum`.
  """
  @spec decode_to_integer(String.t(), Keyword.t()) :: {:ok, integer} | :error | :error_checksum
  def decode_to_integer(string, opts \\ [])

  def decode_to_integer(<<>>, _opts) do
    error_invalid()
  end

  def decode_to_integer(string, opts) when is_binary(string) do
    string
    |> remove_hyphen()
    |> may_split_with_checksum(Keyword.get(opts, :checksum, false))
    |> decoding_integer()
  catch
    _error ->
      error_invalid()
  end

  @doc """
  Decode the encoded to a bitstring, all hyphen(s) are removed and ignore the encoded's case.

  If the encoded bitstring be with a check symbol, require to use `checksum: true` in decoding.

  ## Example

      iex> CrockfordBase32.decode_to_bitstring("C5H66")
      {:ok, "abc"}
      iex> CrockfordBase32.decode_to_bitstring("C5H66C", checksum: true)
      {:ok, "abc"}
      iex> CrockfordBase32.decode_to_bitstring("C5H66D", checksum: true)
      :error_checksum

  ## Options

  The same to the options of `decode_to_integer/2`.
  """
  @spec decode_to_bitstring(bitstring(), Keyword.t()) :: {:ok, bitstring()} | :error | :error_checksum
  def decode_to_bitstring(input, opts \\ [])

  def decode_to_bitstring(<<>>, _opts) do
    error_invalid()
  end

  def decode_to_bitstring(input, opts) when is_bitstring(input) do
    input
    |> remove_hyphen()
    |> may_split_with_checksum(Keyword.get(opts, :checksum, false))
    |> decoding_bitstring()
  catch
    _error ->
      error_invalid()
  end

  defp may_split_with_checksum(input, false), do: {input, nil}
  defp may_split_with_checksum(<<>>, true), do: {<<>>, <<>>}

  defp may_split_with_checksum(input, true) when is_binary(input) do
    if Regex.match?(~r/\A[0-9A-Za-z*~$=]*\z/, input) do
      payload_size = byte_size(input) - 1
      <<payload::binary-size(payload_size), checksum::binary-size(1)>> = input
      {payload, checksum}
    else
      String.split_at(input, -1)
    end
  end

  defp may_split_with_checksum(input, true), do: {input, nil}

  defp remove_hyphen(input) when is_binary(input) do
    String.replace(input, "-", "")
  end
  defp remove_hyphen(input), do: input

  defp decoding_integer({str, nil}) do
    {:ok, decode_integer_value(str)}
  end

  defp decoding_integer({str, <<checksum::integer-size(8)>>}) do
    check_value = d(checksum)
    integer = decode_integer_value(str)

    if check_value != rem(integer, 37) do
      invalid_checksum()
    else
      {:ok, integer}
    end
  end

  defp decoding_integer(_), do: error_invalid()

  defp decode_integer_value(<<>>), do: 0

  defp decode_integer_value(str) do
    case trim_leading_zero_integer_symbols(str) do
      {:ok, <<>>} ->
        0

      {:ok, payload} ->
        case decode_canonical_integer(payload) do
          {:ok, integer} -> integer
          nil -> decode_integer_chunks(str, 0)
        end

      nil ->
        decode_integer_chunks(str, 0)
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
    checksum_for_bitstring(bitstring) == input_checksum
  end

  defp verify_checksum(decoded, full_decoded, checksum) do
    # double checksum with two kinds of decoded bitstrings in sequence
    if checksum_valid?(decoded, checksum) || checksum_valid?(full_decoded, checksum) do
      :ok
    else
      invalid_checksum()
    end
  end

  defp decoding_bitstring({bitstring, nil}) do
    case do_decode_bitstring(bitstring, <<>>) do
      {:ok, decoded, _} ->
        {:ok, decoded}
      :error ->
        :error
    end
  end

  defp decoding_bitstring({bitstring, <<checksum::integer-size(8)>>}) do
    with {:ok, decoded, full_decoded} <- do_decode_bitstring(bitstring, <<>>),
         :ok <- verify_checksum(decoded, full_decoded, checksum) do
      {:ok, decoded}
    else
      error when is_atom(error) ->
        error
    end
  end

  defp invalid_checksum(), do: :error_checksum

  defp integer_to_encode({value, checksum}) do
    integer_to_encode(value, checksum)
  end

  defp integer_to_encode(0, []), do: "0"
  defp integer_to_encode(0, ["0"]), do: "00"
  defp integer_to_encode(0, encoded), do: IO.iodata_to_binary(encoded)

  defp integer_to_encode(value, encoded)
       when value > 0 and value < @integer_binary_threshold do
    integer_to_encode(bsr(value, 5), [e(band(value, 31)) | encoded])
  end

  defp integer_to_encode(value, checksum) when value > 0 do
    encoded =
      value
      |> :binary.encode_unsigned()
      |> drop_integer_leading_zero_bits()
      |> left_pad_to_base32_boundary()
      |> encode_bitstring([])
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

  defp bytes_to_encode(bytes, with_checksum) do
    encoded =
      bytes
      |> encode_bitstring([])
      |> Enum.reverse()

    checksum =
      if with_checksum == true do
        [<<checksum_for_bitstring(bytes)::integer>>]
      else
        []
      end

    IO.iodata_to_binary([encoded, checksum])
  end

  defp encode_bitstring(<<>>, encoded), do: encoded

  defp encode_bitstring(<<value::integer-size(5), rest::bitstring>>, encoded) do
    encode_bitstring(rest, [e(value) | encoded])
  end

  defp encode_bitstring(<<value::integer-size(4)>>, encoded), do: [e(bsl(value, 1)) | encoded]
  defp encode_bitstring(<<value::integer-size(3)>>, encoded), do: [e(bsl(value, 2)) | encoded]
  defp encode_bitstring(<<value::integer-size(2)>>, encoded), do: [e(bsl(value, 3)) | encoded]
  defp encode_bitstring(<<value::integer-size(1)>>, encoded), do: [e(bsl(value, 4)) | encoded]

  defp checksum_for_bitstring(bitstring) do
    bitstring
    |> bitstring_remainder(0)
    |> e()
  end

  defp bitstring_remainder(<<>>, remainder), do: remainder

  defp bitstring_remainder(
         <<value::integer-size(@checksum_chunk_bits), rest::bitstring>>,
         remainder
       ) do
    bitstring_remainder(rest, rem(bsl(remainder, @checksum_chunk_bits) + value, 37))
  end

  defp bitstring_remainder(<<value::integer-size(5), rest::bitstring>>, remainder) do
    bitstring_remainder(rest, rem(bsl(remainder, 5) + value, 37))
  end

  defp bitstring_remainder(<<value::integer-size(4)>>, remainder),
    do: rem(bsl(remainder, 4) + value, 37)

  defp bitstring_remainder(<<value::integer-size(3)>>, remainder),
    do: rem(bsl(remainder, 3) + value, 37)

  defp bitstring_remainder(<<value::integer-size(2)>>, remainder),
    do: rem(bsl(remainder, 2) + value, 37)

  defp bitstring_remainder(<<value::integer-size(1)>>, remainder),
    do: rem(bsl(remainder, 1) + value, 37)

  defp may_checksum(input, true) when is_integer(input) do
    {input, [<<calculate_checksum(input)::integer>>]}
  end

  defp may_checksum(input, _) do
    {input, []}
  end

  defp calculate_checksum(int) do
    int |> rem(37) |> e()
  end

  defp may_split_by_split_size_with_hyphen(encoded, split_size)
       when is_integer(split_size) and split_size > 0 do
    split_with_hyphen(encoded, split_size, [])
  end

  defp may_split_by_split_size_with_hyphen(encoded, _), do: encoded

  defp split_with_hyphen(str, size, prepared) when byte_size(str) > size do
    <<chunk::size(size)-binary, rest::binary>> = str
    split_with_hyphen(rest, size, [chunk | prepared])
  end

  defp split_with_hyphen(str, _size, []), do: str

  defp split_with_hyphen(rest, _size, prepared) do
    Enum.reverse([rest | prepared]) |> Enum.join("-")
  end

  @doc false
  def error_invalid(), do: :error

  defp calculate_padding_in_decoding(bitstring, size) when size > 5 do
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
  defp calculate_padding_in_decoding(bitstring, _size), do: bitstring

  @compile {:inline, do_decode_bitstring: 2}
  defp do_decode_bitstring(<<>>, acc) do
    decoded_size = bit_size(acc)
    case rem(decoded_size, 8) do
      0 ->
        {:ok, acc, acc}
      padding_size ->
        data_size = decoded_size - padding_size
        case acc do
          <<decoded::bitstring-size(data_size), 0::size(padding_size)>> ->
            {:ok, decoded, acc}
          <<decoded::bitstring-size(data_size), rest::size(padding_size)>> ->
            trimmed = calculate_padding_in_decoding(<<rest::size(padding_size)>>, padding_size)
            {:ok, <<decoded::bitstring, trimmed::bitstring>>, acc}
          _ ->
            error_invalid()
        end
    end
  end

  # also generate the alphabet(A-Z) in lowercase when decode with accumulator
  @compile {:inline, do_decode_bitstring: 2}
  for {alphabet, index} <- Enum.with_index(CrockfordBase32.Symbol.alphabet_set()) do
    defp do_decode_bitstring(<<unquote(alphabet), rest::bitstring>>, acc) do
      do_decode_bitstring(rest, <<acc::bitstring, unquote(index)::5>>)
    end
    if alphabet in ?A..?Z do
      defp do_decode_bitstring(<<unquote(alphabet+32), rest::bitstring>>, acc) do
        do_decode_bitstring(rest, <<acc::bitstring, unquote(index)::5>>)
      end
    end
  end
  # I L O
  defp do_decode_bitstring(<<"I", rest::bitstring>>, acc), do: do_decode_bitstring(rest, <<acc::bitstring, 1::5>>)
  defp do_decode_bitstring(<<"L", rest::bitstring>>, acc), do: do_decode_bitstring(rest, <<acc::bitstring, 1::5>>)
  defp do_decode_bitstring(<<"O", rest::bitstring>>, acc), do: do_decode_bitstring(rest, <<acc::bitstring, 0::5>>)
  # i l o
  defp do_decode_bitstring(<<"i", rest::bitstring>>, acc), do: do_decode_bitstring(rest, <<acc::bitstring, 1::5>>)
  defp do_decode_bitstring(<<"l", rest::bitstring>>, acc), do: do_decode_bitstring(rest, <<acc::bitstring, 1::5>>)
  defp do_decode_bitstring(<<"o", rest::bitstring>>, acc), do: do_decode_bitstring(rest, <<acc::bitstring, 0::5>>)
  defp do_decode_bitstring(_input, _acc), do: throw :error

end
