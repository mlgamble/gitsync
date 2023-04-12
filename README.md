# Git-Sync (Bash)

This is a pretty crude tool that reads all `**/.gitsync` files in a git repository to forcefully update files from other git repositories. 

The intended use is in situations when you want to fork a repo, stay up-to-date with _most_ of the upstream but still have control over meaningful changes.

For example, building a bundle of templates as a single repo from actively developed/best-practise repos, or to build a monorepo to improve CI.

## .gitsync files
This tool provides a mechanism (`.gitsync` files) to describe what changes and what doesn't when you want to sync. Then it'll forcefully do that; no conflicts ever.

These files can be nested anywhere in the project, and multiple `.gitsync` files can be used. 

NOTE: a `.gitsync` file in a parent directory relative to another `.gitsync` file will automatically exclude (see [.rsync-filter files](#.rsync-filter-files)) that child directory from its sync

E.g. In a project with 2 .gitsync files `A/.gitsync` and `A/B/C/.gitsync`, the directory `A/B/C` will be excluded when doing the sync for directory `A`

The `.gitsync` file:
```properties
# REQUIRED
REMOTE="" # The git remote url to be used (git remote add ...)
BRANCH="" # The branch to fetch for changes (git fetch ...)

# OPTIONAL
REMOTE_PATH="" # A relative path from the root in the remote repository that will be used as the root path. Default: entire repo
POST_SYNC_SCRIPT="" # A bash-command to run after completing the sync
```
## .rsync-filter files
See the [full man page](https://linux.die.net/man/1/rsync) for more details

This uses rsync to do the updates, because it's a very robust tool, which means `.rsync-filter` files can be used to control what is synced and not synced.

These files can be placed at anywhere in the project and will be discovered

E.g. Exclude a file/directory from the upstream from copying to this repo
```properties
exclude gradle.bat
exclude .circleci/
```

E.g. Protect a local file/directory that does not exist in the upstream from being removed/modified
```properties
protect configurations/
protect README.md
```

