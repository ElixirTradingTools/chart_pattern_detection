defmodule ChartPatternDetection do
  alias Decimal, as: D
  alias List, as: L
  alias Enum, as: E
  alias Map, as: M

  defp get_pairs(list),
    do: E.zip(E.drop(list, -1), E.drop(list, 1))

  defp normalize_one(val, min, max) when is_integer(val) and is_integer(min) and is_integer(max),
    do: normalize_one(D.new(val), D.new(min), D.new(max))

  defp normalize_one(val = %D{}, max = %D{}, min = %D{}),
    do: D.div(D.sub(val, min), D.sub(max, min))

  def reversals(bar_list) when is_list(bar_list) do
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
        {{:lo, _}, :hi} -> [{:hi, next} | matches]
        {{:hi, _}, :hi} -> L.replace_at(matches, 0, {:hi, next})
        {{:hi, _}, :lo} -> [{:lo, next} | matches]
      end
    end)
  end

  def normalize(reversals) do
    {max_h, min_l} =
      E.reduce(reversals, {"NaN", "NaN"}, fn
        {:hi, %{h: h = %D{}}}, {max_h, min_l} -> {D.max(max_h, h), min_l}
        {:lo, %{l: l = %D{}}}, {max_h, min_l} -> {max_h, D.min(min_l, l)}
      end)

    {_, %{t: max_t}} = L.first(reversals)
    {_, %{t: min_t}} = L.last(reversals)

    E.map(reversals, fn {side, %{h: h, l: l, t: t}} ->
      {side,
       %{
         h: normalize_one(h, max_h, min_l),
         l: normalize_one(l, max_h, min_l),
         t: normalize_one(t, max_t, min_t)
       }}
    end)
  end

  def get_subsets(results_list, min_l) when is_integer(min_l) and is_list(results_list) do
    len = length(results_list)

    if min_l < len and min_l > 1 do
      {:ok, E.map(len..min_l, fn num -> E.take(results_list, num) end)}
    else
      {:error, "cannot scan between minimum #{min_l} and set of #{len} items"}
    end
  end

  def detect(data_set, rules_list) when is_list(rules_list) and is_list(data_set) do
    E.map(rules_list, fn rule_fn when is_function(rule_fn) -> rule_fn.(data_set) end)
    |> E.all?(fn test_result -> test_result == true end)
  end
end
