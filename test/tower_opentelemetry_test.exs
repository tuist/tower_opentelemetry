defmodule TowerOpentelemetryTest do
  use ExUnit.Case, async: false

  require OpenTelemetry.Tracer

  defp build_event do
    {reason, stacktrace} =
      try do
        raise RuntimeError, "boom"
      rescue
        e -> {e, __STACKTRACE__}
      end

    %Tower.Event{
      id: "01HZTESTID",
      kind: :error,
      level: :error,
      reason: reason,
      stacktrace: stacktrace,
      datetime: DateTime.utc_now(),
      similarity_id: 0
    }
  end

  test "implements the Tower.Reporter behaviour" do
    behaviours =
      :attributes
      |> TowerOpentelemetry.__info__()
      |> Keyword.get_values(:behaviour)
      |> List.flatten()

    assert Tower.Reporter in behaviours
  end

  test "report_event/1 returns :ok when no span is active" do
    assert :ok == TowerOpentelemetry.report_event(build_event())
  end

  test "report_event/1 returns :ok inside an active span" do
    OpenTelemetry.Tracer.with_span "test.span" do
      assert :ok == TowerOpentelemetry.report_event(build_event())
    end
  end

  test "report_event/1 handles non-exception kinds without crashing" do
    event = %Tower.Event{
      id: "x",
      kind: :exit,
      level: :error,
      reason: :killed,
      stacktrace: nil,
      datetime: DateTime.utc_now(),
      similarity_id: 0
    }

    assert :ok == TowerOpentelemetry.report_event(event)
  end
end
