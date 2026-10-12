# Putting the I back in IDE: Towards a Github Explorer

- Source: <https://blog.janestreet.com/putting-the-i-back-in-ide-towards-a-github-explorer/>
- Published: 2018-03-27
- Kind: blog post

## Summary

- Describes Feature Explorer, an Emacs UI over Jane Street's Iron code review system and
  Mercurial, used daily by hundreds of engineers for about two years.
- Every "feature" (branch or pull request) gets its own sandboxed workspace directory,
  implemented with Mercurial's share extension (cheap shares pointing at one full clone),
  so build artifacts and uncommitted work persist per branch.
- A global todo lists reviews assigned to you first, then your own features, colored by
  state (failing build, in review, releasable, work in progress).
- Opening a feature from the todo simultaneously checks out the branch, changes into its
  sandbox, and opens the changed file at the changed line; switching context is a few
  keystrokes.
- Review happens in the editor: Iron computes which diffs a reviewer still needs to see
  across merges and rebases; one key approves; comments are "CR" code comments that land
  in the assignee's todo.
- The author argues any extensible editor plus Git and the GitHub API could replicate the
  core, and that a code review server under 100 ms latency was what made it click.

## Relevance to us

- Weak relevance: a developer workflow post. Our side-by-side checkouts plus per-agent
  `DUNE_BUILD_DIR` are a crude version of per-branch sandboxes, but nothing to build here.
- **Action:** none.

Tags: `culture`, `build`
