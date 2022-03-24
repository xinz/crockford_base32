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

  def calculate_base(bits_size, block_size) do
    rem = rem(bits_size, block_size)
    arg_num = div(bits_size, block_size)
    padding_size = if rem != 0, do: block_size - rem, else: 0
    {rem, arg_num, padding_size}
  end

end
