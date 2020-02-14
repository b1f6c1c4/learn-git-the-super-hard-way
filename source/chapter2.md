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
- stash - 暂存
为了简化起见，在*Lv3命令中*且*不引起歧义的情况下*，`refs/*/`可以省略。

Git特别引用直接放在`<repo>`下，一般包括`HEAD`等。

引用可以分为直接（指向对象的）引用和间接（指向其他引用的）两种。

本章所有命令都不涉及worktree。后续章节会介绍如何利用worktree来操纵对象（Lv3）。

## 创建直接引用

注：若引用已存在，则会覆盖

- Lv0
该操作非常危险，因为没有保存操作记录。
```bash
mkdir -p the-repo.git/refs/heads/br1
echo bce83a8c51fdad7b2e11155826b9794590950268 > the-repo.git/refs/heads/br1
```

- Lv2
该操作会在`<repo>/logs/refs/heads/br1`中留下操作记录。
```bash
git --git-dir=the-repo.git update-ref --no-deref -m 'Reason for update' refs/heads/br1 bce8
```

- Lv3
该操作会在`<repo>/logs/refs/heads/br1`中留下操作记录，原因是`branch: Created from ...`或者`branch: Reset to ...`。
```bash
git --git-dir=the-repo.git branch -f refs/heads/br1 bce8
```

### 查看直接引用

- Lv0
```bash
cat the-repo.git/refs/heads/br1
# bce83a8c51fdad7b2e11155826b9794590950268
```

- Lv2
```bash
git --git-dir=the-repo.git rev-parse refs/heads/br1
# bce83a8c51fdad7b2e11155826b9794590950268
```

- Lv3
```bash
# 似乎此处必须省略refs/heads/
git --git-dir=the-repo.git branch -v --list br1
#   br1 bce83a8 The commit message
```

### 创建间接引用

- Lv0
```bash
echo 'ref: refs/heads/br1' > the-repo.git/refs/heads/br2
```

- Lv2
```bash
git --git-dir=the-repo.git symbolic-ref refs/heads/br2 refs/heads/br1
```

### 查看间接引用

- Lv0
```bash
cat the-repo.git/refs/heads/br2
# ref: refs/heads/br1
```

- Lv2
注意以下两者的区别
```bash
git --git-dir=the-repo.git symbolic-ref refs/heads/br2
# ref: refs/heads/br1
git --git-dir=the-repo.git rev-parse refs/heads/br2
# bce83a8c51fdad7b2e11155826b9794590950268
```

- Lv3
Lv3命令只能看到解引用后的对象，无法看清楚间接引用本身
```bash
# 似乎此处必须省略refs/heads/
git --git-dir=the-repo.git branch -v --list br1
#   br1 bce83a8 The commit message
git --git-dir=the-repo.git branch -v --list br2
#   br2 bce83a8 The commit message
```

### 删除引用

- Lv0
```bash
rm the-repo.git/refs/heads/br1
rm the-repo.git/refs/heads/br2
```

- Lv2
```bash
# 以下操作会删除refs/heads/br1
git --git-dir=the-repo.git update-ref -d refs/heads/br1
git --git-dir=the-repo.git update-ref -d --no-deref refs/heads/br1
git --git-dir=the-repo.git update-ref -d refs/heads/br2 # 注意--no-deref的作用
# 以下操作会删除refs/heads/br2
git --git-dir=the-repo.git update-ref -d --no-deref refs/heads/br2
git --git-dir=the-repo.git symbolic-ref --delete refs/heads/br2
```

- Lv3
```bash
# 似乎此处必须省略refs/heads/
git --git-dir=the-repo.git branch -D br1
# Deleted branch br1 (was bce83a8).
git --git-dir=the-repo.git branch -D br2
# Deleted branch br2 (was refs/heads/br1).
```

## 关于`update-ref`的特别备注

带`--no-deref`表明修改引用本身（不论其是什么类型的）
不带`--no-deref`表明修改引用本身（如果其不存在或者是直接引用）或者引用的引用（如果其是间接引用）
```bash
# 以下操作会修改refs/heads/br1
git --git-dir=the-repo.git update-ref refs/heads/br1 f9ab
git --git-dir=the-repo.git update-ref --no-deref refs/heads/br1 f9ab
git --git-dir=the-repo.git update-ref refs/heads/br2 f9ab # 注意--no-deref的作用
# 以下操作会修改refs/heads/br2，由间接引用变为直接引用
git --git-dir=the-repo.git update-ref --no-deref refs/heads/br2 f9ab
```

## 总结

- Lv0
  - 用来看可以，但是进行修改会非常危险
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

