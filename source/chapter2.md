# 第2章：直接操纵引用

## 基础知识

Git引用常规放在`<repo>/refs/`中，可以有任意层次的文件夹结构。
惯例如下：
- heads
  - 各本地分支
- remotes
  - 各远程仓库
    - 各远程分支
- tags
  - 各标签
- stash - 见第3章`git stash`
- replace - 见第1章`git replace`
- notes - 见第1章`git notes`

Git特别引用直接放在`<repo>`下，一般包括`HEAD`等。

引用可以分为直接（指向对象的）引用和间接（指向其他引用的）两种。

本章所有命令都不涉及worktree。后续章节会介绍如何利用worktree来操纵对象（Lv3）。

## 创建直接引用

注：若引用已存在，则会覆盖

- Lv0
该操作非常危险，因为没有保存操作记录。
```bash
mkdir -p ./refs/heads/
echo d4dafde7cd9248ef94c0400983d51122099d312a > ./refs/heads/br1
echo d4dafde7cd9248ef94c0400983d51122099d312a > ./refs/tags/tg1
```

- Lv2
该操作会在`<repo>/logs/refs/heads/br1`中留下操作记录。
```bash
git update-ref --no-deref -m 'Reason for update' refs/heads/br1 d4da
git update-ref --no-deref refs/tags/tg1 d4da
```

- Lv3
该操作会在`<repo>/logs/refs/heads/br1`中留下操作记录，原因是`branch: Created from ...`或者`branch: Reset to ...`。
```bash
# 此处必须省略refs/heads/
git branch -f br1 d4da
```

```bash
# 此处必须省略refs/tags/
git tag -f tg1 d4da
```

### 查看直接引用

- Lv0
```bash
cat ./refs/heads/br1
cat ./refs/tags/tg1
```

- Lv2
```bash
git rev-parse refs/heads/br1
git rev-parse refs/tags/tg1
```

- Lv3
```bash
# 此处必须省略refs/heads/
git branch -avl br1
# 此处必须省略refs/tags/
git tag -l tg1
```

### 创建间接引用

- Lv0
```bash
echo 'ref: refs/heads/br1' > ./refs/heads/br2
```

- Lv2
```bash
git symbolic-ref refs/heads/br2 refs/heads/br1
```

### 查看间接引用

- Lv0
```bash
cat ./refs/heads/br2
```

- Lv2
注意以下两者的区别
```bash
git symbolic-ref refs/heads/br2
git rev-parse refs/heads/br2
```

- Lv3
Lv3命令只能看到解引用后的对象，无法看清楚间接引用本身
```bash
# 此处必须省略refs/heads/
git branch -avl br1
git branch -avl br2
```

### 删除引用

- Lv0
```bash
rm ./refs/heads/br1
rm ./refs/heads/br2
rm ./refs/tags/tg1
```

- Lv2
```bash
# 以下操作会删除refs/heads/br1
git update-ref -d refs/heads/br1
git update-ref -d --no-deref refs/heads/br1
git update-ref -d refs/heads/br2 # 注意--no-deref的作用
# 以下操作会删除refs/heads/br2
git update-ref -d --no-deref refs/heads/br2
(git symbolic-ref refs/heads/br2 refs/heads/br1)
git symbolic-ref --delete refs/heads/br2
```

- Lv3
```bash
# 此处必须省略refs/heads/
(git update-ref --no-deref refs/heads/br1 d4da)
git branch -D br1
(git symbolic-ref refs/heads/br2 refs/heads/br1)
git branch -D br2
# 此处必须省略refs/tags/
(git update-ref --no-deref refs/tags/tg1 d4da)
git tag -d tg1
```

## 关于`update-ref`的特别备注

带`--no-deref`表明修改引用本身（不论其是什么类型的）
不带`--no-deref`表明修改引用本身（如果其不存在或者是直接引用）或者引用的引用（如果其是间接引用）
```bash
# 以下操作会修改refs/heads/br1
git update-ref refs/heads/br1 efd4
git update-ref --no-deref refs/heads/br1 efd4
git update-ref refs/heads/br2 efd4 # 注意--no-deref的作用
# 以下操作会修改refs/heads/br2，由间接引用变为直接引用
git update-ref --no-deref refs/heads/br2 efd4
```

## 查看历史记录

```bash
git update-ref --no-deref refs/heads/br1 d4da
git update-ref --no-deref refs/heads/br1 efd4
```

- Lv0

```bash
cat ./logs/refs/heads/br1
```

- Lv3

```bash
git reflog refs/heads/br1
```

## 批量查看引用

- Lv2

`git show-ref`接类似于`git rev-parse`的东西，而`git for-each-ref`接前缀：

```bash
(git update-ref --no-deref HEAD d4da)
(git update-ref --no-deref SOME_THING d4da)
(git update-ref --no-deref refs/heads/br1 d4da)
(git symbolic-ref refs/heads/br2 refs/heads/br1)
(git update-ref --no-deref refs/remotes/origin/br3 d4da)
(git update-ref --no-deref refs/tags/tg1 d4da)
git show-ref --head
git show-ref
git for-each-ref
git show-ref br1
git for-each-ref br1
git show-ref refs/remotes/
git for-each-ref refs/remotes/
```

两个都不能列出`$GIT_DIR`下的引用！

## 给定commit-ish，逆向查找引用

- Lv1

```bash
git show-ref | grep $(git rev-parse d4da) | awk '{ print $2; }'
```

- Lv2

```bash
git name-rev d4da
git name-rev --all
```

- Lv3

```bash
git describe d4da
git describe --always d4da
git describe d4da~
git describe --always d4da~
```

添加`--dirty`可以在结果后面添加`-dirty`，特别适用于版本号。

## 总结

- 添加/修改/删除
  - Lv0
    - 不推荐
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
  - Lv0
    - `cat <repo>/logs/<ref>`
  - Lv3
    - `git reflog`
- 单独查看
  - Lv0
    - `cat <repo>/<ref>`
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

## 扩展阅读

[git-rev-parse: specifying revisions](https://git-scm.com/docs/git-rev-parse#_specifying_revisions)

