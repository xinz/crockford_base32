defmodule CrockfordBase32.FixedEncoding do
  @moduledoc false

  @arg "arg"
  @block_size 5

  defmacro generate_encode(bits_size) when bits_size != nil do
    rem = rem(bits_size, @block_size)
    arg_num = div(bits_size, @block_size)
  
    pattern_match_of_arg = generate_encode_args(arg_num, rem)
       
    body_expr = generate_body(arg_num, rem)

    quote do
      def encode(unquote({:<<>>, [], pattern_match_of_arg})) do
        unquote({:<<>>, [], body_expr})
      end
    end
  end

  defp generate_encode_args(arg_num, rem) when rem != 0 do
    arg_num
    |> generate_binary_pattern_match_args()
    |> List.insert_at(
      -1, 
      {:"::", [], [{:"#{@arg}#{arg_num+1}", [], nil}, rem]}
    )
  end
  defp generate_encode_args(arg_num, _rem) do
    generate_binary_pattern_match_args(arg_num)
  end

  defp generate_binary_pattern_match_args(arg_num) do
    for i <- 1..arg_num do
      {:"::", [], [{:"#{@arg}#{i}", [], nil}, @block_size]}
    end
  end

  defp generate_body(arg_num, rem) when rem != 0 do
    arg_num
    |> Macro.generate_arguments(nil)
    |> List.insert_at(
      -1,
      {:<<>>, [], [{:"::", [], [Macro.var(:"#{@arg}#{arg_num+1}", nil), rem]}, {:"::", [], [0, {:size, [], [@block_size - rem]}]}]}
    )
    |> body_expr()
  end
  defp generate_body(arg_num, _rem) do
    arg_num
    |> Macro.generate_arguments(nil)
    |> body_expr()
  end

  defp body_expr(body) do
    Enum.map(body, fn
      {:<<>>, _, _} = item ->
        quote do
          <<x::5>> = unquote(item)
          CrockfordBase32.e(x)
        end
      item->
        quote do: CrockfordBase32.e(unquote(item))
    end)
  end

end
