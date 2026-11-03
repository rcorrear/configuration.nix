---
name: land
description: >-
  Land an explicitly requested change in rcorrear/configuration.nix through a
  verified GitHub pull request. Invoke only when the user requests landing or
  merging, including an explicit /land invocation; not for review, preparation,
  passing checks, or installing this skill.
disable-model-invocation: true
metadata:
  delta-action: land
---

# Land configuration.nix changes

An explicit invocation authorizes carrying the requested change through merge.
Proceed without asking for the same merge permission again. Stop for genuine
scope, authentication, signing, verification, review, or safety blockers.

## Scope and preflight

- Work only on the intended `rcorrear/configuration.nix` repository. Inspect the
  current checkout, Git status, remotes, branch, and diff before changing state.
  The expected publication remote is `origin`, currently
  `git@github.com:rcorrear/configuration.nix.git`; verify this rather than
  publishing to the `local` backlink.
- Identify the requested files and commits, including applicable uncommitted
  work. Preserve unrelated changes and never stage the entire checkout blindly.
  If the requested change lives only in another checkout, obtain authorized
  access or have it brought into this checkout. An empty or unrelated diff is
  not permission to invent, recover, or publish a different change.
- Inspect `AGENT.md`/`AGENTS.md`, contribution policies, templates, and workflow
  definitions at execution time. Carry out applicable unmet requirements for
  signing, contributor agreements, authorship, reviews, tests, documentation,
  changelogs, and submission metadata. Do not replace a requirement for
  human-authored text with approval of generated text.
- Use `rtk` for shell commands. When its filter hides necessary evidence or
  does not support a command, use `rtk proxy` to run the underlying tool.
  Source: `AGENTS.md`, RTK instructions.
- Confirm GitHub authentication and repository access without displaying
  credentials. Inspect current default branch, allowed merge methods, branch
  protections, rulesets, required checks, and review requirements. At setup time
  `main` was the default, merge commits were enabled, squash/rebase merges were
  disabled, and the published ruleset was disabled. These are observations,
  not guarantees: obey active settings when executing.
- Preserve configured commit signing, including SSH signing. Never disable it
  to work around an approval prompt. Ask the user to approve signing when
  necessary; do not request private keys or passwords.
- Account for Git and JJ state without disturbing unrelated commits, bookmarks,
  workspaces, or working trees. Do not rewrite published history, force-push,
  overwrite a dirty checkout, or directly push to the destination branch.
  If this is a plain JJ workspace without usable Git metadata, do not bootstrap
  or repoint repositories just to make checks or publication work; report the
  blocker and arrange an authorized Git-capable checkout.

## Prepare the change

1. Fetch the verified publication remote and compare the intended change with
   its current destination branch. Create or reuse a dedicated feature branch,
   not `main`; give it a descriptive name and do not overwrite an existing
   unrelated remote branch.
2. Update the feature branch against the destination without discarding work.
   Resolve conflicts automatically only when the intended result is extremely
   clear. Otherwise report the conflicting files and the decision needed, and
   pause. Never choose one side wholesale merely to finish a merge.
3. Check generated-file conventions. `flake.nix` is generated: when input or
   flake definitions need updating, change their authoritative modules and run
   `rtk nix run .#write-flake`, rather than hand-editing the generated output.
   Source: the generation directive in `flake.nix`; `modules/dendritic.nix`
   imports `inputs.flake-file.flakeModules.dendritic`, which supplies the
   `write-flake` application. Verify that application remains available before
   invoking it.
4. Stage only the agreed files, inspect the staged diff, and prepare descriptive
   commits consistent with the existing conventional-style history. Use
   non-interactive commands such as
   `rtk proxy env GIT_EDITOR=true git commit -m "..."`; never invoke an
   editor-dependent commit or rebase. Set `GIT_EDITOR=true` for any Git operation
   that may open an editor. Keep configured signing enabled.

## Verify locally

- Run the required full check:

  ```sh
  rtk devenv shell check
  ```

  Source: `devenv.nix`, `scripts.check.exec`, runs
  `nix fmt -- --fail-on-change "$@"` followed by `prek run --all-files`.
  The hooks enabled in that file are flake-checker, statix, trufflehog, and
  zizmor. `modules/treefmt.nix` defines the formatter and formatting check;
  `devenv.yaml` defines the development-shell inputs.
- Inspect the complete output, not only the exit status: the check script does
  not explicitly stop before running hooks if formatting fails. Treat any
  formatter failure or changed file as a failed verification. Review changes,
  update the intended commit if appropriate, and rerun until formatting reports
  no changes and all hooks pass.
- Run `rtk git diff --check` and inspect the final status. Add targeted tests or
  builds appropriate to the actual diff only after checking their current
  task/package definitions and supported arguments. Do not run live host
  deployments, privileged provisioning, or unrelated full-system builds as
  incidental landing validation.
- A representative local run is not a replacement for the complete remote
  Linux/macOS matrix. Do not silently omit a local required check because a
  tool, platform, credential, Git metadata, or dependency is unavailable.
  Report the actual limitation and stop unless repository policy provides a
  verified alternative.
- If preparation changes code and Graphify is available, follow the update
  requirement in `AGENTS.md`. Use the currently supported CLI and verify the
  working-tree diff afterward; do not commit ignored generated graph artifacts.
  The authoritative CI graph validation is the Graphify workflow below.

## Publish and open or update the PR

- Push only the dedicated feature branch to the verified publication remote,
  using a normal non-force push. No other remote destination or third-party
  service is authorized merely because it is reachable.
- Reuse an existing PR only if its head, base, and scope match this request.
  Otherwise create a PR with explicit `--repo`, `--base`, `--head`, `--title`,
  and `--body-file` arguments to `rtk proxy gh pr create`. Use a temporary
  body file rather than fragile shell interpolation.
- Describe the change, scope, exact checks performed, limitations, and any
  operational follow-up. Follow current submission templates and policies.
  Obtain human-authored submission text if policy requires it.
- Publication and PR creation are intermediate steps, not successful landing.

## Verify the exact PR revision and merge

1. Record the PR head SHA and current destination SHA. Read the PR's check
   results and workflow runs, not only `gh pr checks --required`: the repository
   may have no enforced branch protection even though its workflows must pass.
2. Require successful completion of both matrix jobs from
   `.github/workflows/test.yml`: `Nix flake check ubuntu-latest` and
   `Nix flake check macos-latest`. That workflow runs `nix flake metadata`,
   writes a CI-only `modules/ci-runtime.nix`, and runs `nix flake check`.
   Evaluate the current workflow definition if names or conditions change.
3. Require the applicable `graphify` job from `.github/workflows/graphify.yaml`.
   Its exact validation command is
   `nix run nixpkgs#devenv -- shell -- graphify-build --artifact-dir "$RUNNER_TEMP"`.
   `packages/graphify/lifecycle.nix` defines the wrapper, and
   `tools/graphify/src/configuration_nix/graphify/build.clj` implements its
   argument handling. Honor legitimate workflow conditions, but do not add a
   `graphify-skip` label or alter a workflow to bypass a failing check.
4. Also require all active destination-policy checks, required reviews, and
   resolution requirements to be satisfied. Do not dismiss reviews, resolve
   discussion cosmetically, use `--admin`, or change protections to merge.
5. Wait for the latest applicable runs on the exact PR revision or its
   corresponding current-base test merge. Pending, failed, cancelled, missing,
   stale, or unverifiable required checks are blockers. Check that the runs
   belong to this PR and SHA. Watch commands must have a bounded terminal
   timeout; a timeout is not success.
6. If the head changes, rerun affected local checks and verify the new remote
   results. If the base changes in a way not covered by the successful test
   merge, update the feature branch and obtain fresh checks rather than
   assuming an old green result still applies.
7. Once all checks and policies pass, merge with a merge commit and guard the
   reviewed head:

   ```sh
   rtk proxy gh pr merge PR_NUMBER --repo rcorrear/configuration.nix \
     --merge --match-head-commit VERIFIED_HEAD_SHA
   ```

   Replace the arguments with the verified values. Use this only while merge
   commits are still permitted. If the repository adopts a merge queue, follow
   the live queue requirements and continue verifying through actual merge;
   enabling auto-merge or entering the queue is not completion.

## Confirm the result

- Confirm the PR is `MERGED`, record its merge commit, fetch the publication
  remote, and verify that commit is contained in the intended destination
  branch. A pushed branch, open PR, or scheduled merge is not a landed change.
- Check the post-merge workflows applicable to that exact merge. The Graphify
  workflow publishes `graphify-SHA` on pushes to `main`; verify the relevant
  result rather than assuming it exists.
- If the merge occurred but post-merge validation fails, report both facts
  explicitly. Do not claim the change is unmerged, and do not silently revert
  or perform another landing without authorization.
- Leave unrelated local work and workspaces intact. Do not automatically delete
  branches or workspaces, switch the user's checkout, deploy NixOS, or perform
  hypervisor operations.
- Report the PR, destination, merge commit, checks actually observed, and any
  remaining follow-up. If blocked before merge, say plainly that the changes
  have not landed and identify the blocker.
