# 第4章：直接操纵HEAD

## 基础知识

每个repo必须有一个HEAD，无论是否选配了worktree。

本章不介绍新的Lv2命令，但将常用的Lv3命令进行了Lv2的表示，以方便读者理解工作原理。

## 设置HEAD指向某一个commit

注意：`<commit-ish>`如果是一个间接引用，那么会被解引用
- Lv2
  - `git update-ref --no-deref HEAD <commit-ish>`
- Lv3
  - `git switch --detach <commit-ish>` - 相当于依次执行以下命令：
    - `git update-ref --no-deref HEAD <commit-ish>` - 修改HEAD
    - `git read-tree HEAD` - 修改index
    - `git checkout-index -a` - 修改worktree
  - 旧语法`git checkout --detach <commit-ish> --`

## 创建直接引用并设置HEAD指向它

- Lv2：一步一步来即可
- Lv3
  - `git switch -c <branch> <commit-ish>` - 相当于依次执行以下命令：
    - `git update-ref --no-deref refs/heads/<branch> <commit-ish>` - 创建直接引用
    - `git symbolic-ref HEAD refs/heads/<branch>` - 修改HEAD
    - `git read-tree HEAD` - 修改index
    - `git checkout-index -a` - 修改worktree
  - 旧语法`git checkout -b <branch> <commit-ish> --`


## 设置HEAD指向某一个直接引用

- Lv2
  - `git symbolic-ref HEAD <ref>`
- Lv3
  - `git switch <ref>` - 相当于依次执行以下命令：
    - `git symbolic-ref HEAD <ref>` - 修改HEAD
    - `git reset HEAD -- .` - 修改index
    - `git checkout-index -a` - 修改worktree
  - 旧语法`git checkout <ref> --`

## 详解`git checkout`

注意：该命令只有旧语法，请避免使用。

必须在以下几种用法中选一种：
- `git checkout -- <path>` - 根据index更新worktree，见第3章
  - 请使用新语法：`git restore [--worktree] -- <path>`
- `git checkout [--detach] [<commit-ish>] --` - 修改HEAD、index、worktree，见上面（留空`<tree-ish>`表示HEAD）
  - 请使用新语法：`git switch <commit-ish>`
- `git checkout <commit-ish> -- <path>` - 根据tree更新index和worktree，见第3章
  - 请使用新语法：`git restore --source <commit-ish> --stage --worktree -- <path>`

## 详解`git reset`

必须在以下几种用法中选一种：
- `git reset [<tree-ish>] -- <path>` - 根据`<commit-ish>`修改index，见第3章
  - 请使用新语法：`git restore [--source <commit-ish>] --stage -- <path>`
- `git reset --soft [<commit-ish>] --` - 相当于依次执行以下命令：（留空`<tree-ish>`表示HEAD）
  - `git update-ref HEAD <commit-ish>` - 修改HEAD*或者*HEAD指向的引用
- `git reset [--mixed] [<commit-ish>] --` - 相当于依次执行以下命令：（留空`<tree-ish>`表示HEAD）
  - `git update-ref HEAD <commit-ish>` - 修改HEAD*或者*HEAD指向的引用
  - `git restore --staged -- :/` - 根据HEAD修改index，见第3章
- `git reset --hard [<commit-ish>] --` - 相当于依次执行以下命令：（留空`<tree-ish>`表示HEAD）
  - `git update-ref HEAD <commit-ish>` - 修改HEAD*或者*HEAD指向的引用
  - `git restore --staged --worktree -- :/` - 根据HEAD修改index，见第3章

## 详解`git commit`

相当于依次执行以下命令：
- `git write-tree`
- `git commit-tree <new-tree> -p HEAD`
- `git update-ref HEAD <new-commit>` - 修改HEAD*或者*HEAD指向的引用

## 备注

- 以下几个命令效果相同：
  - `git restore --source HEAD --stage --worktree -- :/
  - `git reset --hard [HEAD]`
  - （旧语法）`git checkout -f [HEAD] --`
  - （旧语法）`git checkout -f HEAD -- .`
- 以下几个命令效果相同，但跟以上命令完全不相同：
  - `git restore -- :/
  - `git restore --worktree -- :/
  - `git restore --stage --worktree -- :/
  - （旧语法）`git checkout -f -- .`
- 以下命令没有任何效果：
  - `git switch <branch>`（假设HEAD已经指向`refs/heads/<branch>`）
- 在HEAD不是间接引用的情况下，以下几个命令效果相同：
  - `git reset --hard <commit-ish>`
  - `git switch --detach <commit-ish>`
  - （旧语法）`git checkout -f --detach <commit-ish>`

## 总结

- Lv3
  - `git switch --detach <commit-ish>`
  - `git switch -c <branch> <commit-ish>`
  - `git switch <ref>`
  - `git reset --soft [<commit-ish>] --`
  - `git reset [--mixed] [<commit-ish>] --`
  - `git reset --hard [<commit-ish>] --`

