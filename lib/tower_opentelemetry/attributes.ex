defmodule TowerOpentelemetry.Attributes do
  @moduledoc """
  Pure functions that translate a `Tower.Event` into OpenTelemetry semantic
  convention attributes for exceptions.

  See <https://opentelemetry.io/docs/specs/semconv/exceptions/>.
  """

  @doc """
  Returns the list of `exception.*` attributes for the given event,
  following the OpenTelemetry semantic conventions for exceptions.
  """
  def exception_attributes(%Tower.Event{kind: :error, reason: reason, stacktrace: stacktrace}) do
    [
      {:"exception.type", exception_type(reason)},
      {:"exception.message", exception_message(reason)},
      {:"exception.escaped", true}
    ] ++ stacktrace_attribute(stacktrace)
  end

  def exception_attributes(%Tower.Event{kind: kind, reason: reason, stacktrace: stacktrace}) do
    [
      {:"exception.type", non_error_type(kind)},
      {:"exception.message", inspect(reason)},
      {:"exception.escaped", true}
    ] ++ stacktrace_attribute(stacktrace)
  end

  @doc """
  Tower-specific attributes attached alongside the `exception.*` ones, for
  correlation between Tower events and OTEL spans.
  """
  def tower_attributes(%Tower.Event{} = event) do
    [
      {:"event.id", to_string(event.id)},
      {:"event.kind", to_string(event.kind)},
      {:"event.level", to_string(event.level)}
    ]
  end

  @doc """
  A short human-readable description of the event, suitable for use as the
  span status message.
  """
  def status_message(%Tower.Event{kind: :error, reason: reason}) when is_exception(reason),
    do: Exception.message(reason)

  def status_message(%Tower.Event{reason: reason}), do: inspect(reason)

  defp exception_type(reason) when is_exception(reason), do: reason.__struct__ |> Module.split() |> Enum.join(".")

  defp exception_type(reason), do: inspect(reason)

  defp exception_message(reason) when is_exception(reason), do: Exception.message(reason)
  defp exception_message(reason), do: inspect(reason)

  defp non_error_type(:exit), do: "Exit"
  defp non_error_type(:throw), do: "Throw"
  defp non_error_type(:message), do: "Message"
  defp non_error_type(other), do: other |> Atom.to_string() |> String.capitalize()

  defp stacktrace_attribute(nil), do: []
  defp stacktrace_attribute([]), do: []
  defp stacktrace_attribute(stacktrace), do: [{:"exception.stacktrace", Exception.format_stacktrace(stacktrace)}]
end
