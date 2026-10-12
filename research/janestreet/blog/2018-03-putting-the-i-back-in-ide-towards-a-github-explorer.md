# Putting the I back in IDE: Towards a Github Explorer

- Source: <https://blog.janestreet.com/putting-the-i-back-in-ide-towards-a-github-explorer/>
- Published: 2018-03-27
- Kind: blog post

## Summary

- Describes Feature Explorer, an Emacs UI over Jane Street's Iron review system and
  Mercurial, used daily by hundreds of engineers for about two years; the goal is to
  inspire similar tools for Git, GitHub and other editors.
- The argument: browser-based review is not only inconvenient but shallower, since real
  understanding needs building, running and exploring code in your own editor.
- Every branch of every repository gets its own sandboxed directory with persisted history,
  uncommitted work and build artifacts, built on Mercurial's share extension (cheap
  per-branch shares backed by one full clone per repository).
- A global todo lists assigned reviews first (deliberately treated as urgent), then your
  own features, color-coded: failing build, in review, releasable, work in progress.
- "Features" unify branches and pull requests; enabling or disabling review toggles
  visibility, so an author can go quiet to rework after feedback.
- Opening a feature from the todo does four things at once: review summary, checkout of the
  branch, change into its sandbox, and open the file at the changed line.
- Review is in the editor: Iron computes which diffs remain for each reviewer across merges
  and rebases; one key approves; comments are "CR" code comments that are assigned and
  resolved by editing and appear in the assignee's todo.
- Any extensible editor plus the GitHub API could replicate the core; the most valuable
  piece is jumping from a pull request to the file on that branch on local disk, and the
  system only felt right once the review server answered in under 100 ms.

## Relevance to us

- A developer workflow post. Our side-by-side checkouts plus per-agent `DUNE_BUILD_DIR`
  are a crude form of per-branch sandboxes; nothing concrete to change in our repos.
  **Action:** none.

Tags: `culture`, `build`
