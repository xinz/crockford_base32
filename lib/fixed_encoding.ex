defmodule CrockfordBase32.FixedEncoding do
  @moduledoc false

  alias CrockfordBase32.FixedEncoding.{Bitstring, Integer}

  @block_size 5

  defmacro generate(bits_size, :bitstring) when bits_size != nil do
    quote do
      require Bitstring
      Bitstring.generate(unquote(bits_size), unquote(@block_size))
    end
  end

  defmacro generate(bits_size, :integer) when bits_size != nil do
    quote do
      require Integer
      Integer.generate(unquote(bits_size), unquote(@block_size))
    end
  end

end
