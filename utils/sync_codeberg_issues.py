#!/usr/bin/env python3
"""Mirror new CodeBerg issues into GitHub.

This script treats GitHub as authoritative and mirrors issue reports filed on
CodeBerg so users on either forge can be heard.
"""

from __future__ import annotations

import argparse
import datetime as dt
import json
import os
import re
import sys
import textwrap
import urllib.error
import urllib.parse
import urllib.request
from typing import Dict, Iterable, List, Optional, Tuple


GITHUB_API = "https://api.github.com"
CODEBERG_API = "https://codeberg.org/api/v1"
MIRROR_MARKER_RE = re.compile(r"<!--\s*mirrored-from-codeberg:\s*([^#\s]+/[\w.-]+)#(\d+)\s*-->")


def eprint(msg: str) -> None:
    print(msg, file=sys.stderr)


def env_to_bool(raw: Optional[str], default: bool = False) -> bool:
    if raw is None:
        return default
    normalized = raw.strip().lower()
    if normalized in {"1", "true", "yes", "on"}:
        return True
    if normalized in {"0", "false", "no", "off"}:
        return False
    return default


def env_to_int(raw: Optional[str], default: int, var_name: str) -> int:
    if raw is None:
        return default
    trimmed = raw.strip()
    if not trimmed:
        return default
    try:
        return int(trimmed)
    except ValueError as exc:
        raise ValueError(f"{var_name} must be an integer, got: {raw!r}") from exc


def is_pull_request(issue: dict) -> bool:
    """Return True only when issue payload is actually a PR.

    Some forge APIs include `pull_request: null` on normal issues.
    """
    return issue.get("pull_request") not in (None, False)


def parse_repo(value: str, flag_name: str) -> Tuple[str, str]:
    if "/" not in value:
        raise ValueError(f"{flag_name} must be in owner/repo format")
    owner, repo = value.split("/", 1)
    owner = owner.strip()
    repo = repo.strip()
    if not owner or not repo:
        raise ValueError(f"{flag_name} must be in owner/repo format")
    return owner, repo


def parse_iso_datetime(raw: str) -> dt.datetime:
    raw = raw.strip()
    if re.fullmatch(r"\d{4}-\d{2}-\d{2}", raw):
        return dt.datetime.strptime(raw, "%Y-%m-%d").replace(tzinfo=dt.timezone.utc)
    if raw.endswith("Z"):
        raw = raw[:-1] + "+00:00"
    parsed = dt.datetime.fromisoformat(raw)
    if parsed.tzinfo is None:
        parsed = parsed.replace(tzinfo=dt.timezone.utc)
    return parsed.astimezone(dt.timezone.utc)


def api_request(
    method: str,
    url: str,
    headers: Optional[Dict[str, str]] = None,
    payload: Optional[dict] = None,
) -> dict:
    body = None
    final_headers = {"Accept": "application/json"}
    if headers:
        final_headers.update(headers)
    if payload is not None:
        body = json.dumps(payload).encode("utf-8")
        final_headers["Content-Type"] = "application/json"

    req = urllib.request.Request(url=url, method=method, headers=final_headers, data=body)
    try:
        with urllib.request.urlopen(req, timeout=60) as resp:
            text = resp.read().decode("utf-8")
            return json.loads(text) if text else {}
    except urllib.error.HTTPError as exc:
        detail = exc.read().decode("utf-8", errors="replace")
        raise RuntimeError(f"HTTP {exc.code} for {method} {url}: {detail}") from exc
    except urllib.error.URLError as exc:
        raise RuntimeError(f"Network error for {method} {url}: {exc}") from exc


def paged_get(base_url: str, params: dict, headers: Dict[str, str]) -> Iterable[dict]:
    page = 1
    per_page = 100
    while True:
        final_params = dict(params)
        final_params.update({"page": page, "limit": per_page, "per_page": per_page})
        url = f"{base_url}?{urllib.parse.urlencode(final_params)}"
        rows = api_request("GET", url, headers=headers)
        if not isinstance(rows, list):
            raise RuntimeError(f"Expected list response from {url}, got {type(rows).__name__}")
        if not rows:
            break
        for row in rows:
            yield row
        if len(rows) < per_page:
            break
        page += 1


def collect_existing_github_mirrors(
    gh_owner: str, gh_repo: str, gh_headers: Dict[str, str]
) -> Dict[int, int]:
    """Map CodeBerg issue number -> GitHub issue number by marker."""
    mapping: Dict[int, int] = {}
    url = f"{GITHUB_API}/repos/{gh_owner}/{gh_repo}/issues"
    for issue in paged_get(url, {"state": "all", "sort": "created", "direction": "asc"}, gh_headers):
        if is_pull_request(issue):
            continue
        body = issue.get("body") or ""
        match = MIRROR_MARKER_RE.search(body)
        if not match:
            continue
        cb_number = int(match.group(2))
        gh_number = int(issue["number"])
        mapping[cb_number] = gh_number
    return mapping


def normalize_issue_body(body: Optional[str]) -> str:
    return body.strip() if body and body.strip() else "(No description provided on CodeBerg.)"


def build_github_issue_body(
    cb_owner: str,
    cb_repo: str,
    cb_issue: dict,
) -> str:
    issue_number = cb_issue["number"]
    source_url = cb_issue["html_url"]
    original_author = (cb_issue.get("user") or {}).get("login", "unknown")
    created_at = cb_issue.get("created_at", "unknown")
    labels = [lbl.get("name", "") for lbl in cb_issue.get("labels", []) if lbl.get("name")]
    labels_text = ", ".join(labels) if labels else "(none)"
    original_body = normalize_issue_body(cb_issue.get("body"))

    return textwrap.dedent(
        f"""
        Mirrored from CodeBerg so GitHub remains the authoritative tracker for triage/closure.

        - Source issue: {source_url}
        - Original author: @{original_author}
        - Opened on CodeBerg: {created_at}
        - CodeBerg labels: {labels_text}

        ### Original report

        {original_body}

        <!-- mirrored-from-codeberg: {cb_owner}/{cb_repo}#{issue_number} -->
        """
    ).strip()


def create_github_issue(
    gh_owner: str,
    gh_repo: str,
    gh_headers: Dict[str, str],
    title: str,
    body: str,
    labels: List[str],
) -> dict:
    url = f"{GITHUB_API}/repos/{gh_owner}/{gh_repo}/issues"
    payload = {"title": title, "body": body}
    if labels:
        payload["labels"] = labels
    return api_request("POST", url, headers=gh_headers, payload=payload)


def fetch_github_labels(gh_owner: str, gh_repo: str, gh_headers: Dict[str, str]) -> Dict[str, str]:
    """Map lowercase label name -> canonical GitHub label name."""
    label_map: Dict[str, str] = {}
    url = f"{GITHUB_API}/repos/{gh_owner}/{gh_repo}/labels"
    for row in paged_get(url, {"sort": "created", "direction": "asc"}, gh_headers):
        name = row.get("name")
        if isinstance(name, str) and name:
            label_map[name.lower()] = name
    return label_map


def create_github_label(
    gh_owner: str,
    gh_repo: str,
    gh_headers: Dict[str, str],
    name: str,
) -> None:
    url = f"{GITHUB_API}/repos/{gh_owner}/{gh_repo}/labels"
    api_request(
        "POST",
        url,
        headers=gh_headers,
        payload={
            "name": name,
            "color": "ededed",
            "description": "Mirrored from CodeBerg issue labels",
        },
    )


def resolve_github_labels_for_issue(
    cb_issue: dict,
    gh_owner: str,
    gh_repo: str,
    gh_headers: Dict[str, str],
    gh_label_map: Dict[str, str],
    label_prefix: str,
    create_missing_labels: bool,
    dry_run: bool,
) -> List[str]:
    resolved: List[str] = []
    seen: set[str] = set()

    for lbl in cb_issue.get("labels", []):
        raw_name = lbl.get("name") if isinstance(lbl, dict) else None
        if not isinstance(raw_name, str) or not raw_name.strip():
            continue

        candidate = f"{label_prefix}{raw_name.strip()}"
        key = candidate.lower()

        canonical = gh_label_map.get(key)
        if canonical is None and create_missing_labels:
            if dry_run:
                print(f"DRY RUN: would create missing GitHub label '{candidate}'")
                canonical = candidate
            else:
                create_github_label(gh_owner, gh_repo, gh_headers, candidate)
                canonical = candidate
            gh_label_map[key] = canonical

        if canonical is None:
            continue
        if canonical.lower() in seen:
            continue
        resolved.append(canonical)
        seen.add(canonical.lower())

    return resolved


def comment_on_codeberg_issue(
    cb_owner: str,
    cb_repo: str,
    cb_issue_number: int,
    cb_headers: Dict[str, str],
    comment_body: str,
) -> None:
    url = f"{CODEBERG_API}/repos/{cb_owner}/{cb_repo}/issues/{cb_issue_number}/comments"
    api_request("POST", url, headers=cb_headers, payload={"body": comment_body})


def should_import(issue: dict, since: Optional[dt.datetime]) -> bool:
    if is_pull_request(issue):
        return False
    if since is None:
        return True
    created = parse_iso_datetime(issue["created_at"])
    return created >= since


def main() -> int:
    parser = argparse.ArgumentParser(description="Mirror new CodeBerg issues into GitHub.")
    parser.add_argument(
        "--github-repo",
        default=os.environ.get("GITHUB_REPO"),
        help="GitHub target repository in owner/repo format (or GITHUB_REPO env).",
    )
    parser.add_argument(
        "--codeberg-repo",
        default=os.environ.get("CODEBERG_REPO"),
        help="CodeBerg source repository in owner/repo format (or CODEBERG_REPO env).",
    )
    parser.add_argument(
        "--github-token",
        default=os.environ.get("GITHUB_TOKEN"),
        help="GitHub token with issues:write permission (or GITHUB_TOKEN env).",
    )
    parser.add_argument(
        "--codeberg-token",
        default=os.environ.get("CODEBERG_TOKEN"),
        help="CodeBerg token (needed to post backlink comments).",
    )
    parser.add_argument(
        "--since",
        default=os.environ.get("CODEBERG_SYNC_SINCE"),
        help="Only mirror CodeBerg issues created at/after this UTC timestamp (YYYY-MM-DD or ISO-8601).",
    )
    parser.add_argument(
        "--max-import",
        type=int,
        default=env_to_int(os.environ.get("CODEBERG_SYNC_MAX_IMPORT"), 25, "CODEBERG_SYNC_MAX_IMPORT"),
        help="Safety cap on number of issues to mirror in one run.",
    )
    parser.add_argument(
        "--label-prefix",
        default=os.environ.get("CODEBERG_SYNC_LABEL_PREFIX", ""),
        help="Optional prefix to apply to mirrored CodeBerg labels in GitHub.",
    )
    parser.add_argument(
        "--create-missing-labels",
        action="store_true",
        default=env_to_bool(os.environ.get("CODEBERG_SYNC_CREATE_MISSING_LABELS"), default=False),
        help="Create missing GitHub labels for CodeBerg labels before issue creation.",
    )
    parser.add_argument(
        "--allow-backfill",
        action="store_true",
        help="Allow mirroring old pre-existing open issues when --since is not set.",
    )
    parser.add_argument(
        "--no-codeberg-comment",
        action="store_true",
        help="Do not post a backlink comment on the source CodeBerg issue.",
    )
    parser.add_argument("--dry-run", action="store_true", help="Show actions without creating anything.")
    args = parser.parse_args()

    if not args.github_repo or not args.codeberg_repo:
        parser.error("--github-repo and --codeberg-repo are required")
    if not args.github_token and not args.dry_run:
        parser.error("--github-token (or GITHUB_TOKEN) is required unless --dry-run is used")
    if args.max_import < 1:
        parser.error("--max-import must be >= 1")

    gh_owner, gh_repo = parse_repo(args.github_repo, "--github-repo")
    cb_owner, cb_repo = parse_repo(args.codeberg_repo, "--codeberg-repo")
    since = parse_iso_datetime(args.since) if args.since else None

    gh_headers = {
        "Authorization": f"Bearer {args.github_token}" if args.github_token else "",
        "X-GitHub-Api-Version": "2022-11-28",
        "User-Agent": "dancingmad-codeberg-sync",
    }
    if not args.github_token:
        gh_headers.pop("Authorization", None)

    cb_headers = {
        "User-Agent": "dancingmad-codeberg-sync",
    }
    if args.codeberg_token:
        cb_headers["Authorization"] = f"token {args.codeberg_token}"

    eprint("Loading existing GitHub mirrored issue markers...")
    existing = collect_existing_github_mirrors(gh_owner, gh_repo, gh_headers)

    eprint("Loading GitHub labels for mapping...")
    gh_label_map = fetch_github_labels(gh_owner, gh_repo, gh_headers)

    eprint("Fetching open issues from CodeBerg...")
    cb_issue_url = f"{CODEBERG_API}/repos/{cb_owner}/{cb_repo}/issues"
    codeberg_open_issues: List[dict] = list(
        paged_get(cb_issue_url, {"state": "open", "sort": "created", "direction": "asc"}, cb_headers)
    )

    candidates: List[dict] = []
    for issue in codeberg_open_issues:
        if int(issue["number"]) in existing:
            continue
        if not should_import(issue, since):
            continue
        candidates.append(issue)

    if since is None and not args.allow_backfill and len(candidates) > args.max_import:
        eprint(
            "Refusing large unsafeguarded backfill. Set --since, raise --max-import, or pass --allow-backfill."
        )
        eprint(f"Would import {len(candidates)} issues right now.")
        return 2

    to_import = candidates[: args.max_import]
    skipped = len(candidates) - len(to_import)

    print(f"Found {len(candidates)} unmirrored candidate issue(s).")
    if skipped:
        print(f"Applying max-import cap; importing {len(to_import)} and deferring {skipped}.")

    mirrored = 0
    for issue in to_import:
        number = int(issue["number"])
        gh_title = f"[CodeBerg #{number}] {issue.get('title', '(untitled)')}"
        gh_body = build_github_issue_body(cb_owner, cb_repo, issue)
        gh_labels = resolve_github_labels_for_issue(
            cb_issue=issue,
            gh_owner=gh_owner,
            gh_repo=gh_repo,
            gh_headers=gh_headers,
            gh_label_map=gh_label_map,
            label_prefix=args.label_prefix,
            create_missing_labels=args.create_missing_labels,
            dry_run=args.dry_run,
        )

        if args.dry_run:
            if gh_labels:
                print(
                    f"DRY RUN: would create GitHub issue for CodeBerg #{number}: {gh_title} with labels {gh_labels}"
                )
            else:
                print(f"DRY RUN: would create GitHub issue for CodeBerg #{number}: {gh_title}")
            mirrored += 1
            continue

        created = create_github_issue(gh_owner, gh_repo, gh_headers, gh_title, gh_body, gh_labels)
        gh_number = created["number"]
        gh_url = created["html_url"]
        print(f"Mirrored CodeBerg #{number} -> GitHub #{gh_number} ({gh_url})")
        mirrored += 1

        if args.no_codeberg_comment:
            continue
        if not args.codeberg_token:
            print("Skipping CodeBerg backlink comment (no CODEBERG_TOKEN provided).")
            continue

        comment = textwrap.dedent(
            f"""
            Thanks for the report. This has been mirrored to the canonical GitHub tracker:
            {gh_url}

            For triage and closure status, please follow the GitHub issue above.
            """
        ).strip()
        comment_on_codeberg_issue(cb_owner, cb_repo, number, cb_headers, comment)

    print(f"Done. Mirrored {mirrored} issue(s).")
    return 0


if __name__ == "__main__":
    sys.exit(main())