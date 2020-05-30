# 基础知识

每个repo可以引用（注意不是第0章中的“放弃对象和引用的所有权并链接”）其它repo。
这种对repo的引用称为remote。每个remote包括以下信息：
- 名字，惯例是origin和upstream
- URL，常见协议包括http、https、ftp、files、ssh（`git@github.com`实际上是ssh协议）
- 关于如何进行fetch的信息

本章所有命令都无需worktree。为了方便起见，本章所有命令都将直接在repo中操作，省略`--git-dir`。

```bash
git init --bare .
ls
```

# Packfile
研究Git remotes之前需要先研究packfile。
由于packfile内部格式相当复杂，本节不介绍Lv0命令。
以下命令均为Lv2。

在开始之前，先创建几个对象：
```bash
echo 'obj1' | git hash-object -t blob --stdin -w
echo 'obj2' | git hash-object -t blob --stdin -w
echo 'obj3' | git hash-object -t blob --stdin -w
git mktree <<EOF
100644 blob 5ff37e33c444f1ef1a6b3abda4fa05bf78352d12$(printf '\t')1.txt
100755 blob 95fc5713e4d2debb0e898632c63bfe4a4ce0c665$(printf '\t')2.txt
EOF
git mktree <<EOF
100644 blob cff99442835504ec82ba2b6d6328d898033a5300$(printf '\t')3.txt
040000 tree 2da98740b77749cb1b6b3acaee43a3644fb3e9e5$(printf '\t')dir
EOF
```
检查对象创建情况：
```bash
git ls-tree -r 187e
find objects -type f
```

## 创建Packfile

```bash
mkdir -p ../somewhere-else/
git pack-objects ../somewhere-else/prefix <<EOF
cff99442835504ec82ba2b6d6328d898033a5300
95fc5713e4d2debb0e898632c63bfe4a4ce0c665
187e91589a3f4f248f4cc8b1a1eca65b5161cc7b
EOF
ls ../somewhere-else/
```

## 自动列出应该打包哪些对象

前述方法手工指定了打包的文件；然而，由于没有打包blob 5ff3和tree 2da9，即便接收者拿到了对象也没有什么卵用（还原不出整个tree 187e，在`git checkout-index`时会失败）。
此时需要祭出Git最复杂的Lv2命令之一：`git rev-list`
（复杂程度与之不相上下的还有`git filter-branch`、`git merge-tree`）。

```bash
git rev-list --objects 187e
git rev-list --objects 187e | git pack-objects ../somewhere-else/prefix
```

## 查看Packfile

```bash
git verify-pack -v ../somewhere-else/prefix-2b2d8ce85275da98291c5ad8f60680b2dec81ba4.idx
git verify-pack -v ../somewhere-else/prefix-a451aab5615fb6d97e2ecb337b7f1d783ed66a70.idx
```
对于复杂的packfile，可能出现链状结构（只保存了增量修改信息）。详情参见[这里](https://git-scm.com/book/en/v2/Git-Internals-Packfiles)。

## 解压缩Packfile

（先删除所有objects：`rm -rf objects/*`)
```bash
git unpack-objects < ../somewhere-else/prefix-a451aab5615fb6d97e2ecb337b7f1d783ed66a70.pack
```

# 跨库直接对象传输

首先创建另一个repo：
```bash
mkdir -p ../another-repo.git/objects ../another-repo.git/refs
echo 'ref: refs/heads/master' > ../another-repo.git/HEAD
# 允许直接传输对象
git config uploadpack.allowAnySHA1InWant true
git --git-dir=../another-repo.git config uploadpack.allowAnySHA1InWant true
```

直接索要对象（若不加`--keep`则直接解Packfile）：
```bash
git --git-dir=../another-repo.git fetch-pack --keep --no-progress "$(pwd)" 187e91589a3f4f248f4cc8b1a1eca65b5161cc7b
```
注意：`$(pwd)`还可以是URL，用于跨域对象传输

# 跨库直接引用传输

创建引用：
```bash
git hash-object -t commit --stdin -w <<EOF
tree 187e91589a3f4f248f4cc8b1a1eca65b5161cc7b
author b1f6c1c4 <b1f6c1c4@gmail.com> 1514736000 +0800
committer b1f6c1c4 <b1f6c1c4@gmail.com> 1514736000 +0800

The commit message
EOF
git update-ref refs/heads/itst bb6d
```

直接索要引用及其对象：
```bash
git --git-dir=../another-repo.git fetch-pack --no-progress "$(pwd)" refs/heads/itst
```

直接推送引用及其对象：
```bash
git send-pack --force --no-progress ../another-repo.git refs/heads/itst
```

检查远程引用：
```bash
git ls-remote ../another-repo.git
```

# 跨库间接传输

跨域但无法建立网络连接时，先创建bundle：
```bash
git bundle create ../the-bundle refs/heads/itst
```
再解bundle：
```bash
git --git-dir=../another-repo.git bundle unbundle ../the-bundle
```

# Lv3命令

首先用Lv0命令修改设置，以讨论设置对Lv3的影响。

## 指明remote的`git push`和`git fetch`

裸remote：
```bash
cat >./config <<EOF
[remote "another"]
  url = ../another-repo.git
EOF
git push another itst
git fetch another itst
git fetch another itst:tsts
```

带默认fetch的remote：
```bash
cat >./config <<EOF
[remote "another"]
  url = ../another-repo.git
  fetch = +refs/heads/*:refs/heads/abc/*
  fetch = +refs/heads/*:refs/heads/def/*
EOF
git fetch another itst
```

强制全盘push：
```bash
cat >./config <<EOF
[remote "another"]
  url = ../another-repo.git
  mirror = true
EOF
git push another itst
git push another
```

## 未指明remote的`git push`和`git fetch`

```bash
cat >./config <<EOF
[remote "another"]
  url = ../another-repo.git
[branch "itst"]
  remote = another
  merge = refs/heads/itst
EOF
git symbolic-ref HEAD refs/heads/itst
git push --verbose
# 与git fetch无关
```

```bash
cat >./config <<EOF
[remote "another"]
  url = ../another-repo.git
  fetch = +refs/heads/*:refs/remotes/another/*
[branch "itst"]
  remote = another
EOF
git symbolic-ref HEAD refs/heads/itst
git fetch --verbose
# 与git push无关
```

## 使用Lv3命令修改设置

```bash
(rm -f ./config)
git remote add another ../another-repo.git
cat ./config
git push -u another itst
cat ./config
(rm -f ./config)
git remote add another --mirror=fetch ../another-repo.git
cat ./config
(rm -f ./config)
git remote add another --mirror=push ../another-repo.git
cat ./config
```

## 关于`git pull`

`git pull`基本上是先`git fetch`再`git merge FETCH_HEAD`；
`git pull --rebase`基本上是先`git fetch`再`git rebase FETCH_HEAD`。
由于这个命令高度不可控，非常不推荐使用。
然而`git pull --ff-only`却非常有用，是先`git fetch`再`git merge --ff-only FETCH_HEAD`。

# 复制repo：`git clone`

（参见第5章）

## `git clone --mirror`

复制另一个repo的大多数对象、所有普通引用、特殊引用HEAD

- Lv2
```bash
(rm -rf *) # 删掉之前所有东西
# 先准备好
git init --bare copy.git
cat >>./copy.git/config <<EOF
[remote "origin"]
  url = git@github.com:b1f6c1c4/learn-git-the-super-hard-way.git
  fetch = +refs/*:refs/*
  mirror = true
EOF
git --git-dir=copy.git fetch origin refs/heads/master:refs/heads/master
git --git-dir=copy.git fetch origin refs/heads/dev:refs/heads/dev
git --git-dir=copy.git symbolic-ref HEAD refs/heads/master
```

- Lv3
```bash
rm -rf copy.git
git clone --mirror git@github.com:b1f6c1c4/learn-git-the-super-hard-way.git copy.git
```

## `git clone --bare`

与`--mirror`类似，但是四不像（没有config）

- Lv2
```bash
rm -rf copy.git
git init --bare copy.git
tee -a ./copy.git/config <<EOF
[remote "origin"]
  url = git@github.com:b1f6c1c4/learn-git-the-super-hard-way.git
EOF
git --git-dir=copy.git fetch origin refs/heads/master:refs/heads/master
git --git-dir=copy.git fetch origin refs/heads/dev:refs/heads/dev
git --git-dir=copy.git symbolic-ref HEAD refs/heads/master
```

- Lv3

```bash
rm -rf copy.git
git clone --bare git@github.com:b1f6c1c4/learn-git-the-super-hard-way.git copy.git
```

## `git clone`

- Lv2

```bash
rm -rf copy-wt
git init copy-wt
tee -a ./copy-wt/.git/config <<EOF
[remote "origin"]
  url = git@github.com:b1f6c1c4/learn-git-the-super-hard-way.git
  fetch = +refs/*:refs/*
[branch "dev"]
  remote = origin
  merge = refs/heads/dev
EOF
git --git-dir=copy-wt/.git fetch origin
git --git-dir=copy-wt/.git update-ref refs/heads/dev refs/remotes/origin/dev
git --git-dir=copy-wt/.git symbolic-ref HEAD refs/heads/dev
# 如果指定了--no-checkout，省略这一行
git --git-dir=copy-wt/.git --work-tree=copy-wt checkout-index -fua
```

- Lv3
```bash
rm -rf copy-wt
git clone --branch dev git@github.com:b1f6c1c4/learn-git-the-super-hard-way.git copy-wt
```

# 总结

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
  - 检查
    - `git ls-remote <url>`
- Lv3
  - 配置
    - `git remote add <remote> [--mirror=push|fetch] <url>`
    - `git push -u <remote> <local-ref>:<remote-ref>`
  - 传输
    - `git push <remote> <local-ref>:<remote-ref>`
    - `git fetch <remote> <remote-ref>:<local-ref>`
  - 一键跟上进度
    - `git pull --ff-only`
  - 基于远程创建repo
    - `git clone --mirror <url> <repo>`
    - `git clone --bare <url> <repo>`
    - `git clone [--no-checkout] [--branch <ref>] [--separate-git-dir <repo>] <url> <worktree>`
  - 不推荐使用的邪恶命令
    - `git pull [--rebase]`

