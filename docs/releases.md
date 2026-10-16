# PETOPIA releases

The source repository is private. The browser game is published on Cloudflare Pages at https://petopia-dqi.pages.dev/ . Publishing the playable build is separate from approving final art/content.

`VERSION` and `application/config/version` identify the same semantic version. Each release has an immutable `vX.Y.Z` Git tag, GitHub release notes, downloadable browser ZIP and SHA256SUMS. The deployed `/release.json` records version, exact source commit, engine and game-pack checksum. Cloudflare gives each deployment an immutable preview URL while the main URL stays stable.

## Prepare

```bash
python3 tools/release.py prepare 0.1.1
```

This updates the version, runs all current suites and exports the browser build. Review the generated game at `python3 tools/serve_web.py`, update the release notes and verification/progress sources, rebuild progress, then commit the reviewed sources to `main`.

## Publish

```bash
python3 tools/release.py publish
```

Publishing requires a clean `main` commit and release notes. It runs all suites again, builds the actual Godot game, creates/pushes the version tag, deploys the static assets to Cloudflare and creates a GitHub prerelease with its ZIP and checksums. It refuses to move an existing tag to another commit. It uses the current user's `gh` and pinned Wrangler OAuth login; credentials are never stored in the repository. A deployment receipt is saved under `builds/releases/vX.Y.Z/deployment.json`.

Rollback uses a previously published web ZIP from its GitHub release, redeployed through the same Cloudflare project. Keep the original tag and release immutable; record the rollback deployment separately rather than moving a version tag.

The browser uses single-threaded Godot4.7.2 for Safari/Chrome compatibility. The routine save path retains one scheduled idle writer and the latest snapshot; native builds keep the existing worker thread. Transactions supersede stale callbacks, and failures/rewards/shutdown have separate regression checks. Browser reload persistence is tested separately from native writer tests. Browser data stays on that browser/device and can be removed by clearing site data.

The build preserves source image quality: its lossless PCK is divided into12MiB parts solely to meet Cloudflare's per-file limit, reassembled and SHA-256 checked before the stock Godot engine starts. WASM is gzip encoded and served with the matching headers. Source documentation, experiments, test profiles and secrets are excluded from the public game package.
