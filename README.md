# tower_opentelemetry

A [Tower](https://github.com/mimiquate/tower) reporter that records captured exceptions as [OpenTelemetry](https://opentelemetry.io) span events, following the [OTEL semantic conventions for exceptions](https://opentelemetry.io/docs/specs/semconv/exceptions/).

Tower is responsible for *capturing* errors from Plug, Phoenix, Bandit/Cowboy, Oban, LiveView and the Erlang `:logger`. This package is one of the *reporters* you can plug in — it forwards every captured event into the active OpenTelemetry trace, so you can ship your application's exceptions to any OTEL-compatible backend (Honeycomb, Datadog, Grafana Tempo, Jaeger, …) without a vendor-specific SDK.

## Installation

```elixir
def deps do
  [
    {:tower, "~> 0.8"},
    {:tower_opentelemetry, "~> 0.1"}
  ]
end
```

## Configuration

```elixir
# config/config.exs
config :tower, reporters: [TowerOpentelemetry]
```

You can combine it with other reporters during a migration:

```elixir
config :tower, reporters: [Tower.Sentry, TowerOpentelemetry]
```

## Recorded attributes

Per the OTEL semantic conventions for exceptions, the following attributes are attached to each `exception` span event:

| Attribute              | Source                                                    |
| ---------------------- | --------------------------------------------------------- |
| `exception.type`       | exception module (or `Exit`/`Throw`/`Message`)            |
| `exception.message`    | `Exception.message/1`, otherwise `inspect/1` of `reason`  |
| `exception.stacktrace` | `Exception.format_stacktrace/1`                           |

The reporter also attaches `event.id`, `event.kind` and `event.level` so you can correlate OTEL spans with Tower's normalized event stream.

## Behaviour when no span is active

Tower can capture errors from contexts where there is no active OTEL span (for example, a crash in a background process). In that case, a short-lived span named `tower.event` is started so the event still reaches the OTEL pipeline.

## Roadmap

The current OTEL semantic conventions recommend recording exceptions as **log records** rather than span events. Once the Erlang OpenTelemetry SDK ships a stable logs API on Hex, this reporter will gain a `mode: :logs` option and follow the spec's [`OTEL_SEMCONV_EXCEPTION_SIGNAL_OPT_IN`](https://opentelemetry.io/docs/specs/semconv/exceptions/exceptions-logs/) migration path.

## License

MIT — see [LICENSE](./LICENSE).
