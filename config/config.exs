import Config

if Mix.env() == :test do
  config :opentelemetry,
    traces_exporter: :none
end
