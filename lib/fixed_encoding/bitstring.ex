defmodule CrockfordBase32.FixedEncoding.Bitstring do
  @moduledoc false

  import CrockfordBase32.FixedEncoding, only: [calculate_base: 2]
  import CrockfordBase32, only: [error_invalid: 0]

  @arg "arg"

  defmacro generate(bits_size, block_size) when bits_size != nil do
    {rem, arg_num, padding_size} = calculate_base(bits_size, block_size)

    pattern_match_of_arg = generate_encode_args(arg_num, rem, block_size)
    encode_body_expr = generate_encode_body(arg_num, rem, padding_size, block_size)
    pattern_match_of_decode_arg = generate_decode_args(arg_num, rem)
    decode_body_expr = generate_decode_body(arg_num, rem, block_size)

    quote do
      use CrockfordBase32.Symbol

      def encode(unquote({:<<>>, [], pattern_match_of_arg})) do
        unquote({:<<>>, [], encode_body_expr})
      end
      def encode(_), do: error_invalid()

      def decode(unquote({:<<>>, [], pattern_match_of_decode_arg})) do
        <<data::size(unquote(bits_size)), _::size(unquote(padding_size))>> = unquote({:<<>>, [], decode_body_expr})
        {:ok, <<data::size(unquote(bits_size))>>}
      catch
        _ ->
          error_invalid()
      end
      def decode(_), do: error_invalid()
    end
  end

  defp generate_encode_args(arg_num, rem, block_size) when rem != 0 do
    arg_num
    |> generate_binary_pattern_match_args(block_size)
    |> List.insert_at(
      -1,
      {:"::", [], [{:"#{@arg}#{arg_num + 1}", [], nil}, rem]}
    )
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
    arg_num
    |> Macro.generate_arguments(nil)
    |> List.insert_at(
      -1,
      {:<<>>, [],
       [
         {:"::", [], [Macro.var(:"#{@arg}#{arg_num + 1}", nil), rem]},
         {:"::", [], [0, {:size, [], [padding_size]}]}
       ]}
    )
    |> encode_body_expr(block_size)
  end

  defp generate_encode_body(arg_num, _rem, _padding, block_size) do
    arg_num
    |> Macro.generate_arguments(nil)
    |> encode_body_expr(block_size)
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
    generate_binary_pattern_match_args(arg_num + 1, 8)
  end

  defp generate_decode_args(arg_num, _rem) do
    generate_binary_pattern_match_args(arg_num, 8)
  end

  defp generate_decode_body(arg_num, rem, block_size) when rem != 0 do
    arg_num + 1
    |> Macro.generate_arguments(nil)
    |> decode_body_expr(block_size)
  end

  defp generate_decode_body(arg_num, _rem, block_size) do
    arg_num
    |> Macro.generate_arguments(nil)
    |> decode_body_expr(block_size)
  end

  defp decode_body_expr(body, block_size) do
    Enum.map(body, fn
      item ->
        quote do
          d(unquote(item))::unquote(block_size)
        end
    end)
  end

end
