# Rendered performance benchmark

`node_flow_500_benchmark_test.dart` renders a deterministic graph with 500
nodes by default (955 connections). It warms the renderer and records separate pan,
zoom, single-node drag/drop, and node-plus-edge topology churn workloads using
Flutter's engine-provided `FrameTiming` values. The topology workload
alternately creates a visible node with two incident edges and removes that
node with its edges, keeping the fixture near its configured size while exercising widget
mounting, the spatial index, adjacency cleanup, and connection-scene
invalidation. By default, it runs the same fixture and workloads in four
configurations:

- `full`: adaptive LOD disabled, so every visible node uses its full widget.
- `retained-full`: every node keeps full labels, card styling, and port marks,
  but ordinary nodes are retained as recorded pictures instead of widget
  subtrees. Active nodes are promoted back into the widget overlay.
- `navigation`: all nodes use full widgets while idle, but camera gestures
  replace ordinary nodes with the painted scene. Selected or actively edited
  nodes remain promoted as a small widget overlay.
- `adaptive`: adaptive LOD enabled with `maxInteractiveNodes: 200`, allowing
  the editor to switch to its batched overview painter.

Run it from `packages/demo` as the production web target:

```sh
flutter drive \
  --release \
  --wasm \
  -d web-server \
  --browser-name chrome \
  --web-port 8080 \
  --driver=test_driver/integration_test.dart \
  --target=integration_test/node_flow_500_benchmark_test.dart
```

Keep the window size, Chrome version, Flutter version, renderer, and power state
fixed when comparing runs. The report records `runtime.wasm`, which must be
`true` for a valid WASM result.

## Local web release testing

For an interactive release build of the demo that stays open in Chrome:

```sh
cd packages/demo
flutter run --release --wasm -d chrome --web-port 8092
```

The explicit port avoids taking over another application already using
`localhost:8080`. Open the URL printed by Flutter (normally
`http://localhost:8092`).

For the exact automated 500-node release fixture, start a ChromeDriver that
matches the installed Chrome major version, then run:

```sh
chromedriver --port=4444

cd packages/demo
flutter drive \
  --release \
  --wasm \
  -d web-server \
  --browser-name chrome \
  --web-port 8080 \
  --driver=test_driver/integration_test.dart \
  --target=integration_test/node_flow_500_benchmark_test.dart \
  --dart-define=NODE_FLOW_BENCHMARK_RENDER_MODE=all
```

Use `comparison` to run only the full-widget and retained-full representations,
or name one representation directly.
The automated driver opens a visible Chrome window, performs the workloads,
writes `build/node_flow_<count>_benchmark.json`, and closes the window when done.

The driver writes the structured result to
`build/node_flow_<count>_benchmark.json`. The same report is also printed with a
`NODE_FLOW_BENCHMARK` prefix. Each workload reports p50, p95, p99, and
maximum UI, raster, and total frame spans, plus the number of frames exceeding
the 16.67 ms budget for a 60 Hz display. Warmup is captured as a separate
measurement phase, while pan, zoom, drag, and topology churn are marked as
`steady_state`.
Each phase reports requested versus engine-delivered frames, missing or extra
timing records, delivery ratio, workload update counters, and frame-budget miss
ratio. `frame_count` and the historical `frames_over_8_33_ms` metric remain for
compatibility, while `frames_over_16_67_ms` is the current acceptance metric.
Each mode and scenario also records the effective LOD
level, widget/thumbnail path, spatially visible node count, and spatially
visible connection count.

The default run uses 100 warmup frames followed by 100 measured frames per
steady-state scenario. This is enough to make p95 and p99 useful while keeping
the deliberately slow full-widget baseline practical to run. The pan and zoom workloads apply exactly one lightweight
live-camera update before each requested frame; their
`workload.viewport_updates` counter should therefore match
`workload.pumped_frames`. The MobX/plugin viewport commits after each measured
phase. The topology workload reports its add/remove API calls in
`workload.graph_updates` and restores the original configured fixture
after measurement.

To compare the two full-detail renderers, set
`NODE_FLOW_BENCHMARK_RENDER_MODE=comparison`. To iterate on one configuration,
use `full`, `retained-full`, `navigation`, or `adaptive` (`all` is the default):

```sh
flutter drive \
  --release \
  --wasm \
  -d web-server \
  --browser-name chrome \
  --web-port 8080 \
  --driver=test_driver/integration_test.dart \
  --target=integration_test/node_flow_500_benchmark_test.dart \
  --dart-define=NODE_FLOW_BENCHMARK_RENDER_MODE=adaptive
```

Scale the same fixture to larger graphs without editing the benchmark:

```sh
flutter drive \
  --release \
  --wasm \
  -d web-server \
  --browser-name chrome \
  --web-port 8080 \
  --driver=test_driver/integration_test.dart \
  --target=integration_test/node_flow_500_benchmark_test.dart \
  --dart-define=NODE_FLOW_BENCHMARK_NODE_COUNT=2000 \
  --dart-define=NODE_FLOW_BENCHMARK_RENDER_MODE=retained-full
```

The report is written to `build/node_flow_<count>_benchmark.json` and grouped
under `node_flow_<count>`, so 500-, 1,000-, and 2,000-node runs can coexist.

For a short diagnostic run while editing the harness, reduce the frame counts:

```sh
flutter drive \
  --release \
  --wasm \
  -d web-server \
  --browser-name chrome \
  --web-port 8080 \
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
    "target_ms": 16.667,
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
- The acceptance target is 60 FPS, which gives the complete frame 16.67 ms.
  Keep the test display and browser refresh rate fixed for comparisons.
- The workloads call controller operations directly and therefore measure graph
  mutation, Flutter build/layout/paint, and raster work without pointer-event
  latency or hit-testing overhead. Input latency should be profiled separately.
- The graph is intentionally zoomed so most or all configured full node widgets are
  visible. A smaller window can change the visible population and must be kept
  constant between comparisons.
- Web engines can report raster timings differently or return zero for fields
  that are not available. Compare like-for-like targets rather than desktop and
  web numbers directly.
- Frame timings are delivered in batches. The harness waits after each workload
  to collect the final batch, which makes the wall-clock runtime longer than the
  animated workload itself.
