# Professional git cheatsheet

## 操纵repo（第0章）

- `git init --bare <repo>`
- `git init [--separate-git-dir <repo>] <worktree>`
- `git worktree list|add|prune`

## 操纵对象（第1章）

- Lv1
  - `git hash-object -t <type> [--stdin|<file>] -w` - 创建对象
- Lv2
  - `git mktree --missing` - 创建tree
  - `git commit-tree <tree> -m <message> [-p <parent>]*` - 创建commit
  - `git cat-file <type> <SHA1>` - 查看blob和commit
  - `git ls-tree <SHA1> -- [<path>]` - 查看tree
- Lv3
  - `git tag -a -m <message> <name> <object>` - 同时创建新引用在`refs/tags/<name>`
  - `git show <commit>`
  - `git show <tree>` - 如`HEAD^{tree}`
  - `git show <blob>` - 如`HEAD:index.js`

## 操纵引用（第2章）

- Lv2
  - `git rev-parse <object>`
  - `git update-ref --no-deref <ref> [-d|<new>]` - 修改`<ref>`
  - `git update-ref <ref> [-d|<new>]` - 修改`<ref>`或者其引用的引用
  - `git symbolic-ref <ref>`
  - `git symbolic-ref --delete <ref>`
  - `git symbolic-ref <from> <to>`
- Lv3
  - `git branch -f <branch> <commit-ish>` - 只能操纵`refs/heads/s`
  - `git branch -D <branch>` - 只能操纵`refs/heads/s`

## 操纵index（第3章）

- Lv1
  - `git update-index --add --cacheinfo <mode>,<SHA1>,<path>`
- 不常用Lv2
  - `git update-index --add [--info-only] -- <path>`
  - `git update-index --delete -- <path>`
  - `git checkout-index -fu [--prefix=<pf>] -a`
  - `git checkout-index -fu [--prefix=<pf>] -- <path>`
- 常用Lv2
  - `git update-index --chmod +x -- <path>`
  - `git ls-files -s`
  - `git ls-files -s -- <path>`
  - `git read-tree [--prefix=<pf>] <tree-ish>`
  - `git write-tree [--prefix=<pf>]`
- Lv3
  - `git add -f -- <path>`
  - `git rm --cached -- <path>`
  - `git mv` & `git cp`
  - `git reset [<tree-ish>] -- <path>` - 留空`<tree-ish>`表示HEAD
  - `git checkout -f -- <path>`
  - `git commit`

## 操纵HEAD（第4章）

- `git checkout -- <path>` - 根据index更新worktree，见第3章
- `git checkout [--detach] [<commit-ish>] --` - 修改HEAD、index、worktree，见上面（留空`<tree-ish>`表示HEAD）
- `git checkout <commit-ish> -- <path>` - 相当于依次执行以下命令：
  - `git reset <commit-ish> -- <path>` - 根据`<commit-ish>`修改index，见第3章
  - `git checkout-index -- <path>` - 修改worktree
- `git reset [<tree-ish>] -- <path>` - 根据`<commit-ish>`修改index，见第3章
- `git reset --soft [<commit-ish>]` - 相当于依次执行以下命令：（留空`<tree-ish>`表示HEAD）
  - `git update-ref HEAD <commit-ish>` - 修改HEAD*或者*HEAD指向的引用
- `git reset [--mixed] [<commit-ish>]` - 相当于依次执行以下命令：（留空`<tree-ish>`表示HEAD）
  - `git update-ref HEAD <commit-ish>` - 修改HEAD*或者*HEAD指向的引用
  - `git reset HEAD -- .` - 根据HEAD修改index，见第3章
- `git reset --hard [<commit-ish>]` - 相当于依次执行以下命令：（留空`<tree-ish>`表示HEAD）
  - `git update-ref HEAD <commit-ish>` - 修改HEAD*或者*HEAD指向的引用
  - `git reset HEAD -- .` - 根据HEAD修改index，见第3章
  - `git checkout-index -f -a` - 修改worktree

操纵remote（第5章）
- Lv2
  - Packfile
    - `git rev-list --objects <object> | git pack-objects <path-prefix>`
    - `git unpack-objects`
  - Bundle
    - `git bundle create <file> <refs>*`
    - `git bundle unbundle <file>`
  - 传输
    - `git fetch-pack <url> <hash>*` - 需要`git config uploadpack.allowAnySHA1InWant true`
    - `git fetch-pack <url> <ref>*`
    - `git send-pack --force <url> <local-ref>:<remote-ref>*`
- Lv3
  - 配置
    - `git remote add <remote> [--mirror=push|fetch] <url>`
    - `git push -u <remote> <ref>`
  - 传输
    - `git push <remote> <local-ref>:<remote-ref>`
    - `git fetch <remote> <remote-ref>:<local-ref>`

## 操纵merge（第6章）

- 查看和处理修改
  - Lv2
    - `git diff-tree [-p] <tree-ish> <tree-ish> -- <path>`
    - `git diff-tree [-p] <commit-ish> -- <path>`
    - `git diff-index [-p] [--cached] <tree-ish> -- <path>`
    - `git diff-files [-p] <path>`
    - `git apply [--cached] <patch> -- <path>`
  - Lv3
    - `git diff <tree-ish> <tree-ish> -- <path>`
    - `git show <commit-ish> -- <path>`
    - `git diff [--cached] <tree-ish> -- <path>`
    - `git diff -- <path>`
- 合并修改
  - Lv2
    - `git merge-file [--ours|--theirs|--union] C A B`
    - `git merge-tree C A B`
    - `git read-tree -m H M`
    - `git read-tree -m A C B`
    - `git merge-index -o git-merge-one-file -a`
  - Lv3
    - `git merge-resolve [--no-ff] [--no-commit] B`
    - `git merge-octopus [--no-ff] [--no-commit] B*`
    - `git merge -s ours [--no-ff] [--no-commit] B*`
    - `git merge -s recursive [--no-ff] [--no-commit] B`
    - `git merge -s subtree [--no-ff] [--no-commit] B`

## 操纵rebase（第7章）

- Lv2
  - `git cherry-pick --keep-redundant-commits <commit-ish>...`
- Lv3
  - `git revert <commit-ish>...`
  - `git rebase --keep-empty [-i] [--onto <newbase>] [(<upstream>|--root) [<branch>]]`
    - `[--no-ff]`
    - `[--rebase-merges[=[no-]rebase-cousins]]`
