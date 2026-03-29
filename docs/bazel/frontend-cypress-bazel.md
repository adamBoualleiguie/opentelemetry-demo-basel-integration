# Frontend Cypress and Bazel (BZ-131)

## Current state (M4)

- **`src/frontend`** uses **`aspect_rules_js`** with **`npm_translate_lock`** (**`npm_frontend`**).
- **`lifecycle_hooks_exclude = ["cypress"]`** avoids running Cypress’s postinstall during **`npm`** fetch under Bazel (large binary download; unstable in hermetic sandboxes).
- **E2E** today runs via **Makefile** / npm scripts outside Bazel (see upstream **`src/frontend`** README and **`frontend-tests`** Dockerfile row in **`component-build-images.yml`**).

## Why not wrapped in M4

- Cypress needs a **browser** or **official Cypress image**; **`ubuntu-latest`** runners require extra setup.
- **`bazel test`** sandboxing conflicts with Cypress defaults unless **`tags = ["no-sandbox", "manual"]`** and a dedicated job.

## Planned approach (BZ-131)

1. Add **`js_test`** or **`sh_test`** that runs **`npx cypress run`** (or **`cypress run --headless`**) with **`tags = ["e2e", "manual"]`** initially.  
2. Wire a **separate** GitHub Actions job (nightly or **`workflow_dispatch`**) with **browser** dependencies or **`cypress-io/github-action`**.  
3. Optionally reuse **`src/frontend/Dockerfile.cypress`** as the execution environment instead of raw Bazel.

## Command target (backlog acceptance)

```bash
# Future (not implemented in this M4 slice):
# bazel test //src/frontend:cypress_e2e --config=e2e
```

Track progress in **`docs/bazel/milestones/m4-completion.md`** and **`docs/planification/5-bazel-migration-task-backlog.md`** §17.
