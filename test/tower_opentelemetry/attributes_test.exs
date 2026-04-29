defmodule TowerOpentelemetry.AttributesTest do
  use ExUnit.Case, async: true

  alias TowerOpentelemetry.Attributes

  describe "exception_attributes/1 with an :error event holding a real exception" do
    test "maps to OTEL semconv exception attributes" do
      {reason, stacktrace} =
        try do
          raise ArgumentError, "bad argument"
        rescue
          e -> {e, __STACKTRACE__}
        end

      event = %Tower.Event{
        id: "01HZ",
        kind: :error,
        level: :error,
        reason: reason,
        stacktrace: stacktrace,
        datetime: DateTime.utc_now(),
        similarity_id: 0
      }

      attrs = Attributes.exception_attributes(event)

      assert {:"exception.type", "ArgumentError"} in attrs
      assert {:"exception.message", "bad argument"} in attrs
      assert {:"exception.escaped", true} in attrs

      stacktrace_attr = Keyword.get(attrs, :"exception.stacktrace")
      assert is_binary(stacktrace_attr)
      assert stacktrace_attr =~ "attributes_test.exs"
    end

    test "omits exception.stacktrace when no stacktrace is available" do
      event = %Tower.Event{
        id: "01HZ",
        kind: :error,
        level: :error,
        reason: %RuntimeError{message: "boom"},
        stacktrace: nil,
        datetime: DateTime.utc_now(),
        similarity_id: 0
      }

      attrs = Attributes.exception_attributes(event)
      refute Keyword.has_key?(attrs, :"exception.stacktrace")
      assert {:"exception.escaped", true} in attrs
    end
  end

  describe "exception_attributes/1 with non-exception kinds" do
    test "maps :exit reason to type Exit and inspected message" do
      event = %Tower.Event{
        id: "01HZ",
        kind: :exit,
        level: :error,
        reason: :killed,
        stacktrace: nil,
        datetime: DateTime.utc_now(),
        similarity_id: 0
      }

      attrs = Attributes.exception_attributes(event)
      assert Keyword.get(attrs, :"exception.type") == "Exit"
      assert Keyword.get(attrs, :"exception.message") == ":killed"
      refute Keyword.has_key?(attrs, :"exception.stacktrace")
      assert {:"exception.escaped", true} in attrs
    end

    test "maps :throw reason to type Throw" do
      event = %Tower.Event{
        id: "01HZ",
        kind: :throw,
        level: :error,
        reason: %{thrown: true},
        stacktrace: [],
        datetime: DateTime.utc_now(),
        similarity_id: 0
      }

      attrs = Attributes.exception_attributes(event)
      assert Keyword.get(attrs, :"exception.type") == "Throw"
      assert Keyword.get(attrs, :"exception.message") == "%{thrown: true}"
    end

    test "maps :message reason to type Message" do
      event = %Tower.Event{
        id: "01HZ",
        kind: :message,
        level: :warning,
        reason: "something went wrong",
        stacktrace: nil,
        datetime: DateTime.utc_now(),
        similarity_id: 0
      }

      attrs = Attributes.exception_attributes(event)
      assert Keyword.get(attrs, :"exception.type") == "Message"
      assert Keyword.get(attrs, :"exception.message") == "\"something went wrong\""
    end
  end

  describe "tower_attributes/1" do
    test "exposes id, kind and level for correlation" do
      event = %Tower.Event{
        id: "abc",
        kind: :error,
        level: :error,
        reason: %RuntimeError{message: "x"},
        stacktrace: nil,
        datetime: DateTime.utc_now(),
        similarity_id: 0
      }

      attrs = Attributes.tower_attributes(event)
      assert attrs == [{:"event.id", "abc"}, {:"event.kind", "error"}, {:"event.level", "error"}]
    end
  end

  describe "status_message/1" do
    test "uses Exception.message/1 for exceptions" do
      event = %Tower.Event{
        id: "x",
        kind: :error,
        level: :error,
        reason: %ArgumentError{message: "boom"},
        stacktrace: nil,
        datetime: DateTime.utc_now(),
        similarity_id: 0
      }

      assert Attributes.status_message(event) == "boom"
    end

    test "uses inspect/1 for non-exception reasons" do
      event = %Tower.Event{
        id: "x",
        kind: :exit,
        level: :error,
        reason: :killed,
        stacktrace: nil,
        datetime: DateTime.utc_now(),
        similarity_id: 0
      }

      assert Attributes.status_message(event) == ":killed"
    end
  end
end
