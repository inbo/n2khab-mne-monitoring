---
aliases:
tags:
  - git
  - merge
  - db_tooldev
started: 2026-04-20
finished: 2026-04-20
execution:
  - FM
status: true
---
On the branch `db_tooldev`, #FM started to work on implementing a new #snippets version and bringing it to the database.
I confused `rep` version with `snip` version, and initiated work by merging `main` with the relevant changes by #FV into the dev branch.

However, because this was a dev branch, and I was lazy, I did not bother to move to a sub-branch of `dev_feature` and thought the commit message would be fine for later identification.
Then, other parallel commits happened on things I encountered on the way.

Realizing later I had to rewrite the commit message `db_rep0.15.1 [...]` to  `db_snip0.15.1 [...]`, I started a 

## merge commit interactive rebase

This starts on a commit *before* the one to adjust; I chose the one on the `dev` branch.

```sh
git rebase -i --rebase-merges <commit hash of a commit before the message issue>
```

> [!important] note the `--rebase-merges` flag which allows the attempt to rebase merges interactively.

- The rebase todo list will open in an editor.
- read the commented documentation below the todo list; watch out for `-C` and `-c`.
- On the merge commit, change `-C` to `-c`
- save and close
- another editor will spawn to allow changing the commit message

Rebase went through smoothly.

Afterwards, force-push with 
```sh
git push --force-with-lease origin db_tooldev
```