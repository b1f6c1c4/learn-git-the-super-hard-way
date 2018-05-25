# 第4章：直接操纵HEAD

## 基础知识

每个repo必须有一个HEAD，无论是否选配了worktree。

本章不介绍新的Lv2命令，但将常用的Lv3命令进行了Lv2的表示，以方便读者理解工作原理。

## 设置HEAD指向某一个commit

注意：`<commit-ish>`如果是一个间接引用，那么会被解引用
- Lv2
  - `git update-ref --no-deref HEAD <commit-ish>`
- Lv3
  - `git checkout --detach <commit-ish> --` - 相当于依次执行以下命令：
    - `git update-ref --no-deref HEAD <commit-ish>` - 修改HEAD
    - `git reset HEAD -- .` - 修改index
    - `git checkout-index -a` - 修改worktree

## 设置HEAD指向某一个间接引用

- Lv2
  - `git symbolic-ref HEAD <ref>`
- Lv3
  - `git checkout <ref> --` - 相当于依次执行以下命令：
    - `git symbolic-ref HEAD <ref>` - 修改HEAD
    - `git reset HEAD -- .` - 修改index
    - `git checkout-index -a` - 修改worktree

## 详解`git checkout`

必须在以下几种用法中选一种：
- `git checkout -- <path>` - 根据index更新worktree，见第3章
- `git checkout [--detach] [<commit-ish>] --` - 修改HEAD、index、worktree，见上面（留空`<tree-ish>`表示HEAD）
- `git checkout <commit-ish> -- <path>` - 相当于依次执行以下命令：
  - `git reset <commit-ish> -- <path>` - 根据`<commit-ish>`修改index，见第3章
  - `git checkout-index -- <path>` - 修改worktree

## 详解`git reset`

必须在以下几种用法中选一种：
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

## 详解`git commit`

相当于依次执行以下命令：
- `git write-tree`
- `git commit-tree <new-tree> -p HEAD`
- `git update-ref HEAD <new-commit>` - 修改HEAD*或者*HEAD指向的引用

## 备注

- 以下几个命令效果相同：
  - `git reset --hard [HEAD]`
  - `git checkout -f [HEAD] --`
  - `git checkout -f HEAD -- .`
  - 注意：以下命令跟以上命令完全不相同
      - `git checkout -f -- .`
- 在HEAD不是间接引用的情况下，以下几个命令效果相同：
  - `git reset --hard <commit-ish>`
  - `git checkout -f --detach <commit-ish>`

