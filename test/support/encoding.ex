defmodule CrockfordBase32.Encoding do
  defmodule Fixed8 do
    use CrockfordBase32,
      bits_size: 8
  end

  defmodule Fixed128 do
    use CrockfordBase32,
      bits_size: 128
  end

  defmodule Fixed25 do
    use CrockfordBase32,
      bits_size: 25
  end

  defmodule Fixed48Integer do
    use CrockfordBase32,
      bits_size: 48,
      type: :integer
  end

  defmodule Fixed15Integer do
    use CrockfordBase32,
      bits_size: 15,
      type: :integer
  end

  defmodule Fixed128Integer do
    use CrockfordBase32,
      bits_size: 128,
      type: :integer
  end
end
