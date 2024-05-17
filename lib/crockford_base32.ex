defmodule CrockfordBase32 do
  @moduledoc """
  The main module implements Douglas Crockford's [Base32](https://www.crockford.com/base32.html) encoding.
  """

  use CrockfordBase32.Symbol

  import Bitwise, only: [bor: 2, bsl: 2]

  defmacro __using__(opts \\ []) do
    alias CrockfordBase32.FixedEncoding
    opts = Macro.prewalk(opts, &Macro.expand(&1, __CALLER__))
    bits_size = Keyword.get(opts, :bits_size)
    type = Keyword.get(opts, :type, :bitstring)

    if bits_size != nil do
      quote do
        require FixedEncoding
        FixedEncoding.generate(unquote(bits_size), unquote(type))
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
    |> may_checksum(Keyword.get(opts, :checksum, false))
    |> bytes_to_encode()
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
  def decode_to_bitstring(string, opts \\ [])

  def decode_to_bitstring(<<>>, _opts) do
    error_invalid()
  end

  def decode_to_bitstring(string, opts) when is_bitstring(string) do
    string
    |> remove_hyphen()
    |> may_split_with_checksum(Keyword.get(opts, :checksum, false))
    |> decoding_string()
  catch
    _error ->
      error_invalid()
  end

  defp may_split_with_checksum(str, false), do: {str, nil}

  defp may_split_with_checksum(str, true) do
    String.split_at(str, -1)
  end

  defp remove_hyphen(str) do
    String.replace(str, "-", "")
  end

  defp decoding_integer({str, nil}) do
    {:ok, decoding_integer(str, 0)}
  end

  defp decoding_integer({str, <<checksum::integer-size(8)>>}) do
    check_value = d(checksum)
    integer = decoding_integer(str, 0)

    if check_value != rem(integer, 37) do
      invalid_checksum()
    else
      {:ok, integer}
    end
  end

  defp decoding_integer(_), do: error_invalid()

  defp decoding_integer(<<>>, acc), do: acc

  defp decoding_integer(<<byte::integer-size(8), rest::binary>>, acc) do
    acc = acc * 32 + d(byte)
    decoding_integer(rest, acc)
  end

  defp decoding_string({str, nil}) do
    decode_string(str, <<>>)
  end

  defp decoding_string({str, <<checksum::integer-size(8)>>}) do
    with {:ok, decoded} = result <- decode_string(str, <<>>),
         checksum_of_decoded <-
           decoded
           |> bytes_to_integer_nopadding(0)
           |> calculate_checksum() do
      if checksum_of_decoded != checksum do
        invalid_checksum()
      else
        result
      end
    else
      error ->
        error
    end
  end

  defp invalid_checksum(), do: :error_checksum

  defp integer_to_encode({value, checksum}) do
    integer_to_encode(value, checksum)
  end

  defp integer_to_encode(0, []), do: "0"
  defp integer_to_encode(0, ["0"]), do: "00"
  defp integer_to_encode(0, encoded), do: to_string(encoded)

  defp integer_to_encode(value, encoded) when value > 0 do
    remainder = rem(value, 32)
    value = div(value, 32)
    integer_to_encode(value, [e(remainder) | encoded])
  end

  defp encode_bytes_maybe_padding(value, expected_size, checksum) do
    do_encode_bytes_maybe_padding(value, expected_size, checksum)
  end

  defp do_encode_bytes_maybe_padding(0, expected_size, []),
    do: String.duplicate("0", expected_size)

  defp do_encode_bytes_maybe_padding(0, 0, acc), do: to_string(acc)

  defp do_encode_bytes_maybe_padding(0, size, acc) when size > 0 do
    encode_bytes_maybe_padding(0, size - 1, [e(0) | acc])
  end

  defp do_encode_bytes_maybe_padding(value, size, acc) do
    remainder = rem(value, 32)
    value = div(value, 32)
    encode_bytes_maybe_padding(value, size - 1, [e(remainder) | acc])
  end

  defp bytes_to_integer_nopadding(<<>>, n), do: n

  defp bytes_to_integer_nopadding(<<bytes::integer-size(1)>>, n) do
    bsl(n, 1) |> bor(bytes)
  end

  defp bytes_to_integer_nopadding(<<bytes::integer-size(2)>>, n) do
    bsl(n, 2) |> bor(bytes)
  end

  defp bytes_to_integer_nopadding(<<bytes::integer-size(3)>>, n) do
    bsl(n, 3) |> bor(bytes)
  end

  defp bytes_to_integer_nopadding(<<bytes::integer-size(4)>>, n) do
    bsl(n, 4) |> bor(bytes)
  end

  defp bytes_to_integer_nopadding(<<bytes::integer-size(5), rest::bitstring>>, n) do
    bytes_to_integer_nopadding(rest, bsl(n, 5) |> bor(bytes))
  end

  defp bytes_to_integer_with_padding(<<>>, n), do: n

  defp bytes_to_integer_with_padding(<<bytes::integer-size(1)>>, n) do
    bsl(n, 5) |> bor(bsl(bytes, 4))
  end

  defp bytes_to_integer_with_padding(<<bytes::integer-size(2)>>, n) do
    bsl(n, 5) |> bor(bsl(bytes, 3))
  end

  defp bytes_to_integer_with_padding(<<bytes::integer-size(3)>>, n) do
    bsl(n, 5) |> bor(bsl(bytes, 2))
  end

  defp bytes_to_integer_with_padding(<<bytes::integer-size(4)>>, n) do
    bsl(n, 5) |> bor(bsl(bytes, 1))
  end

  defp bytes_to_integer_with_padding(<<bytes::integer-size(5), rest::bitstring>>, n) do
    bytes_to_integer_with_padding(rest, bsl(n, 5) |> bor(bytes))
  end

  defp bytes_to_encode({bytes, checksum}) do
    bytes
    |> bytes_to_integer_with_padding(0)
    |> encode_bytes_maybe_padding(encoded_length_of_bytes(bytes), checksum)
  end

  defp encoded_length_of_bytes(bytes) do
    bit_size = bit_size(bytes)
    base = div(bit_size, 5)

    case rem(bit_size, 5) do
      0 -> base
      _ -> base + 1
    end
  end

  defp may_checksum(input, true) when is_integer(input) do
    {input, [<<calculate_checksum(input)::integer>>]}
  end

  defp may_checksum(input, true) when is_bitstring(input) do
    int = bytes_to_integer_nopadding(input, 0)
    {input, [<<calculate_checksum(int)::integer>>]}
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

  defp calculate_padding_in_decoding(bitstring) do
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

  @compile {:inline, decode_string: 2}
  defp decode_string(<<>>, acc) do
    decoded_size = bit_size(acc)

    case rem(decoded_size, 8) do
      0 ->
        {:ok, acc}

      padding_size ->
        data_size = decoded_size - padding_size

        case acc do
          <<decoded::bitstring-size(data_size), 0::size(padding_size)>> ->
            {:ok, decoded}
          <<decoded::bitstring-size(data_size), rest::size(padding_size)>> ->
            trimmed = calculate_padding_in_decoding(<<rest::size(padding_size)>>)
            {:ok, <<decoded::bitstring, trimmed::bitstring>>}
          _ ->
            error_invalid()
        end
    end
  end

  # also generate the alphabet(A-Z) in lowercase when decode with accumulator
  @compile {:inline, decode_string: 2}
  for {alphabet, index} <- Enum.with_index(CrockfordBase32.Symbol.alphabet_set()) do
    defp decode_string(<<unquote(alphabet), rest::bitstring>>, acc) do
      decode_string(rest, <<acc::bitstring, unquote(index)::5>>)
    end
    if alphabet in ?A..?Z do
      defp decode_string(<<unquote(alphabet+32), rest::bitstring>>, acc) do
        decode_string(rest, <<acc::bitstring, unquote(index)::5>>)
      end
    end
  end
  defp decode_string(_input, _acc), do: throw :error

end
