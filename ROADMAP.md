注：命令前的编号是本教程中出现该命令的章数

```
$ git help -a

   See 'git help <command>' to read about a specific subcommand

   Main Porcelain Commands
03    add                  Add file contents to the index
14    am                   Apply a series of patches from a mailbox
14    archive              Create an archive of files from a named tree
09    bisect               Use binary search to find the commit that introduced a bug
02    branch               List, create, or delete branches
05    bundle               Move objects and refs by archive
03/04 checkout             Switch branches or restore working tree files
07    cherry-pick          Apply the changes introduced by some existing commits
      citool               Graphical alternative to git-commit
03    clean                Remove untracked files from the working tree
00    clone                Clone a repository into a new directory
03    commit               Record changes to the repository
02    describe             Give an object a human readable name based on an available ref
06    diff                 Show changes between commits, commit and working tree, etc
05    fetch                Download objects and refs from another repository
14    format-patch         Prepare patches for e-mail submission
      gc                   Cleanup unnecessary files and optimize the local repository
TODO  gitk                 The Git repository browser
08    grep                 Print lines matching a pattern
      gui                  A portable graphical interface to Git
00    init                 Create an empty Git repository or reinitialize an existing one
08    log                  Show commit logs
06    merge                Join two or more development histories together
03    mv                   Move or rename a file, a directory, or a symlink
01    notes                Add or inspect object notes
05    pull                 Fetch from and integrate with another repository or a local branch
05    push                 Update remote refs along with associated objects
      range-diff           Compare two commit ranges (e.g. two versions of a branch)
07    rebase               Reapply commits on top of another base tip
04    reset                Reset current HEAD to the specified state
03    restore              Restore working tree files
07    revert               Revert some existing commits
03    rm                   Remove files from the working tree and from the index
08    shortlog             Summarize 'git log' output
01    show                 Show various types of objects
TODO  sparse-checkout      Initialize and modify the sparse-checkout
03    stash                Stash the changes in a dirty working directory away
TODO  status               Show the working tree status
09    submodule            Initialize, update or inspect submodules
04    switch               Switch branches
02    tag                  Create, list, delete or verify a tag object signed with GPG
00    worktree             Manage multiple working trees

   Ancillary Commands / Manipulators
10    config               Get and set repository or global options
14    fast-export          Git data exporter
14    fast-import          Backend for fast Git data importers
09    filter-branch        Rewrite branches
      mergetool            Run merge conflict resolution tools to resolve merge conflicts
      pack-refs            Pack heads and tags for efficient repository access
01    prune                Prune all unreachable objects from the object database
02    reflog               Manage reflog information
05    remote               Manage set of tracked repositories
      repack               Pack unpacked objects in a repository
01    replace              Create, list, delete refs to replace objects

   Ancillary Commands / Interrogators
08    annotate             Annotate file lines with commit information
08    blame                Show what revision and author last modified each line of a file
01    count-objects        Count unpacked number of objects and their disk consumption
      difftool             Show changes using common diff tools
01    fsck                 Verifies the connectivity and validity of the objects in the database
      gitweb               Git web interface (web frontend to Git repositories)
TODO  help                 Display help information about Git
      instaweb             Instantly browse your working repository in gitweb
06    merge-tree           Show three-way merge without touching index
TODO  rerere               Reuse recorded resolution of conflicted merges
08    show-branch          Show branches and their commits
13    verify-commit        Check the GPG signature of commits
13    verify-tag           Check the GPG signature of tags
08    whatchanged          Show logs with difference each commit introduces

   Interacting with Others
14    archimport           Import a GNU Arch repository into Git
14    cvsexportcommit      Export a single commit to a CVS checkout
14    cvsimport            Salvage your data out of another SCM people love to hate
14    cvsserver            A CVS server emulator for Git
14    imap-send            Send a collection of patches from stdin to an IMAP folder
14    p4                   Import from and submit to Perforce repositories
14    quiltimport          Applies a quilt patchset onto the current branch
14    request-pull         Generates a summary of pending changes
14    send-email           Send a collection of patches as emails
14    svn                  Bidirectional operation between a Subversion repository and Git

   Low-level Commands / Manipulators
06    apply                Apply a patch to files and/or to the index
03    checkout-index       Copy files from the index to the working tree
      commit-graph         Write and verify Git commit-graph files
01    commit-tree          Create a new commit object
01    hash-object          Compute object ID and optionally creates a blob from a file
      index-pack           Build pack index file for an existing packed archive
06    merge-file           Run a three-way file merge
06    merge-index          Run a merge for files needing merging
01    mktag                Creates a tag object
01    mktree               Build a tree-object from ls-tree formatted text
      multi-pack-index     Write and verify multi-pack-indexes
05    pack-objects         Create a packed archive of objects
      prune-packed         Remove extra objects that are already in pack files
03/06 read-tree            Reads tree information into the index
02    symbolic-ref         Read, modify and delete symbolic refs
05    unpack-objects       Unpack objects from a packed archive
03    update-index         Register file contents in the working tree to the index
03    update-ref           Update the object name stored in a ref safely
03    write-tree           Create a tree object from the current index

   Low-level Commands / Interrogators
01    cat-file             Provide content or type and size information for repository objects
      cherry               Find commits yet to be applied to upstream
06    diff-files           Compares files in the working tree and the index
06    diff-index           Compare a tree to the working tree or index
06    diff-tree            Compares the content and mode of blobs found via two tree objects
10    for-each-ref         Output information on each ref
14    get-tar-commit-id    Extract commit ID from an archive created using git-archive
03    ls-files             Show information about files in the index and the working tree
05    ls-remote            List references in a remote repository
01    ls-tree              List the contents of a tree object
06    merge-base           Find as good common ancestors as possible for a merge
02    name-rev             Find symbolic names for given revs
      pack-redundant       Find redundant pack files
08    rev-list             Lists commit objects in reverse chronological order
02    rev-parse            Pick out and massage parameters
      show-index           Show packed archive index
02    show-ref             List references in a local repository
      unpack-file          Creates a temporary file with a blob's contents
      var                  Show a Git logical variable
05    verify-pack          Validate packed Git archive files

   Low-level Commands / Syncing Repositories
      daemon               A really simple server for Git repositories
05    fetch-pack           Receive missing objects from another repository
      http-backend         Server side implementation of Git over HTTP
05    send-pack            Push objects over Git protocol to another repository
      update-server-info   Update auxiliary info file to help dumb servers

   Low-level Commands / Internal Helpers
      check-attr           Display gitattributes information
      check-ignore         Debug gitignore / exclude files
      check-mailmap        Show canonical names and email addresses of contacts
      check-ref-format     Ensures that a reference name is well formed
      column               Display data in columns
      credential           Retrieve and store user credentials
      credential-cache     Helper to temporarily store passwords in memory
      credential-store     Helper to store credentials on disk
      fmt-merge-msg        Produce a merge commit message
      interpret-trailers   Add or parse structured information in commit messages
      mailinfo             Extracts patch and authorship from a single e-mail message
      mailsplit            Simple UNIX mbox splitter program
06    merge-one-file       The standard helper program to use with git-merge-index
      patch-id             Compute unique ID for a patch
      sh-i18n              Git's i18n setup code for shell scripts
      sh-setup             Common Git shell script setup code
10    stripspace           Remove unnecessary whitespace
```
