# learn git the super hard way cheatsheet

## 操纵repo（第0章）

- Lv3
  - `git init --bare <repo>`
  - `git init [--separate-git-dir <repo>] <worktree>`
  - `git clone --mirror|--bare <url> <repo>`
  - `git clone [--no-checkout] [--branch <ref>] [--separate-git-dir <repo>] <url> <worktree>`
  - `git worktree list|add|prune`

## 操纵对象（第1章）

- Lv1
  - `git hash-object -t <type> [--stdin|<file>] -w`
- Lv2
  - `git mktree --missing`
  - `git commit-tree <tree> -m <message> [-p <parent>]*`
  - `git mktag`
  - `git cat-file <type> <SHA1>`
  - `git ls-tree <SHA1> -- [<path>]`
  - `git count-objects`
  - `git fsck [--unreachable] [--connectivity-only]`
  - `git prune` - **有一定危险，可能会删掉有用的东西**
  - `git replace -f <original> <replacement>`
- Lv3
  - `git tag -a -m <message> <name> <object>` - 同时创建新引用在`refs/tags/<name>`
  - `git show <commit>`
  - `git show <tree>` - 如`HEAD^{tree}`
  - `git show <blob>` - 如`HEAD:index.js`
  - `git replace --edit <original>`
  - `git replace -l --format=long`
  - `git replace --delete <original>`
  - `git notes add | list | show <object> | remove <object>`

## 操纵引用（第2章）

- 添加/修改/删除
  - Lv2
    - `git rev-parse <object>`
    - `git update-ref --no-deref <ref> [-d|<new>]` - 修改`<ref>`
    - `git update-ref <ref> [-d|<new>]` - 修改`<ref>`或者其引用的引用
    - `git symbolic-ref --delete <ref>`
    - `git symbolic-ref <from> <to>`
  - Lv3
    - `git branch -f <branch> <commit-ish>` - 只能操纵`refs/heads/`
    - `git branch -D <branch>` - 只能操纵`refs/heads/`
    - `git tag -f <tag> <commit-ish>` - 只能操纵`refs/tags/`
    - `git tag -d <tag>` - 只能操纵`refs/tags/`
- 查看历史记录
  - Lv3
    - `git reflog`
- 单独查看
  - Lv2
    - `git rev-parse <ref>` - 可以接多个但是不如`git show-ref`好用
    - `git symbolic-ref <ref>`
- 批量查看
  - Lv2
    - `git show-ref [--head] [<ref>...]`
    - `git for-each-ref [<ref-pattern>...]`
  - Lv3
    - `git branch -av`
    - `git branch -avl <branch-pattern>`
    - `git tag -l <tag-pattern>`
- 给定commit-ish，逆向查找引用
  - Lv2
    - `git name-rev [--tags] --all|<commit-ish>`
  - Lv3
    - `git describe [--all] [--always] [<commit-ish>]` - 留空表示HEAD
    - `git describe [--all] [--always] --dirty`

## 操纵索引（第3章）

- Lv1
  - `git update-index --add --cacheinfo <mode>,<SHA1>,<path>`
- 不常用Lv2
  - `git update-index --add [--info-only] -- <path>`
  - `git update-index --force-remove -- <path>`
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
  - `git mv`
  - `git restore [--source <tree-ish>] [--staged] [--worktree] -- <path>`
  - `git checkout -f -- <path>`
  - `git commit`
  - `git stash [pop]`
  - `git clean -nd [-x|-X] [-- <path>]`（把`-n`换成`-f`就会真的删除，**非常危险**）
  - `git add -p`
  - `git restore -p`

## 操纵HEAD（第4章）

- Lv3
  - `git switch --detach <commit-ish>`
  - `git switch -c <branch> <commit-ish>`
  - `git switch <ref>`
  - `git reset --soft [<commit-ish>] --`
  - `git reset [--mixed] [<commit-ish>] --`
  - `git reset --hard [<commit-ish>] --`

- Lv3(旧语法)
  - `git checkout -- <path>` - 根据index更新worktree，见第3章
    - 请使用新语法：`git restore [--worktree] -- <path>`
  - `git checkout [--detach] [<commit-ish>] --` - 修改HEAD、index、worktree，见上面（留空`<tree-ish>`表示HEAD）
    - 请使用新语法：`git switch <commit-ish>`
  - `git checkout <commit-ish> -- <path>` - 根据tree更新index和worktree，见第3章
    - 请使用新语法：`git restore --source <commit-ish> --stage --worktree -- <path>`
  - `git reset [<tree-ish>] -- <path>` - 根据`<commit-ish>`修改index，见第3章
    - 请使用新语法：`git restore [--source <commit-ish>] --stage -- <path>`
  - `git reset --soft [<commit-ish>]` - 相当于依次执行以下命令：（留空`<tree-ish>`表示HEAD）
    - `git update-ref HEAD <commit-ish>` - 修改HEAD*或者*HEAD指向的引用
  - `git reset [--mixed] [<commit-ish>]` - 相当于依次执行以下命令：（留空`<tree-ish>`表示HEAD）
    - `git update-ref HEAD <commit-ish>` - 修改HEAD*或者*HEAD指向的引用
    - `git restore --staged -- :/` - 根据HEAD修改index，见第3章
  - `git reset --hard [<commit-ish>]` - 相当于依次执行以下命令：（留空`<tree-ish>`表示HEAD）
    - `git update-ref HEAD <commit-ish>` - 修改HEAD*或者*HEAD指向的引用
    - `git restore --staged --worktree -- :/` - 根据HEAD修改index，见第3章

## 操纵远程（第5章）

- Lv2
  - `git ls-remote <url>`
- Lv3
  - `git remote add <remote> [--mirror=push|fetch] <url>`
  - `git push [-u] <remote> <local-ref>:<remote-ref>`
  - `git fetch <remote> <remote-ref>:<local-ref>`
  - `git pull --ff-only`
- Lv3(不推荐使用的邪恶命令)
  - `git pull [--rebase]`

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
  - Lv4
    - `git mf`
    - `git mnf`
    - `git mnfnc`
  - Lv5
    - `git-mnfss`

## 操纵commit（第7章）

- Lv2
  - `git cherry-pick --keep-redundant-commits <commit-ish>...`
- Lv3
  - `git revert <commit-ish>...`
  - `git rebase --keep-empty [-i] [--onto <newbase>] [(<upstream>|--root) [<branch>]]`
    - `[--no-ff]`
    - `[--rebase-merges[=[no-]rebase-cousins]]`

## 检索与查看历史（第8章）

- 列出commit
  - Lv2
    - `git rev-list [-v] <commit-ish>`
  - Lv3
    - `git log`
    - `git show-branch` - 另一种方式查看整个repo的历史
  - Lv4
    - `git lg` - HEAD的简要历史
    - `git la` - 整个repo的简要历史
    - `git ls` - HEAD的文件修改摘要
    - `git lf` - HEAD的文件修改详情
- 检查文件的历史
  - Lv3
    - `git blame -n -- <path>` - 对每一行找出最近一次修改它的commit
  - Lv4
    - `git lf [--follow] -- <path>` - 列出相关commit
- 寻找文件
  - Lv4
    - `git find`
    - `git finds`
- 搜索关键词
  - Lv3
    - `git grep [-i] [-w] [-P] <regex> -- <path>` - 在worktree中搜索
    - `git grep --cached [-i] [-w] [-P] <regex> -- <path>` - 在index中搜索
    - `git grep [-i] [-w] [-P] <regex> <tree-ish> -- <path>` - 在tree中搜索
    - `git log -G <regex>` - 在HEAD的历史中搜索
    - `git grep <regex> $(git rev-list --all)` - 在整个repo中搜索
  - Lv4
    - `git greps [-i] [-w] [-P] <regex>`

## 邪恶的submodule（第9章）

- 一次性添加submodule的五个部分：
  - `git submodule add [-b <branch>] [--name <name>] -- <url> <path>`
- 分别修改submodule的五个部分：
  - `.gitmodules`
    - Lv0: `vim .gitmodules`
    - Lv2: `git config --file=.gitmodules submodule.<name>.<key> <value>`
  - `$GIT_DIR/config`
    - Lv0: `vim .git/config`
    - Lv2: `git config submodule.<name>.<key> <value>`
  - index
    - Lv2：`git update-index [--add|--force-remove] --cacheinfo 160000,<sha1>,<path>`
  - repo (`$GIT_DIR/modules/<name>`)
    - `git -C <path> ...`
  - worktree (`$GIT_WORK_TREE/<path>`)
    - `git -C <path> ...`
- 用静态更新动态：
  - `git submodule init -- <path>`
    - 用`.gitmodules`来更新`.git/config`
  - `git submodule update --init [--recursive] --checkout -- <path>`
    - 用`.gitmodules`和index来创建repo和worktree
  - `git submodule sync -- <path>`
    - 用`.gitmodules`来更新`.git/config`和repo的URL
  - `git gets -- <path>`
    - 快速下载指定commit
- 用静态和动态更新动态：
  - `git submodule update [--recursive] [--checkout|--rebase|--merge] -- <path>`
    - 用`.git/config`和index来更新repo和worktree，共5种选项
- 用动态更新静态：
  - `git update-index -- <path>` - 用repo来更新index
  - `git add <path>` - 用repo来更新index
  - `git submodule absorbgitdirs -- <path>`
    - 有repo、worktree、`.gitmodules`和index之后，用该命令创建`.git/config`并将repo移动到正确位置
- 删除：
  - `git submodule deinit -f -- <path>`
    - 删除`.git/config`和worktree
  - 其他部分需要逐一删除

## 批处理与自动化（第10章）

- `git for-each-ref` - 对每个引用进行处理（比`git show-ref`更灵活）
- `git filter-branch` - 对每个commit进行处理（比`git rebase`更灵活）
- `git submodule foreach --recursive` - 对每个submodule进行处理
- `git bisect` - 二分查找法定位bug位于哪个commit
- `vim .git/hooks/pre-commit` - 在commit前做检查
- `vim .git/hooks/commit-msg` - 自动撰写commit message
- `vim .git/hooks/pre-push` - 在push前做检查
- `vim .git/hooks/...`
- `git config --global core.autocrlf true|false|input`
- `git stripspace`
- `git config --global core.whitespace ...`
