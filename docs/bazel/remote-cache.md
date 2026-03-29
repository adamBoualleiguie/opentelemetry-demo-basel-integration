# Bazel remote cache (BZ-800 / M5)

PR CI already uses a **disk** cache on **`~/.cache/bazel`** (**BZ-613**). A **remote** cache speeds clean runners and large teams by sharing action outputs.

## Recommended setup (local / CI)

1. Provision a cache endpoint supported by Bazel (gRPC or HTTP), for example **Google RBE-compatible** cache, **BuildBuddy**, **EngFlow**, or a self-hosted **bazel-remote**.  
2. **Do not commit** credentials. Use a **user-local** rc file ignored by git.

Create **`.bazelrc.user`** in the repo root (gitignored — add the filename to your **global** `~/.gitignore` if the repo does not ignore it yet):

```text
# Example only — replace with your org’s endpoint and flags.
build --remote_cache=grpcs://remote.buildbuddy.io
build --remote_header=x-buildbuddy-api-key=YOUR_KEY
```

Or pass once:

```bash
bazelisk build //src/checkout:checkout_image \
  --remote_cache=https://cache.example.com \
  --remote_cache_header="Authorization=Bearer $TOKEN"
```

## CI secrets (maintainers)

To enable remote cache in **GitHub Actions**, inject the same flags via a repository **secret** (for example **`BAZEL_REMOTE_CACHE_URL`**) and append to **`BAZEL_EXTRA_OPTS`** in a workflow step, or add a small **`echo 'build --remote_cache=...' >> .bazelrc.ci`** step from secrets. **Forks** should leave this unset so CI stays green without org credentials.

## References

- [Bazel remote caching](https://bazel.build/remote/caching)  
- Milestone context: **`docs/bazel/milestones/m5-completion.md`** § Epic Q
