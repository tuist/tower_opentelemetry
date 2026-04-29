defmodule TowerOpentelemetry do
  @moduledoc """
  A [Tower](https://github.com/mimiquate/tower) reporter that records captured
  exceptions as OpenTelemetry span events, following the
  [OTEL semantic conventions for exceptions](https://opentelemetry.io/docs/specs/semconv/exceptions/).

  ## Usage

  Add `:tower` and `:tower_opentelemetry` to your dependencies, then configure
  the reporter:

      # config/config.exs
      config :tower, reporters: [TowerOpentelemetry]

  When Tower captures an unhandled exception, exit, throw or `Logger` error,
  this reporter records it as an `exception` event on the currently active
  span and marks the span status as `:error`. If no span is active (for
  example, a crash in a background process), a short-lived span named
  `"tower.event"` is started so the event still reaches the OTEL pipeline.

  ## Recorded attributes

  Per the semantic conventions, the following attributes are attached to the
  span event:

    * `exception.type` — the fully-qualified exception module name, or
      `Exit`/`Throw`/`Message` for non-exception kinds.
    * `exception.message` — `Exception.message/1` for exceptions, otherwise
      `inspect/1` of the reason.
    * `exception.stacktrace` — `Exception.format_stacktrace/1`, when a
      stacktrace is available. Omitted otherwise, per the spec.
    * `exception.escaped` — always `true`, since Tower only reports
      exceptions that escaped their original scope.

  In addition, `event.id`, `event.kind` and `event.level` are attached for
  correlation with Tower's normalized event stream.

  ## Coexisting with other reporters

  This reporter is fully compatible with other Tower reporters. For example,
  to ship exceptions to both Sentry and an OTEL backend at the same time:

      config :tower, reporters: [Tower.Sentry, TowerOpentelemetry]
  """

  @behaviour Tower.Reporter

  alias OpenTelemetry.Span
  alias OpenTelemetry.Tracer
  alias TowerOpentelemetry.Attributes

  require OpenTelemetry.Tracer

  @impl true
  def report_event(%Tower.Event{} = event) do
    case Tracer.current_span_ctx() do
      :undefined -> record_in_new_span(event)
      span_ctx -> record(span_ctx, event)
    end

    :ok
  end

  defp record_in_new_span(event) do
    OpenTelemetry.Tracer.with_span "tower.event" do
      record(Tracer.current_span_ctx(), event)
    end
  end

  defp record(span_ctx, %Tower.Event{} = event) do
    attributes = Attributes.exception_attributes(event) ++ Attributes.tower_attributes(event)
    Span.add_event(span_ctx, :exception, attributes)
    Span.set_status(span_ctx, OpenTelemetry.status(:error, Attributes.status_message(event)))
  end
end
