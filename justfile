#!/usr/bin/env just --justfile

set shell := ["fish", "-c"]

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
