defmodule OhlcPatternDetectionTest do
  use ExUnit.Case
  alias OhlcPatternDetection.Reversals
  alias Decimal, as: D

  @fixture1 [
    %{l: D.new("1.0"), h: D.new("1.1"), t: 1000},
    %{l: D.new("0.5"), h: D.new("1.0"), t: 1060},
    %{l: D.new("0.6"), h: D.new("1.0"), t: 1120},
    %{l: D.new("0.7"), h: D.new("1.5"), t: 1180},
    %{l: D.new("0.6"), h: D.new("1.0"), t: 1240},
    %{l: D.new("0.5"), h: D.new("1.0"), t: 1300},
    %{l: D.new("0.6"), h: D.new("0.9"), t: 1360},
    %{l: D.new("0.7"), h: D.new("1.5"), t: 1420},
    %{l: D.new("0.5"), h: D.new("1.0"), t: 1480},
    %{l: D.new("0.6"), h: D.new("0.9"), t: 1540}
  ]

  @expected1 [
    {:lo, %{l: D.new("0.5"), h: D.new("1.0"), t: 1480}},
    {:hi, %{l: D.new("0.7"), h: D.new("1.5"), t: 1420}},
    {:lo, %{l: D.new("0.5"), h: D.new("1.0"), t: 1300}},
    {:hi, %{l: D.new("0.7"), h: D.new("1.5"), t: 1180}},
    {:lo, %{l: D.new("0.5"), h: D.new("1.0"), t: 1060}}
  ]

  @expected2 [
    {:lo, %{h: D.new("0.5"), l: D.new("0"), t: D.new("1")}},
    {:hi, %{h: D.new("1"), l: D.new("0.2"), t: D.new("0.86")}},
    {:lo, %{h: D.new("0.5"), l: D.new("0"), t: D.new("0.57")}},
    {:hi, %{h: D.new("1"), l: D.new("0.2"), t: D.new("0.28")}},
    {:lo, %{h: D.new("0.5"), l: D.new("0"), t: D.new("0.0")}}
  ]

  describe "OhlcPatternDetection" do
    test "get_reversals/1" do
      D.Context.with(%D.Context{precision: 2, rounding: :half_even}, fn ->
        result = Reversals.get(@fixture1)
        assert result == @expected1
        assert Reversals.normalize(result) == @expected2
      end)
    end
  end
end
