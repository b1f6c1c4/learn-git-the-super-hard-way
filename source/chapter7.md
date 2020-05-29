# 基础知识

从物理结构上讲，一个commit表示一个完整的版本；
但是，从逻辑结构上讲，一个commit还可以表示 *相比于之前进行了哪些修改* 。

从物理结构上讲，一个ref就是一个commit的指针；
但是，从逻辑结构上讲，一个ref还可以表示 *一系列修改*。

为了简便起见，本章所有commit均为空；当commit非空时，请参照第6章进行merge。

```bash
git init .
git config alias.lg "log --graph --pretty=tformat:'%h -%d <%an/%cn> %s' --abbrev-commit"
```

# 复制逻辑commit

在开始之前，先创建几个commit：
```bash
git mktree </dev/null
git hash-object -t commit --stdin -w <<EOF
tree 4b825dc642cb6eb9a060e54bf8d69288fbee4904
author b1f6c1c4 <b1f6c1c4@gmail.com> 1514736000 +0800
committer b1f6c1c4 <b1f6c1c4@gmail.com> 1514736000 +0800

commit A
EOF
git hash-object -t commit --stdin -w <<EOF
tree 4b825dc642cb6eb9a060e54bf8d69288fbee4904
parent 7b2c8f5d87ac92311b142000cb783ea85d80c3d2
author b1f6c1c4 <b1f6c1c4@gmail.com> 1514736001 +0800
committer b1f6c1c4 <b1f6c1c4@gmail.com> 1514736001 +0800

commit B
EOF
git hash-object -t commit --stdin -w <<EOF
tree 4b825dc642cb6eb9a060e54bf8d69288fbee4904
parent cd5b86bab3df3d8556c03d03ecbabf136a5ca1da
author b1f6c1c4 <b1f6c1c4@gmail.com> 1514736002 +0800
committer b1f6c1c4 <b1f6c1c4@gmail.com> 1514736002 +0800

commit C
EOF
git hash-object -t commit --stdin -w <<EOF
tree 4b825dc642cb6eb9a060e54bf8d69288fbee4904
parent c6e6deb39bb4022a49e0ca72abe328d5bb9db47d
author b1f6c1c4 <b1f6c1c4@gmail.com> 1514736003 +0800
committer b1f6c1c4 <b1f6c1c4@gmail.com> 1514736003 +0800

commit D
EOF
git hash-object -t commit --stdin -w <<EOF
tree 4b825dc642cb6eb9a060e54bf8d69288fbee4904
parent cd5b86bab3df3d8556c03d03ecbabf136a5ca1da
author b1f6c1c4 <b1f6c1c4@gmail.com> 1514736004 +0800
committer b1f6c1c4 <b1f6c1c4@gmail.com> 1514736004 +0800

commit E
EOF
git hash-object -t commit --stdin -w <<EOF
tree 4b825dc642cb6eb9a060e54bf8d69288fbee4904
parent 2c353e8bf7f03cce07a8b8d8b7c20cbb9ea3d771
author b1f6c1c4 <b1f6c1c4@gmail.com> 1514736005 +0800
committer b1f6c1c4 <b1f6c1c4@gmail.com> 1514736005 +0800

commit F
EOF
git hash-object -t commit --stdin -w <<EOF
tree 4b825dc642cb6eb9a060e54bf8d69288fbee4904
parent 2c353e8bf7f03cce07a8b8d8b7c20cbb9ea3d771
author b1f6c1c4 <b1f6c1c4@gmail.com> 1514736006 +0800
committer b1f6c1c4 <b1f6c1c4@gmail.com> 1514736006 +0800

commit G
EOF
git hash-object -t commit --stdin -w <<EOF
tree 4b825dc642cb6eb9a060e54bf8d69288fbee4904
parent c6e6deb39bb4022a49e0ca72abe328d5bb9db47d
author b1f6c1c4 <b1f6c1c4@gmail.com> 1514736007 +0800
committer b1f6c1c4 <b1f6c1c4@gmail.com> 1514736007 +0800

commit H
EOF
git update-ref --no-deref refs/heads/br1 f071f8ea
git update-ref --no-deref refs/heads/br2 3aec5e98
git update-ref --no-deref refs/heads/br3 85706b31
git update-ref --no-deref refs/heads/br4 31155de8
git symbolic-ref HEAD refs/heads/br1
git lg br1 br2 br3 br4
```

- Lv1

```bash
git reset HEAD -- .
git checkout-index -f -a
git read-tree -m cd5b^ cd5b
git cat-file commit cd5b
git hash-object -t commit --stdin -w <<EOF
tree $(git write-tree)
parent $(git rev-parse HEAD)
author b1f6c1c4 <b1f6c1c4@gmail.com> 1514736001 +0800
committer b1f6c1c4 <b1f6c1c4@gmail.com> 1514736060 +0800

commit B
EOF
git reset --soft 21ee9448
```

- Lv3

```bash
git update-ref --no-deref refs/heads/br1 f071f8ea
GIT_COMMITTER_NAME=committer \
GIT_COMMITTER_EMAIL=committer@gmail.com \
GIT_COMMITTER_DATE='1514736060 +0800' \
git cherry-pick --keep-redundant-commits cd5b 2c35
git lg br1 br2 br3 br4
# 注意author信息与cd5b的一致
git cat-file commit HEAD~
# 注意author信息与2c35的一致
git cat-file commit HEAD
```

# 逻辑撤销commit

逻辑撤销即添加逆向修改。
你完全可以添加不在本分支上的commit的逆。

- Lv1

```bash
(git update-ref --no-deref refs/heads/br1 f071f8ea)
git reset --hard
git read-tree -m cd5b cd5b^
git cat-file commit cd5b
git hash-object -t commit --stdin -w <<EOF
tree $(git write-tree)
parent $(git rev-parse HEAD)
author b1f6c1c4 <b1f6c1c4@gmail.com> 1514736001 +0800
committer b1f6c1c4 <b1f6c1c4@gmail.com> 1514736001 +0800

Revert "commit B"

This reverts commit cd5b86bab3df3d8556c03d03ecbabf136a5ca1da.
EOF
git reset --soft 25911f90caf4b0081d23b3b0ba7e4a66fa61b349
git lg
(git reset --soft HEAD~)
```

- Lv3

`git revert`：对若干commits依次执行以下操作：
* `git read-tree -m <commit> <commit>^` （注意：此处方向反过来了）
* `git commit-tree $(git write-tree) -p HEAD`
  * author信息沿用原author的
* `git reset --soft <new-commit>`

遗憾的是，`git revert`并不支持`--allow-empty`，这里就不演示了。

# 详解`git rebase`

## 基本语义

为了更方便地执行大规模commit复制，`git rebase`应运而生。
基本用法是：
- `git rebase [--no-ff] --keep-empty [-i] [--onto <newbase>] [<upstream> [<branch>]]`
  - 若省略`--onto`，则`<newbase>=<upstream>`
  - 若省略`<branch>`，则为`git symbolic-ref HEAD`
  - 若省略`<upsteram>`，则为`<branch>`的默认remote
- `git rebase [--no-ff] --keep-empty [-i] --onto <newbase> --root [<branch>]`
  - 若省略`<branch>`，则为`git symbolic-ref HEAD`
- `git rebase [--no-ff] --keep-empty [-i] --root [<branch>]`
  - 若省略`<branch>`，则为`git symbolic-ref HEAD`

第一种rebase是把upsteram到branch的所有逻辑修改（选择性地）应用到newbase上。
依次执行以下命令：
* `git rev-list ^<upstream> <branch> > git-rebase-todo`
* `vim git-rebase-todo`
* `git update-ref <branch> <newbase>`
* `git symbolic-ref HEAD <branch>`
* `git reset --hard`
* 根据todo文件的内容，对每一个非drop项执行：
  * `git read-tree -m <commit>^ <commit>`
  * `git checkout-index -fua`
  * pick项：
    * 如果没有`--no-ff`且`<commit>`以HEAD为parent，则`git reset --hard <commit>`
    * 不然，`git commit-tree $(git write-tree) -p HEAD`
  * squash和fixup项：
    * `git commit-tree $(git write-tree) -p HEAD~`
  * `git reset --soft <new-commit>`

第二种rebase是把branch的所有逻辑修改（选择性地）应用到newbase上。
依次执行以下命令：
* `git rev-list ^<newbase> <branch> > git-rebase-todo`
* `vim git-rebase-todo`
* `git update-ref <branch> <newbase>`
* `git symbolic-ref HEAD <branch>`
* `git reset --hard`
* 根据todo文件的内容，对每一个非drop项执行：
  * `git read-tree -m <commit>^ <commit>`
  * `git checkout-index -fua`
  * pick项：
    * 如果没有`--no-ff`且`<commit>`以HEAD为parent，则`git reset --hard <commit>`
    * 不然，`git commit-tree $(git write-tree) -p HEAD`
  * squash和fixup项：
    * `git commit-tree $(git write-tree) -p HEAD~`
  * `git reset --soft <new-commit>`

第三种rebase是把branch的所有逻辑修改（选择性地）重新实现一遍。
依次执行以下命令：
* `git rev-list <branch> > git-rebase-todo`
* `vim git-rebase-todo`
* `git symbolic-ref HEAD <branch>`
* `git rm -rf .`
* 根据todo文件的内容，对第一个非drop项执行：
  * `git read-tree -m <commit>^ <commit>`
  * `git checkout-index -fua`
  * pick项：
    * 如果没有`--no-ff`且`<commit>`没有parent，则`git reset --hard <commit>`
    * 不然，`git commit-tree $(git write-tree)`
  * `git reset --soft <new-commit>`
* 根据todo文件的内容，对其余每一个非drop项执行：
  * `git read-tree -m <commit>^ <commit>`
  * pick项：
    * 如果没有`--no-ff`且`<commit>`以HEAD为parent，则`git reset --hard <commit>`
    * 不然，`git commit-tree $(git write-tree) -p HEAD`
  * squash和fixup项：
    * `git commit-tree $(git write-tree) -p HEAD~`
  * `git reset --soft <new-commit>`

## 示例

```bash
git update-ref --no-deref refs/heads/br1 f071f8ea
git update-ref --no-deref refs/heads/br2 3aec5e98
git update-ref --no-deref refs/heads/br3 85706b31
git update-ref --no-deref refs/heads/br4 31155de8
git symbolic-ref HEAD refs/heads/br1
git lg br1 br2 br3 br4
```

第一种rebase：
```bash
(git update-ref --no-deref refs/heads/br1 f071f8ea)
(git update-ref --no-deref refs/heads/br2 3aec5e98)
(git update-ref --no-deref refs/heads/br3 85706b31)
(git update-ref --no-deref refs/heads/br4 31155de8)
(git symbolic-ref HEAD refs/heads/br1)
GIT_COMMITTER_NAME=committer \
GIT_COMMITTER_EMAIL=committer@gmail.com \
GIT_COMMITTER_DATE='1514736120 +0800' \
git rebase --quiet --no-ff --keep-empty --onto br2 br3 br4
git lg br1 br2 br3 br4
```

第二种rebase：
```bash
(git update-ref --no-deref refs/heads/br1 f071f8ea)
(git update-ref --no-deref refs/heads/br2 3aec5e98)
(git update-ref --no-deref refs/heads/br3 85706b31)
(git update-ref --no-deref refs/heads/br4 31155de8)
(git symbolic-ref HEAD refs/heads/br1)
GIT_COMMITTER_NAME=committer \
GIT_COMMITTER_EMAIL=committer@gmail.com \
GIT_COMMITTER_DATE='1514736120 +0800' \
git rebase --quiet --no-ff --keep-empty --onto br2 --root br4
git lg br1 br2 br3 br4
```

第三种rebase：
```bash
(git update-ref --no-deref refs/heads/br1 f071f8ea)
(git update-ref --no-deref refs/heads/br2 3aec5e98)
(git update-ref --no-deref refs/heads/br3 85706b31)
(git update-ref --no-deref refs/heads/br4 31155de8)
(git symbolic-ref HEAD refs/heads/br1)
GIT_AUTHOR_NAME=author \
GIT_AUTHOR_EMAIL=author@gmail.com \
GIT_AUTHOR_DATE='1234567890 +0800' \
GIT_COMMITTER_NAME=committer \
GIT_COMMITTER_EMAIL=committer@gmail.com \
GIT_COMMITTER_DATE='1514736120 +0800' \
git rebase --quiet --no-ff --keep-empty --root br4
git lg br1 br2 br3 br4
```

# 对merge的处理

`git rebase`有四种处理merge的模式。
其中`--preserve-merge`由于bug连篇建议在任何情况下都不要使用。

下面分别对三种rebase讨论其他三种处理方式的语义。

- 第一种rebase：对于`^<upstream> <branch>`
  - 默认：
    - 先对所有待rebase的DFS排序
    - 再去掉所有包含多于1个parent的commit
    - 依次应用到`<newbase>`上
  - `--rebase-merges[=-no-rebase-cousins]`：
    - 原没有parent，现依然没有parent
    - 原以`<upstream>^!`为直接parent，现以`<newbase>`为直接parent
    - 原以`<upstream>^@`为直接parent，parent不变
    - 原以`^<upstream> <branch>`为直接parent，现以新创建的相应commit为parent
  - `--rebase-merges=rebase-cousins`：
    - 原没有parent，现以`<newbase>`为parent
    - 原以`<upstream>^!`为直接parent，变成以`<newbase>`为直接parent
    - 原以`<upstream>^@`为直接parent，parent不变
    - 原以`^<upstream> <branch>`为直接parent，现以新创建的相应commit为parent
- 第二种rebase：对于`^<newbase> <branch>`
  - 默认：
    - 先对所有待rebase的DFS排序
    - 再去掉所有包含多于1个parent的commit
    - 依次应用到`<newbase>`上
  - `--rebase-merges[=-no-rebase-cousins]`：
    - 原没有parent，现依然没有parent
    - 原以`<newbase>`为直接parent，parent不变
    - 原以`^<newbase> <branch>`为直接parent，现以新创建的相应commit为parent
  - `--rebase-merges=rebase-cousins`：
    - 原没有parent，现以`<newbase>`为parent
    - 原以`<newbase>`为直接parent，parent不变
    - 原以`^<newbase> <branch>`为直接parent，现以新创建的相应commit为parent
- 第三种rebase：对于`<branch>`
  - 默认：
    - 先对所有待rebase的DFS排序
    - 再去掉所有包含多于1个parent的commit
    - 从零开始复制
  - `--rebase-merges[=-no-rebase-cousins]`：同下
  - `--rebase-merges=rebase-cousins`：
    - 原没有parent，现依然没有parent
    - 原以`<branch>`为直接parent，现以新创建的相应commit为parent

# 总结

- Lv2
  - `git cherry-pick --keep-redundant-commits <commit-ish>...`
- Lv3
  - `git revert <commit-ish>...`
  - `git rebase --keep-empty [-i] [--onto <newbase>] [(<upstream>|--root) [<branch>]]`
    - `[--no-ff]`
    - `[--rebase-merges[=[no-]rebase-cousins]]`
