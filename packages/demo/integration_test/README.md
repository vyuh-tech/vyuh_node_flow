# Rendered performance benchmark

`node_flow_500_benchmark_test.dart` renders a deterministic graph with 500
nodes and 955 connections. It warms the renderer and records separate pan,
zoom, single-node drag/drop, and node-plus-edge topology churn workloads using
Flutter's engine-provided `FrameTiming` values. The topology workload
alternately creates a visible node with two incident edges and removes that
node with its edges, keeping the fixture near 500 nodes while exercising widget
mounting, the spatial index, adjacency cleanup, and connection-scene
invalidation. By default, it runs the same fixture and workloads in three
configurations:

- `full`: adaptive LOD disabled, so every visible node uses its full widget.
- `navigation`: all 500 nodes use full widgets while idle, but camera gestures
  replace ordinary nodes with the painted scene. Selected or actively edited
  nodes remain promoted as a small widget overlay.
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

## Local web release testing

For an interactive release build of the demo that stays open in Chrome:

```sh
cd packages/demo
flutter run --release --wasm -d chrome
```

For the exact automated 500-node release fixture, start a ChromeDriver that
matches the installed Chrome major version, then run:

```sh
chromedriver --port=4444

cd packages/demo
flutter drive \
  --release \
  --wasm \
  -d chrome \
  --driver=test_driver/integration_test.dart \
  --target=integration_test/node_flow_500_benchmark_test.dart \
  --dart-define=NODE_FLOW_BENCHMARK_RENDER_MODE=all
```

Use `navigation` or `adaptive` instead of `all` to run one representation.
The automated driver opens a visible Chrome window, performs the workloads,
writes `build/node_flow_500_benchmark.json`, and closes the window when done.

The driver writes the structured result to
`build/node_flow_500_benchmark.json`. The same report is also printed with a
`NODE_FLOW_500_BENCHMARK` prefix. Each workload reports p50, p95, p99, and
maximum UI, raster, and total frame spans, plus the number of frames exceeding
the 8.33 ms budget for a 120 Hz display. Warmup is captured as a separate
measurement phase, while pan, zoom, drag, and topology churn are marked as
`steady_state`.
Each phase reports requested versus engine-delivered frames, missing or extra
timing records, delivery ratio, workload update counters, and frame-budget miss
ratio. The existing `frame_count` and `frames_over_8_33_ms` fields remain as
compatibility aliases. Each mode and scenario also records the effective LOD
level, widget/thumbnail path, spatially visible node count, and spatially
visible connection count.

The default run uses 100 warmup frames followed by 100 measured frames per
steady-state scenario. This is enough to make p95 and p99 useful while keeping
the deliberately slow full-widget baseline practical to run. The pan and zoom workloads apply exactly one lightweight
live-camera update before each requested frame; their
`workload.viewport_updates` counter should therefore match
`workload.pumped_frames`. The MobX/plugin viewport commits after each measured
phase. The topology workload reports its add/remove API calls in
`workload.graph_updates` and restores the original 500-node/955-edge fixture
after measurement.

To iterate on only one configuration, set `NODE_FLOW_BENCHMARK_RENDER_MODE` to
`full`, `navigation`, or `adaptive` (`all` is the default):

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

The relevant JSON shape for every phase is:

```json
{
  "phase": "steady_state",
  "requested_frames": 100,
  "delivered_frames": 100,
  "undelivered_frames": 0,
  "extra_delivered_frames": 0,
  "workload": {
    "requested_frames": 100,
    "pumped_frames": 100,
    "viewport_updates": 100,
    "graph_updates": 0
  },
  "frame_budget": {
    "target_ms": 8.333,
    "misses": 0,
    "met": 100,
    "miss_ratio": 0.0
  }
}
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
