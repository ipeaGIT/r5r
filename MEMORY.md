# Project Memory — r5r

Corrections and learned facts that persist across sessions. When a mistake is corrected, or a non-obvious approach is confirmed, append a `[LEARN:category]` entry below (most recent at bottom). Keep this file under 200 lines; it is committed and read by collaborators.

Personal working preferences (not project facts) live in Claude Code's per-user auto-memory, outside this repo.

---

## Repository layout

[LEARN:r5r] Monorepo: the package is in `r-package/`, there is no root `DESCRIPTION`. Every devtools / `R CMD` / `/r-package-check` call must pass the path explicitly (`devtools::test("r-package")`, `/r-package-check r-package`).

[LEARN:r5r] Default branch is `master`, not `main`; PRs are merged with merge commits. The global `/commit` skill's Steps 0/0b (quality_score.py, check-surface-sync.sh) do not apply here.

## Java / R5

[LEARN:r5r] The little JAR `r-package/inst/jar/r5r.jar` is rebuilt by the CI job `build-jar` on every push to a non-protected branch and committed as `Rebuild JAR for commit <sha>`. Never commit a hand-built JAR; after pushing a `java-r5rcore/` change, `git pull` before pushing again.

[LEARN:r5r] Java must be exactly 21 — `start_r5r_java()` in `R/utils.R` aborts on any other major version. `SystemRequirements` says `>= 21.0` but the code is strict.

[LEARN:r5r] The R5 version is pinned in two places that must move together: `R/onLoad.R` (`r5_jar_version`, `r5_jar_size`) and `inst/extdata/metadata_r5r.csv`. The cache dir name `r5r/r5_jar_v<version>` derives from it and stale caches are purged in `.onLoad`.

[LEARN:r5r] `java-r5rcore/build.gradle` shells out to R (`devtools::load_all(); download_r5()`) to find the R5 JAR, so a local Gradle build needs R, devtools and the package deps installed.

## Tests and artifacts

[LEARN:r5r] Tests run only with `NOT_CRAN=true`; `tests/testthat/setup.R` builds the poa and spo networks once for the whole suite. `test-z_r5r_cache.R` is named to run last because it deletes the JAR cache.

[LEARN:r5r] `build_network()` writes `network.dat`, `*.mapdb*`, `gtfs_errors.csv` and `r5r-log.log` into `data_path`. In `inst/extdata/poa|spo` these are build artifacts, not source; `gtfs_errors.csv` was added to `.gitignore` on 2026-09-21.

[LEARN:ci] `remotes::system_requirements("ubuntu", "24.04")` errors (supports only up to 22.04), and inside the `build-jar` `while read ... < <(Rscript ...)` loop that failure is silent: no GDAL/GEOS/PROJ get installed, then Gradle's `download_r5()` call fails with `"sf" is required`. Keep "20.04" (or move to pak/r-lib sysreqs) and never bump this string without checking it runs.

[LEARN:r5r] `r-package/.Rprofile` is tracked but may carry a contributor's machine-local `JAVA_HOME` block (written by rJavaEnv). Never stage it; `git update-index --skip-worktree r-package/.Rprofile` keeps it out of `git status`.

## Claude Code config

[LEARN:claude] A user-level skill (`~/.claude/skills/<name>`) takes precedence over a project skill with the same name, so r5r-specific skill copies never run for anyone who has the user-level twin. Put r5r specifics in `AGENTS.md`, the path-scoped rules, and `.claude/agents/` (project agents DO override user-level agents).

[LEARN:claude] Rule frontmatter must use `paths:`; Cursor-style `globs:` / `alwaysApply:` are ignored, so such a rule loads in every session.

[LEARN:r5r] `start_r5r_java()` called `rJava::.jinit(parameters = c(log_path, ...))`, which REPLACES `.jinit()`'s default `getOption("java.parameters")`, so a user's `-Xmx` was silently ignored from v2.2.0 to v2.4.0 (JVM got its default heap; `.onAttach`/`r5r_sitrep()` still echoed the option). Fixed in dev by prepending `getOption("java.parameters")`. To verify JVM flags, read `RuntimeMXBean$getInputArguments()` / `Runtime$maxMemory()` in a fresh R session; never trust the option value. To benchmark CRAN <= 2.4.0 with a set heap, call `.jinit()` yourself with the flags plus `-DLOG_PATH/-DR5_VER/-DR5R_VER` before `build_network()`.
