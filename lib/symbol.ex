defmodule CrockfordBase32.Symbol do
  @moduledoc false

  defmacro generate() do
    alphabet = alphabet_set()
    
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

    # also generate the alphabet(A-Z) in lowercase when decode
    d_ast1 =
      for {alphabet, index} <- Enum.with_index(alphabet) do
        quote do
          defp d(unquote(alphabet)), do: unquote(index)
          if unquote(alphabet) in ?A..?Z do
            defp d(unquote(alphabet+32)), do: unquote(index)
          end
        end
      end
    d_ast2=
      quote do
        defp d(73), do: 1
        defp d(76), do: 1
        defp d(79), do: 0
        defp d(105), do: 1
        defp d(108), do: 1
        defp d(111), do: 0
        defp d(_), do: throw :error
      end

    [e_ast1, e_ast2, d_ast1, d_ast2]
  end
  
  defmacro __using__(_) do
    quote do
      @compile {:inline, e: 1}
      @compile {:inline, d: 1}
      require CrockfordBase32.Symbol
      CrockfordBase32.Symbol.generate()
    end
  end


  def alphabet_set() do
    # encoding symbol charlist: '0123456789ABCDEFGHJKMNPQRSTVWXYZ'
    # check symbol charlist: '*~$=U'
    '0123456789ABCDEFGHJKMNPQRSTVWXYZ*~$=U'
  end

end
