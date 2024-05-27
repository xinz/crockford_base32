defmodule CrockfordBase32.Symbol do
  @moduledoc false

  defmacro generate(input_alphabet) do
    alphabet = input_alphabet || alphabet_set()
    
    e_ast1 = 
      for {alphabet, index} <- Enum.with_index(alphabet) do
        quote do
          defp e(unquote(index)), do: unquote(alphabet)
        end
      end
    e_ast2 =
      quote do
        defp e(_), do: throw :error
      end

    d_ast1 =
      if input_alphabet == nil do
        # also generate the alphabet(A-Z) in lowercase when decoding by default
        for {alphabet, index} <- Enum.with_index(alphabet) do
          quote do
            defp d(unquote(alphabet)), do: unquote(index)
            if unquote(alphabet) in ?A..?Z do
              defp d(unquote(alphabet+32)), do: unquote(index)
            end
          end
        end
      else
        # generate by the input alphabet
        for {alphabet, index} <- Enum.with_index(alphabet) do
          quote do
            defp d(unquote(alphabet)), do: unquote(index)
          end
        end
      end

    d_ast2=
      if input_alphabet == nil do
        quote do
          defp d(73), do: 1
          defp d(76), do: 1
          defp d(79), do: 0
          defp d(105), do: 1
          defp d(108), do: 1
          defp d(111), do: 0
          defp d(_), do: throw :error
        end
      else
        quote do
          defp d(_), do: throw :error
        end
      end

    [e_ast1, e_ast2, d_ast1, d_ast2]
  end
  
  defmacro __using__(opts \\ []) do
    opts = Macro.prewalk(opts, &Macro.expand(&1, __CALLER__))
    alphabet = Keyword.get(opts, :alphabet)
    if alphabet != nil and not is_list(alphabet) do
      raise "Requires parameter :alphabet to be as a list."
    end
    quote do
      @compile {:inline, e: 1}
      @compile {:inline, d: 1}
      require CrockfordBase32.Symbol
      CrockfordBase32.Symbol.generate(unquote(alphabet))
    end
  end


  def alphabet_set() do
    # encoding symbol charlist: '0123456789ABCDEFGHJKMNPQRSTVWXYZ'
    # check symbol charlist: '*~$=U'
    '0123456789ABCDEFGHJKMNPQRSTVWXYZ*~$=U'
  end

end
