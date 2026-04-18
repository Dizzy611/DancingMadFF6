#!/usr/bin/env python3
"""Mirror GitHub branches/tags/releases to CodeBerg.

GitHub remains authoritative, but this keeps CodeBerg users on current code
and release assets so bug reports are based on up-to-date builds.
"""

from __future__ import annotations

import argparse
import json
import os
import subprocess
import sys
import tempfile
import urllib.error
import urllib.parse
import urllib.request
from typing import Dict, Iterable, List, Optional, Set, Tuple


GITHUB_API = "https://api.github.com"
CODEBERG_API = "https://codeberg.org/api/v1"


def eprint(msg: str) -> None:
    print(msg, file=sys.stderr)


def parse_repo(value: str, flag_name: str) -> Tuple[str, str]:
    if "/" not in value:
        raise ValueError(f"{flag_name} must be owner/repo")
    owner, repo = value.split("/", 1)
    owner = owner.strip()
    repo = repo.strip()
    if not owner or not repo:
        raise ValueError(f"{flag_name} must be owner/repo")
    return owner, repo


def run_cmd(args: List[str], dry_run: bool = False) -> None:
    quoted = " ".join(sh_quote(arg) for arg in args)
    if dry_run:
        print(f"DRY RUN: {quoted}")
        return
    subprocess.run(args, check=True)


def sh_quote(raw: str) -> str:
    if raw == "":
        return "''"
    if all(ch.isalnum() or ch in "@%_+=:,./-" for ch in raw):
        return raw
    return "'" + raw.replace("'", "'\"'\"'") + "'"


def api_request_json(
    method: str,
    url: str,
    headers: Optional[Dict[str, str]] = None,
    payload: Optional[dict] = None,
) -> object:
    body = None
    final_headers = {"Accept": "application/json"}
    if headers:
        final_headers.update(headers)
    if payload is not None:
        body = json.dumps(payload).encode("utf-8")
        final_headers["Content-Type"] = "application/json"
    req = urllib.request.Request(url=url, method=method, headers=final_headers, data=body)
    try:
        with urllib.request.urlopen(req, timeout=120) as resp:
            text = resp.read().decode("utf-8")
            return json.loads(text) if text else {}
    except urllib.error.HTTPError as exc:
        detail = exc.read().decode("utf-8", errors="replace")
        raise RuntimeError(f"HTTP {exc.code} for {method} {url}: {detail}") from exc
    except urllib.error.URLError as exc:
        raise RuntimeError(f"Network error for {method} {url}: {exc}") from exc


def api_download_bytes(url: str, headers: Optional[Dict[str, str]] = None) -> bytes:
    final_headers = {"User-Agent": "dancingmad-codeberg-mirror"}
    if headers:
        final_headers.update(headers)
    req = urllib.request.Request(url=url, method="GET", headers=final_headers)
    try:
        with urllib.request.urlopen(req, timeout=300) as resp:
            return resp.read()
    except urllib.error.HTTPError as exc:
        detail = exc.read().decode("utf-8", errors="replace")
        raise RuntimeError(f"HTTP {exc.code} while downloading {url}: {detail}") from exc
    except urllib.error.URLError as exc:
        raise RuntimeError(f"Network error while downloading {url}: {exc}") from exc


def api_upload_bytes(url: str, data: bytes, headers: Dict[str, str], dry_run: bool) -> None:
    if dry_run:
        print(f"DRY RUN: upload {len(data)} bytes to {url}")
        return
    final_headers = dict(headers)
    final_headers["Content-Type"] = "application/octet-stream"
    req = urllib.request.Request(url=url, method="POST", headers=final_headers, data=data)
    try:
        with urllib.request.urlopen(req, timeout=300):
            return
    except urllib.error.HTTPError as exc:
        detail = exc.read().decode("utf-8", errors="replace")
        raise RuntimeError(f"HTTP {exc.code} while uploading to {url}: {detail}") from exc
    except urllib.error.URLError as exc:
        raise RuntimeError(f"Network error while uploading to {url}: {exc}") from exc


def paged_list(url: str, params: dict, headers: Dict[str, str]) -> Iterable[dict]:
    page = 1
    per_page = 100
    while True:
        final_params = dict(params)
        final_params.update({"page": page, "limit": per_page, "per_page": per_page})
        query = urllib.parse.urlencode(final_params)
        rows = api_request_json("GET", f"{url}?{query}", headers=headers)
        if not isinstance(rows, list):
            raise RuntimeError(f"Expected list response from {url}, got {type(rows).__name__}")
        if not rows:
            break
        for row in rows:
            if isinstance(row, dict):
                yield row
        if len(rows) < per_page:
            break
        page += 1


def mirror_refs(
    cb_owner: str,
    cb_repo: str,
    cb_username: str,
    cb_token: str,
    dry_run: bool,
) -> None:
    encoded_user = urllib.parse.quote(cb_username, safe="")
    encoded_token = urllib.parse.quote(cb_token, safe="")
    push_url = f"https://{encoded_user}:{encoded_token}@codeberg.org/{cb_owner}/{cb_repo}.git"

    eprint("Mirroring branches and tags to CodeBerg...")
    run_cmd(["git", "rev-parse", "--is-inside-work-tree"], dry_run=dry_run)
    run_cmd(["git", "fetch", "--prune", "origin"], dry_run=dry_run)
    run_cmd(["git", "push", "--prune", push_url, "+refs/heads/*:refs/heads/*"], dry_run=dry_run)
    run_cmd(["git", "push", "--prune", push_url, "+refs/tags/*:refs/tags/*"], dry_run=dry_run)


def release_payload_from_github(gh_release: dict) -> dict:
    return {
        "tag_name": gh_release.get("tag_name", ""),
        "target_commitish": gh_release.get("target_commitish") or "master",
        "name": gh_release.get("name") or gh_release.get("tag_name") or "",
        "body": gh_release.get("body") or "",
        "draft": bool(gh_release.get("draft", False)),
        "prerelease": bool(gh_release.get("prerelease", False)),
    }


def sync_releases(
    gh_owner: str,
    gh_repo: str,
    cb_owner: str,
    cb_repo: str,
    gh_headers: Dict[str, str],
    cb_headers: Dict[str, str],
    include_drafts: bool,
    dry_run: bool,
) -> None:
    eprint("Loading GitHub releases...")
    gh_url = f"{GITHUB_API}/repos/{gh_owner}/{gh_repo}/releases"
    gh_releases = list(paged_list(gh_url, {}, gh_headers))

    eprint("Loading CodeBerg releases...")
    cb_url = f"{CODEBERG_API}/repos/{cb_owner}/{cb_repo}/releases"
    cb_releases = list(paged_list(cb_url, {}, cb_headers))

    cb_by_tag: Dict[str, dict] = {}
    for rel in cb_releases:
        tag = rel.get("tag_name")
        if isinstance(tag, str) and tag:
            cb_by_tag[tag] = rel

    mirrored = 0
    assets_uploaded = 0

    for gh_rel in gh_releases:
        if not include_drafts and gh_rel.get("draft", False):
            continue

        tag = gh_rel.get("tag_name")
        if not isinstance(tag, str) or not tag:
            continue

        desired_payload = release_payload_from_github(gh_rel)
        existing = cb_by_tag.get(tag)

        if existing is None:
            if dry_run:
                print(f"DRY RUN: would create CodeBerg release {tag}")
                created = {
                    "id": -1,
                    "tag_name": tag,
                    "assets": [],
                }
            else:
                created = api_request_json("POST", cb_url, headers=cb_headers, payload=desired_payload)
                if not isinstance(created, dict):
                    raise RuntimeError("Unexpected create release response from CodeBerg")
                print(f"Created CodeBerg release {tag}")
            cb_rel = created
        else:
            cb_rel_id = existing.get("id")
            if not isinstance(cb_rel_id, int):
                raise RuntimeError(f"CodeBerg release for {tag} missing numeric id")
            patch_url = f"{cb_url}/{cb_rel_id}"
            if dry_run:
                print(f"DRY RUN: would update CodeBerg release {tag}")
            else:
                api_request_json("PATCH", patch_url, headers=cb_headers, payload=desired_payload)
                print(f"Updated CodeBerg release {tag}")
            cb_rel = existing

        mirrored += 1

        cb_rel_id = cb_rel.get("id")
        if not isinstance(cb_rel_id, int):
            continue

        existing_assets = set()
        for asset in cb_rel.get("assets", []):
            if isinstance(asset, dict):
                name = asset.get("name")
                if isinstance(name, str) and name:
                    existing_assets.add(name)

        for gh_asset in gh_rel.get("assets", []):
            if not isinstance(gh_asset, dict):
                continue
            asset_name = gh_asset.get("name")
            if not isinstance(asset_name, str) or not asset_name:
                continue
            if asset_name in existing_assets:
                continue

            download_url = gh_asset.get("browser_download_url")
            if not isinstance(download_url, str) or not download_url:
                continue

            if dry_run:
                print(f"DRY RUN: would mirror asset {asset_name} for release {tag}")
                assets_uploaded += 1
                continue

            data = api_download_bytes(download_url, headers=gh_headers)
            upload_query = urllib.parse.urlencode({"name": asset_name})
            upload_url = f"{cb_url}/{cb_rel_id}/assets?{upload_query}"
            api_upload_bytes(upload_url, data, headers=cb_headers, dry_run=False)
            print(f"Uploaded asset {asset_name} to CodeBerg release {tag}")
            assets_uploaded += 1

    print(f"Release sync complete. Mirrored {mirrored} release(s), uploaded {assets_uploaded} asset(s).")


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Mirror GitHub refs/releases to CodeBerg while keeping GitHub authoritative."
    )
    parser.add_argument("--github-repo", default=os.environ.get("GITHUB_REPO"), help="owner/repo")
    parser.add_argument("--codeberg-repo", default=os.environ.get("CODEBERG_REPO"), help="owner/repo")
    parser.add_argument(
        "--codeberg-username",
        default=os.environ.get("CODEBERG_USERNAME"),
        help="CodeBerg username used for git HTTPS authentication.",
    )
    parser.add_argument(
        "--codeberg-token",
        default=os.environ.get("CODEBERG_TOKEN"),
        help="CodeBerg token for git push and release API.",
    )
    parser.add_argument(
        "--github-token",
        default=os.environ.get("GITHUB_TOKEN"),
        help="Optional GitHub token (recommended for API rate limits).",
    )
    parser.add_argument("--skip-refs", action="store_true", help="Do not mirror branches/tags.")
    parser.add_argument("--skip-releases", action="store_true", help="Do not mirror releases/assets.")
    parser.add_argument("--include-drafts", action="store_true", help="Also mirror draft releases.")
    parser.add_argument("--dry-run", action="store_true", help="Show actions without mutating CodeBerg.")
    args = parser.parse_args()

    if not args.github_repo or not args.codeberg_repo:
        parser.error("--github-repo and --codeberg-repo are required")

    gh_owner, gh_repo = parse_repo(args.github_repo, "--github-repo")
    cb_owner, cb_repo = parse_repo(args.codeberg_repo, "--codeberg-repo")

    if not args.skip_refs:
        if not args.codeberg_username:
            parser.error("--codeberg-username (or CODEBERG_USERNAME) is required when syncing refs")
        if not args.codeberg_token:
            parser.error("--codeberg-token (or CODEBERG_TOKEN) is required when syncing refs")

    if not args.skip_releases and not args.codeberg_token and not args.dry_run:
        parser.error("--codeberg-token (or CODEBERG_TOKEN) is required when syncing releases")

    gh_headers = {
        "User-Agent": "dancingmad-codeberg-mirror",
        "Accept": "application/vnd.github+json",
    }
    if args.github_token:
        gh_headers["Authorization"] = f"Bearer {args.github_token}"
        gh_headers["X-GitHub-Api-Version"] = "2022-11-28"

    cb_headers = {
        "User-Agent": "dancingmad-codeberg-mirror",
        "Accept": "application/json",
    }
    if args.codeberg_token:
        cb_headers["Authorization"] = f"token {args.codeberg_token}"

    if args.skip_refs and args.skip_releases:
        print("Nothing to do: both refs and releases are skipped.")
        return 0

    if not args.skip_refs:
        mirror_refs(
            cb_owner=cb_owner,
            cb_repo=cb_repo,
            cb_username=args.codeberg_username or "",
            cb_token=args.codeberg_token or "",
            dry_run=args.dry_run,
        )

    if not args.skip_releases:
        sync_releases(
            gh_owner=gh_owner,
            gh_repo=gh_repo,
            cb_owner=cb_owner,
            cb_repo=cb_repo,
            gh_headers=gh_headers,
            cb_headers=cb_headers,
            include_drafts=args.include_drafts,
            dry_run=args.dry_run,
        )

    print("Done.")
    return 0


if __name__ == "__main__":
    sys.exit(main())