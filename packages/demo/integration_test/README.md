# Rendered performance benchmark

`node_flow_500_benchmark_test.dart` renders a deterministic graph with 500
nodes and 955 connections. It warms the renderer and records separate pan,
zoom, and single-node drag workloads using Flutter's engine-provided
`FrameTiming` values. By default, it runs the same fixture and workloads in two
configurations:

- `full`: adaptive LOD disabled, so every visible node uses its full widget.
- `adaptive`: adaptive LOD enabled with `maxInteractiveNodes: 200`, allowing
  the editor to switch to its batched overview painter.

Run it from `packages/demo` on the target hardware in profile mode:

```sh
flutter drive \
  --profile \
  -d macos \
  --driver=test_driver/integration_test.dart \
  --target=integration_test/node_flow_500_benchmark_test.dart
```

Replace `macos` with another configured device ID. For the web target, use
`-d chrome`. Keep the window size, device, Flutter version, renderer, and power
state fixed when comparing runs.

The driver writes the structured result to
`build/node_flow_500_benchmark.json`. The same report is also printed with a
`NODE_FLOW_500_BENCHMARK` prefix. Each workload reports p50, p95, p99, and
maximum UI, raster, and total frame spans, plus the number of frames exceeding
the 8.33 ms budget for a 120 Hz display. Each mode and scenario also records
the effective LOD level, widget/thumbnail path, spatially visible node count,
and spatially visible connection count.

To iterate on only one configuration, set `NODE_FLOW_BENCHMARK_RENDER_MODE` to
`full` or `adaptive` (`all` is the default):

```sh
flutter drive \
  --profile \
  -d macos \
  --driver=test_driver/integration_test.dart \
  --target=integration_test/node_flow_500_benchmark_test.dart \
  --dart-define=NODE_FLOW_BENCHMARK_RENDER_MODE=adaptive
```

For a short diagnostic run while editing the harness, reduce the frame counts:

```sh
flutter drive \
  --profile \
  -d macos \
  --driver=test_driver/integration_test.dart \
  --target=integration_test/node_flow_500_benchmark_test.dart \
  --dart-define=NODE_FLOW_BENCHMARK_WARMUP_FRAMES=10 \
  --dart-define=NODE_FLOW_BENCHMARK_SCENARIO_FRAMES=30
```

## Interpretation and limitations

- This is a measurement harness, not a normal correctness test, so it has no
  hard timing assertions. Shared CI and debug-mode results are not stable FPS
  gates.
- A 120 Hz target has an 8.33 ms total frame budget. Use a physical 120 Hz
  display when validating that target; lower-refresh displays cannot prove it.
- The workloads call controller operations directly and therefore measure graph
  mutation, Flutter build/layout/paint, and raster work without pointer-event
  latency or hit-testing overhead. Input latency should be profiled separately.
- The graph is intentionally zoomed so most or all 500 full node widgets are
  visible. A smaller window can change the visible population and must be kept
  constant between comparisons.
- Web engines can report raster timings differently or return zero for fields
  that are not available. Compare like-for-like targets rather than desktop and
  web numbers directly.
- Frame timings are delivered in batches. The harness waits after each workload
  to collect the final batch, which makes the wall-clock runtime longer than the
  animated workload itself.
