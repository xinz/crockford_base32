defmodule CrockfordBase32.FixedEncoding.Integer do
  @moduledoc false

  @arg "arg"

  defmacro generate(bits_size, block_size) when bits_size != nil do
    rem = rem(bits_size, block_size)
    arg_num = div(bits_size, block_size)
    padding_size = if rem != 0, do: block_size - rem, else: 0

    pattern_match_of_arg = generate_encode_args(arg_num, rem, block_size)
    encode_body_expr = generate_encode_body(arg_num, rem, padding_size)
    pattern_match_of_decode_arg = generate_decode_args(arg_num, rem)
    decode_body_expr = generate_decode_body(arg_num, rem)

    quote do

      def encode(value) when is_integer(value) and value >= 0 do
        encode_bytes_from_integer(<<value::unsigned-unquote(bits_size)>>)
      end

      defp encode_bytes_from_integer(unquote({:<<>>, [], pattern_match_of_arg})) do
        unquote({:<<>>, [], encode_body_expr})
      end
      defp encode_bytes_from_integer(_), do: {:error, "invalid"}

      def decode(value) do
        case decode_bytes_to_integer(value) do
          {:ok, <<decoded::unsigned-size(unquote(bits_size))>>} ->
            {:ok, decoded}
          error ->
            error
        end
      end

      defp decode_bytes_to_integer(unquote({:<<>>, [], pattern_match_of_decode_arg})) do
        {:ok, unquote({:<<>>, [], decode_body_expr})}
      rescue
        _ ->
          {:error, "invalid"}
      end
      defp decode_bytes_to_integer(_), do: {:error, "invalid"}
    end
  end

  defp generate_encode_args(arg_num, rem, block_size) when rem != 0 do
    args = generate_binary_pattern_match_args(arg_num, block_size)
    [{:"::", [], [{:"#{@arg}0", [], nil}, rem]} | args]
  end

  defp generate_encode_args(arg_num, _rem, block_size) do
    generate_binary_pattern_match_args(arg_num, block_size)
  end

  defp generate_binary_pattern_match_args(arg_num, block_size) do
    for i <- 1..arg_num do
      {:"::", [], [{:"#{@arg}#{i}", [], nil}, block_size]}
    end
  end

  defp generate_encode_body(arg_num, rem, padding_size) when rem != 0 do
    args = Macro.generate_arguments(arg_num, nil)
    args = [
      {:<<>>, [],
       [
         {:"::", [], [Macro.var(:"#{@arg}0", nil), rem]},
         {:"::", [], [0, {:size, [], [padding_size]}]}
       ]} | args
    ]
    encode_body_expr(args)
  end

  defp generate_encode_body(arg_num, _rem, _padding) do
    arg_num
    |> Macro.generate_arguments(nil)
    |> encode_body_expr()
  end

  defp encode_body_expr(body) do
    Enum.map(body, fn
      {:<<>>, _, _} = item ->
        quote do
          <<x::5>> = unquote(item)
          CrockfordBase32.e(x)
        end
      item ->
        quote do
          CrockfordBase32.e(unquote(item))
        end
    end)
  end

  defp generate_decode_args(arg_num, rem) when rem != 0 do
    args = generate_binary_pattern_match_args(arg_num, 8)
    [
      {:"::", [], [{:"#{@arg}0", [], nil}, 8]} | args
    ]
  end

  defp generate_decode_args(arg_num, _rem) do
    generate_binary_pattern_match_args(arg_num, 8)
  end

  defp generate_decode_body(arg_num, rem) when rem != 0 do
    args = Macro.generate_arguments(arg_num, nil)
    args = [
      {:ok, Macro.var(:"#{@arg}0", nil)} | args
    ]
    decode_body_expr(args, rem)
  end

  defp generate_decode_body(arg_num, rem) do
    args = Macro.generate_arguments(arg_num, nil)
    decode_body_expr(args, rem)
  end

  defp decode_body_expr(body, rem) do
    Enum.map(body, fn
      {:ok, arg} ->
        quote do
          CrockfordBase32.d(unquote(arg))::unquote(rem)
        end
      arg ->
        quote do
          CrockfordBase32.d(unquote(arg))::5
        end
    end)
  end

end
