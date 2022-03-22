defmodule CrockfordBase32.FixedEncoding do
  @moduledoc false

  @arg "arg"
  @block_size 5

  defmacro generate(bits_size) when bits_size != nil do
    rem = rem(bits_size, @block_size)
    arg_num = div(bits_size, @block_size)
    padding_size = @block_size - rem

    pattern_match_of_arg = generate_encode_args(arg_num, rem)

    encode_body_expr = generate_encode_body(arg_num, rem, padding_size)

    pattern_match_of_decode_arg = generate_decode_args(arg_num, rem)

    decode_body_expr = generate_decode_body(arg_num, rem)

    quote do
      def encode(unquote({:<<>>, [], pattern_match_of_arg})) do
        unquote({:<<>>, [], encode_body_expr})
      end
      def encode(_), do: {:error, "invalid"}

      def decode(unquote({:<<>>, [], pattern_match_of_decode_arg})) do
        <<data::size(unquote(bits_size)), _::size(unquote(padding_size))>> = unquote({:<<>>, [], decode_body_expr})
        {:ok, <<data::size(unquote(bits_size))>>}
      rescue
        _ ->
          {:error, "invalid"}
      end
      def decode(_), do: {:error, "invalid"}
    end
  end

  defp generate_encode_args(arg_num, rem) when rem != 0 do
    arg_num
    |> generate_binary_pattern_match_args()
    |> List.insert_at(
      -1,
      {:"::", [], [{:"#{@arg}#{arg_num + 1}", [], nil}, rem]}
    )
  end

  defp generate_encode_args(arg_num, _rem) do
    generate_binary_pattern_match_args(arg_num)
  end

  defp generate_binary_pattern_match_args(arg_num, size \\ @block_size) do
    for i <- 1..arg_num do
      {:"::", [], [{:"#{@arg}#{i}", [], nil}, size]}
    end
  end

  defp generate_encode_body(arg_num, rem, padding_size) when rem != 0 do
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
    |> encode_body_expr()
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
    generate_binary_pattern_match_args(arg_num + 1, 8)
  end

  defp generate_decode_args(arg_num, _rem) do
    generate_binary_pattern_match_args(arg_num, 8)
  end

  defp generate_decode_body(arg_num, rem) when rem != 0 do
    arg_num + 1
    |> Macro.generate_arguments(nil)
    |> decode_body_expr()
  end

  defp decode_body_expr(body) do
    Enum.map(body, fn
      {:<<>>, _, _} = item ->
        quote do
          <<x::5>> = unquote(item)
          CrockfordBase32.d(x)::5
        end
      item ->
        quote do
          CrockfordBase32.d(unquote(item))::5
        end
    end)
  end

end
