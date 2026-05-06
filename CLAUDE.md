# CLAUDE.md

Guidance for Claude Code working **on** the mirai package. mirai is a minimalist async / parallel / distributed evaluation framework for R, built on nanonext + NNG. R >= 3.6, only runtime dependency is nanonext.

## Skill vs. this file

`.claude/skills/mirai/SKILL.md` is LLM-targeted guidance for *writing user code that calls mirai*. The same skill ships to end users via the `r-lib` plugin in [posit-dev/skills](https://github.com/posit-dev/skills). When helping a user *use* mirai, defer to the skill. **This file is for working on the package source.**

## Commands

```r
source("tests/tests.R")               # run the full suite (single-file minitest)
devtools::document()                  # roxygen2 -> man/, NAMESPACE
source("dev/vignettes/precompile.R")  # rebuild pre-compiled vignettes
rmarkdown::render("README.Rmd")       # rebuild README
```

```bash
R CMD build .
R CMD check --no-manual --compact-vignettes=gs+qpdf mirai_*.tar.gz   # matches CI
```

- `NOT_CRAN=true` gates extended tests (daemon connectivity, dispatcher).
- `tests/testthat/tests.R` is a one-line shim (`source("../tests.R")`) so testthat-aware tooling discovers the suite — not a parallel testthat run.

## Vignettes are pre-compiled

Vignettes need live daemon connections, so committed `vignettes/v0X-*.Rmd` are *outputs*, not sources. To change a vignette:

1. Edit `dev/vignettes/_v0X-*.Rmd`.
2. `source("dev/vignettes/precompile.R")` — uses `knitr::knit` to write `vignettes/v0X-*.Rmd`.
3. At install/check time, the declared `VignetteBuilder` is **litedown** (not knitr), which renders the already-knit `.Rmd`.

Never edit `vignettes/v0X-*.Rmd` directly.

## Formatter

Air, configured in `air.toml`: width 100, 2-space indent, `persistent-line-breaks = false`. **`tests/` is excluded** — don't reformat `tests/tests.R`.

## Internal state (package-level envs in `R/mirai-package.R`)

These are dot-prefixed and inscrutable on first read:

- `.` — current compute profile, key `"cp"` (default `"default"`)
- `..` — compute profile configs (URLs, sockets, connection state)
- `.opts` — `mirai_map()` collection options (`.flat`, `.progress`, `.stop`)
- `._` — error message templates, `hash = TRUE` for fast lookup
- `.command`, `.urlscheme`, `cli_enabled` — populated in `.onLoad`

`.onLoad` sets the URL scheme by platform: `abstract://` (Linux abstract Unix sockets), `ipc:///tmp/` (macOS/POSIX Unix sockets), `ipc://` (Windows named pipes). Override via `url` argument to `daemons()`.

## Codebase shape (`R/`, 10 files)

Most filenames are self-explanatory. Non-obvious mappings:

- `parallel.R` — `make_cluster()`, the official alternative communications backend for R's `parallel` package.
- `next.R` — `nextstream()`/`nextget()`, the developer interface for packages extending mirai.
- The dispatcher itself is implemented in C **inside nanonext**; mirai only launches/queries it via `nanonext::.dispatcher_*`. (No NEWS entries needed for nanonext-internal additions.)

## Evaluation model (load-bearing when changing core)

mirai expressions evaluate in a **clean environment**, not the daemon's global env. Objects passed via `.args` populate that local env; objects in `...` are assigned to the daemon's global env (and persist across subsequent calls on that daemon). There is **no closure capture from the host** — every dependency must be passed explicitly.

`dispatcher = TRUE` (default): FIFO scheduling, `stop_mirai()` cancellation, custom serialization. `dispatcher = FALSE`: round-robin, lower overhead, no cancellation/serialization.

## Error classes

- `miraiError` — wraps daemon errors; preserves `$stack.trace` and `$condition.class`.
- `miraiInterrupt` — task cancellation.

Both implement `conditionMessage()` / `conditionCall()`.

## Packaging notes

- roxygen2 with markdown; `NAMESPACE` is generated — never hand-edit.
- Version is `major.minor.patch.dev` (current dev tag `.9000`).
- `CLAUDE.md` and `.claude/` are in `.Rbuildignore` and don't ship to CRAN.
- PR-comment commands (`.github/workflows/pr-commands.yaml`) — commenting `/document` runs `roxygen2::roxygenise()`; `/style` runs `styler::style_pkg()`. Both commit back to the PR branch.
