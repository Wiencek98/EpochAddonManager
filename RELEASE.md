# Release Checklist

1. Bump version in `EpochAddonManager.toc` (e.g., `## Version: 1.4.1`).
2. Tag commit: `git tag v1.4.1 && git push --tags`.
3. Draft GitHub Release:
   - Title: `v1.4.1`
   - Notes: changes & fixes.
   - Attach a ZIP that contains a single folder: `EpochAddonManager/` with the `.toc` and `.lua`.
4. Verify: download the ZIP, drop into `Interface/AddOns/`, and test on a clean client.
