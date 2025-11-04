## CI guard and manual external-run guidance

This file documents the recommended guardrails for using an external drive with the development compose files.

1) CI vs Local policy
- CI (GitHub Actions hosted runners): do NOT run `docker-compose.external.yml` on GitHub-hosted runners. Instead, use ephemeral volumes or a dedicated integration environment.
- If you must run external-mounted compose in CI, restrict it to self-hosted runners and protect it with a repository secret `ALLOW_EXTERNAL_COMPOSE=true` and an explicit workflow dispatch input `external_data_path`.

2) How the guard works (what we added)
- `scripts/ci_validate_external.sh` — validates `EXTERNAL_DATA_PATH` exists and is writable. Intended for CI and wrapper checks.
- `scripts/external-stack.sh up` — safe wrapper that runs the validation before calling `docker compose -f docker-compose.yml -f docker-compose.external.yml up -d`.
- `.github/workflows/ci-guard-external.yml` — quick guard that runs the validator early in CI and fails when the secret is missing or invalid.
- `.github/workflows/external-integration-dispatch.yml` — manual workflow to be run on a prepared self-hosted runner; it requires `ALLOW_EXTERNAL_COMPOSE=true` repo secret to proceed.

3) How to run locally (macOS example)

Export the path and bring up the stack using the safe wrapper:

```bash
export EXTERNAL_DATA_PATH="/Volumes/My Passport for Mac/docker/chatbot"
make dev-up
```

To stop:

```bash
make dev-down
```

4) How to run from GitHub Actions on a self-hosted runner

- Set repository secret `ALLOW_EXTERNAL_COMPOSE=true` only for maintainers.
- From the Actions tab, run the `External Integration (manual)` workflow, provide the `external_data_path` input (path visible on the self-hosted runner), and set `run_compose=true` if you want compose to actually run. The workflow will validate the path first.

5) Safety notes
- The validator only checks existence and writability and does not modify data. Any data reset/cleanup operations should require explicit `--force` flags and documented warnings.
