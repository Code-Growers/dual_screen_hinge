# Deployment

The documentation workflow builds the Jaspr site and uploads a Pages artifact.
The deploy job skips cleanly when the repository has not enabled GitHub Pages,
instead of failing with the Pages API 404 response.

One-time repository setup:

1. Open **Settings → Pages** in the GitHub repository.
2. Set **Source** to **GitHub Actions**.
3. Rerun **Publish documentation**, or push another change under `website/`.

The workflow uses Node 24-compatible first-party actions. `upload-pages-artifact`
is pinned to its current v4 release; its bundled artifact dependency may still
emit a deprecation notice until that upstream composite action publishes a
Node 24-native release.
