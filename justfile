#!/usr/bin/env just --justfile

set shell := ["fish", "-c"]

# Generate app icons and splash screen for demo
icons:
    cd packages/demo && \
    dart run flutter_launcher_icons && \
    dart run flutter_native_splash:create

# Build the Flutter web example
build:
    cd packages/demo && \
    flutter build web --release --wasm --no-wasm-dry-run

# Deploy to Cloudflare Pages using Wrangler
deploy: build
    wrangler pages deploy packages/demo/build/web --project-name=vyuh-node-flow

preview:
    cd packages/demo/build/web && \
    serve . -s
