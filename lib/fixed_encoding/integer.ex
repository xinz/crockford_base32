defmodule CrockfordBase32.FixedEncoding.Integer do
  @moduledoc false

  import CrockfordBase32.FixedEncoding, only: [calculate_base: 2]
  import CrockfordBase32, only: [error_invalid: 0, e: 1, d: 1]

  @arg "arg"

  defmacro generate(bits_size, block_size) when bits_size != nil do
    {rem, arg_num, padding_size} = calculate_base(bits_size, block_size)

    pattern_match_of_arg = generate_encode_args(arg_num, rem, block_size)
    encode_body_expr = generate_encode_body(arg_num, rem, padding_size, block_size)
    pattern_match_of_decode_arg = generate_decode_args(arg_num, rem)
    decode_body_expr = generate_decode_body(arg_num, rem, block_size)

    quote do

      def encode(value) when is_integer(value) and value >= 0 do
        encode_bytes_from_integer(<<value::unsigned-unquote(bits_size)>>)
      end

      defp encode_bytes_from_integer(unquote({:<<>>, [], pattern_match_of_arg})) do
        unquote({:<<>>, [], encode_body_expr})
      end
      defp encode_bytes_from_integer(_), do: error_invalid()

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
          error_invalid()
      end
      defp decode_bytes_to_integer(_), do: error_invalid()
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

  defp generate_encode_body(arg_num, rem, padding_size, block_size) when rem != 0 do
    args = Macro.generate_arguments(arg_num, nil)
    args = [
      {:<<>>, [],
       [
         {:"::", [], [Macro.var(:"#{@arg}0", nil), rem]},
         {:"::", [], [0, {:size, [], [padding_size]}]}
       ]} | args
    ]
    encode_body_expr(args, block_size)
  end

  defp generate_encode_body(arg_num, _rem, _padding, block_size) do
    args = Macro.generate_arguments(arg_num, nil)
    encode_body_expr(args, block_size)
  end

  defp encode_body_expr(body, block_size) do
    Enum.map(body, fn
      {:<<>>, _, _} = item ->
        quote do
          <<x::unquote(block_size)>> = unquote(item)
          e(x)
        end
      item ->
        quote do
          e(unquote(item))
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

  defp generate_decode_body(arg_num, rem, block_size) when rem != 0 do
    args = Macro.generate_arguments(arg_num, nil)
    args = [
      {:ok, Macro.var(:"#{@arg}0", nil)} | args
    ]
    decode_body_expr(args, rem, block_size)
  end

  defp generate_decode_body(arg_num, rem, block_size) do
    args = Macro.generate_arguments(arg_num, nil)
    decode_body_expr(args, rem, block_size)
  end

  defp decode_body_expr(body, rem, block_size) do
    Enum.map(body, fn
      {:ok, arg} ->
        quote do
          d(unquote(arg))::unquote(rem)
        end
      arg ->
        quote do
          d(unquote(arg))::unquote(block_size)
        end
    end)
  end

end
