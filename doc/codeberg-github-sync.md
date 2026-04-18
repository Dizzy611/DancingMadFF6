# GitHub / CodeBerg Sync Notes

Quick summary: GitHub is still the main home for this project, but I keep CodeBerg in sync so people there are not accidentally testing/reporting against old stuff.

What gets synced:

* CodeBerg issues -> GitHub issues
* GitHub branches/tags/releases/assets -> CodeBerg

## What Runs What

Issue mirror (CodeBerg -> GitHub):

* Script: `utils/sync_codeberg_issues.py`
* Workflow: `.github/workflows/codeberg-issue-mirror.yml`

Repo/release mirror (GitHub -> CodeBerg):

* Script: `utils/sync_codeberg_repo.py`
* Workflow: `.github/workflows/codeberg-repo-mirror.yml`

## GitHub Actions Setup

Required (do these first):

1. Secret `CODEBERG_TOKEN`
2. Variable `CODEBERG_USERNAME`
3. Variable `GH_REPO` (example: `Dizzy611/DancingMadFF6`)
4. Variable `CODEBERG_REPO` (example: `Dizzy611/DancingMadFF6`)

Recommended:

1. Variable `CODEBERG_SYNC_SINCE`
2. Variable `CODEBERG_SYNC_MAX_IMPORT` (default `25`)
3. Variable `CODEBERG_SYNC_LABEL_PREFIX` (optional)
4. Variable `CODEBERG_SYNC_CREATE_MISSING_LABELS` (`true` or `false`)

Token scope notes:

* Issue mirror needs CodeBerg API access (read issues, write comments if you want backlinks).
* Repo/release mirror needs push access plus release API access (create/update releases and upload assets).

## Issue Mirror Details

What it does:

* Reads open CodeBerg issues.
* Creates matching GitHub issues if they are not already mirrored.
* Uses a hidden marker in issue body so reruns do not duplicate.
* Can post backlink comments on CodeBerg.
* Can map labels from CodeBerg to GitHub.
* Can auto-create missing GitHub labels.

Safety note:

* If CodeBerg has lots of old open issues, set `CODEBERG_SYNC_SINCE` before first live run.

Manual run:

```bash
python3 utils/sync_codeberg_issues.py \
  --github-repo Dizzy611/DancingMadFF6 \
  --codeberg-repo Dizzy611/DancingMadFF6 \
  --github-token "$GITHUB_TOKEN" \
  --codeberg-token "$CODEBERG_TOKEN" \
  --since 2026-04-17
```

Dry run:

```bash
python3 utils/sync_codeberg_issues.py --dry-run \
  --github-repo Dizzy611/DancingMadFF6 \
  --codeberg-repo Dizzy611/DancingMadFF6 \
  --since 2026-04-17
```

Useful flags:

* `--dry-run`
* `--since <timestamp>`
* `--max-import <n>`
* `--label-prefix <prefix>`
* `--create-missing-labels`
* `--allow-backfill`
* `--no-codeberg-comment`

## Repo / Release Mirror Details

What it does:

* Mirrors branch heads.
* Mirrors tags.
* Creates/updates CodeBerg releases by tag.
* Uploads missing release assets.

Behavior notes:

* Ref prune is OFF by default (safer). The mirror will not delete CodeBerg branches/tags unless you explicitly pass `--prune-refs`.
* It mirrors branches from `origin/*` refs so CI checkout state does not accidentally narrow the branch set.
* It does not delete existing CodeBerg release assets.
* It updates existing CodeBerg release metadata to match GitHub.
* Draft GitHub releases are skipped unless you pass `--include-drafts`.

Manual run:

```bash
python3 utils/sync_codeberg_repo.py \
  --github-repo Dizzy611/DancingMadFF6 \
  --codeberg-repo Dizzy611/DancingMadFF6 \
  --codeberg-username "$CODEBERG_USERNAME" \
  --codeberg-token "$CODEBERG_TOKEN" \
  --github-token "$GITHUB_TOKEN"
```

Dry run:

```bash
python3 utils/sync_codeberg_repo.py --dry-run \
  --github-repo Dizzy611/DancingMadFF6 \
  --codeberg-repo Dizzy611/DancingMadFF6 \
  --codeberg-username "$CODEBERG_USERNAME" \
  --codeberg-token "$CODEBERG_TOKEN"
```

Useful flags:

* `--skip-refs`
* `--prune-refs` (dangerous unless intentional)
* `--skip-releases`
* `--include-drafts`
* `--dry-run`

## Final Policy (Short Version)

* GitHub is canonical for code, release publishing, and issue closure.
* CodeBerg stays current via mirror jobs.
* People can report issues on CodeBerg, but triage/closure still happens on GitHub.
