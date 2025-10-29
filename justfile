set shell := ["fish", "-c"]

# Build the Flutter web example
build:
    cd example && flutter build web --release --no-wasm-dry-run

# Deploy to Cloudflare Pages using Wrangler
deploy: build
    wrangler pages deploy example/build/web --project-name=vyuh-node-flow

preview:
    cd example/build/web
    serve -s .
