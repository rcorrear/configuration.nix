# Graphify operations

This repository packages Graphify 0.9.46 with local Clojure and Nix extractors. Graph generation is AST-only and does not use LLM credentials.

## Clean build

Run:

```shell
nix run .#graphify-build
```

The command replaces `graphify-out/`, validates `graph.json`, `manifest.json`, `GRAPH_REPORT.md`, Nix code nodes, and a representative query, then writes `build-metadata.json`. To create the immutable CI bundle, pass `--artifact-dir DIR`.

Pull requests build and validate the graph unless labeled `graphify-skip`. Pushes to `main` additionally publish `graphify-<sha>.tar.zst` as the `graphify-<sha>` GitHub Actions artifact for 90 days.

## Synchronization

Run:

```shell
nix run .#graphify-sync
```

Synchronization restores the exact artifact for the checked-out Git commit when available and valid. If no artifact exists, it performs a clean local build for `HEAD`. A dirty working tree is incrementally applied over the exact baseline.

Useful options are `--sha SHA`, `--repo OWNER/REPO`, `--no-download`, and `--watch`. A requested commit other than `HEAD` requires an artifact; the command never labels the current checkout as another commit.

The devenv shell synchronizes stale or dirty graph state automatically. Set `CONFIGURATION_NIX_GRAPHIFY_AUTO_SYNC=0` to disable this. Artifact downloads require an authenticated GitHub CLI session. `GRAPHIFY_GITHUB_REPOSITORY=owner/repo` overrides repository detection, and CI may set `GRAPHIFY_SOURCE_SHA` when creating a bundle.

After ordinary source edits, `graphify update .` remains available for a quick incremental refresh. Use `graphify-sync --watch` for a foreground watcher.
