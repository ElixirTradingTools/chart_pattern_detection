defmodule OhlcPatternDetection.Reversals do
  alias Decimal, as: D
  alias List, as: L
  alias Enum, as: E
  alias Map, as: M

  defp get_pairs(list),
    do: E.zip(E.drop(list, -1), E.drop(list, 1))

  def normalize_one(val, min, max) when is_integer(val) and is_integer(min) and is_integer(max),
    do: normalize_one(D.new(val), D.new(min), D.new(max))

  def normalize_one(val = %D{}, max = %D{}, min = %D{}),
    do: D.div(D.sub(val, min), D.sub(max, min))

  def normalize(reversals) do
    {max_h, min_l} =
      E.reduce(reversals, {nil, nil}, fn
        {:hi, %{h: h = %D{}}}, {nil, min} -> {h, min}
        {:lo, %{l: l = %D{}}}, {max, nil} -> {max, l}
        {:hi, %{h: h = %D{}}}, {max, min} -> {D.max(max, h), min}
        {:lo, %{l: l = %D{}}}, {max, min} -> {max, D.min(min, l)}
      end)

    {_, %{t: max_t}} = L.first(reversals)
    {_, %{t: min_t}} = L.last(reversals)

    IO.inspect({max_h, min_l, max_t, min_t})

    E.map(reversals, fn {side, %{h: h, l: l, t: t}} ->
      {side,
       %{
         h: normalize_one(h, max_h, min_l),
         l: normalize_one(l, max_h, min_l),
         t: normalize_one(t, max_t, min_t)
       }}
    end)
  end

  def get(bar_list) when is_list(bar_list) do
    get_pairs(bar_list)
    |> E.reduce([], fn {prev, next}, matches ->
      new_lo = D.lt?(M.get(next, :l), M.get(prev, :l))
      new_hi = D.gt?(M.get(next, :h), M.get(prev, :h))

      reversal =
        case {new_lo, new_hi} do
          {true, false} -> :lo
          {false, true} -> :hi
          _ -> nil
        end

      case {L.first(matches), reversal} do
        {_, nil} -> matches
        {nil, :lo} -> [{:lo, next}]
        {nil, :hi} -> [{:hi, next}]
        {{:lo, _}, :lo} -> L.replace_at(matches, 0, {:lo, next})
        {{:lo, _}, :hi} -> [{:hi, next}] ++ matches
        {{:hi, _}, :hi} -> L.replace_at(matches, 0, {:hi, next})
        {{:hi, _}, :lo} -> [{:lo, next}] ++ matches
      end
    end)
  end
end
