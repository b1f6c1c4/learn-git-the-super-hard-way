# 第5章：直接操纵远程

## 基础知识

每个repo可以引用（注意不是第0章中的“放弃对象和引用的所有权并链接”）其它repo。
这种对repo的引用称为remote。每个remote包括以下信息：
- 名字，惯例是origin和upstream
- URL，常见协议包括http、https、ftp、files、ssh（`git@github.com`实际上是ssh协议）
- 关于如何进行fetch的信息

本章所有命令都无需worktree。为了方便起见，本章所有命令都将直接在repo中操作，省略`--git-dir`。

## Packfile
研究Git remotes之前需要先研究packfile。
由于packfile内部格式相当复杂，本节不介绍Lv0命令。
以下命令均为Lv2。

在开始之前，先创建几个对象：
```bash
echo 'obj1' | git hash-object -t blob --stdin -w
# 5ff37e33c444f1ef1a6b3abda4fa05bf78352d12
echo 'obj2' | git hash-object -t blob --stdin -w
# 95fc5713e4d2debb0e898632c63bfe4a4ce0c665
echo 'obj3' | git hash-object -t blob --stdin -w
# cff99442835504ec82ba2b6d6328d898033a5300
git mktree <<EOF
100644 blob 5ff37e33c444f1ef1a6b3abda4fa05bf78352d12	1.txt
100755 blob 95fc5713e4d2debb0e898632c63bfe4a4ce0c665	2.txt
EOF
# 2da98740b77749cb1b6b3acaee43a3644fb3e9e5
git mktree <<EOF
100644 blob cff99442835504ec82ba2b6d6328d898033a5300	3.txt
040000 tree 2da98740b77749cb1b6b3acaee43a3644fb3e9e5	dir
EOF
# 187e91589a3f4f248f4cc8b1a1eca65b5161cc7b
```
检查对象创建情况：
```bash
git ls-tree -r 187e
# 100644 blob cff99442835504ec82ba2b6d6328d898033a5300    3.txt
# 100644 blob 5ff37e33c444f1ef1a6b3abda4fa05bf78352d12    dir/1.txt
# 100755 blob 95fc5713e4d2debb0e898632c63bfe4a4ce0c665    dir/2.txt
find objects -type f
# objects/cf/f99442835504ec82ba2b6d6328d898033a5300
# objects/5f/f37e33c444f1ef1a6b3abda4fa05bf78352d12
# objects/95/fc5713e4d2debb0e898632c63bfe4a4ce0c665
# objects/18/7e91589a3f4f248f4cc8b1a1eca65b5161cc7b
# objects/2d/a98740b77749cb1b6b3acaee43a3644fb3e9e5
```

### 创建Packfile

```bash
mkdir -p ../somewhere-else/
git pack-objects ../somewhere-else/prefix <<EOF
cff99442835504ec82ba2b6d6328d898033a5300
95fc5713e4d2debb0e898632c63bfe4a4ce0c665
187e91589a3f4f248f4cc8b1a1eca65b5161cc7b
EOF
# Counting objects: 3, done.
# 2b2d8ce85275da98291c5ad8f60680b2dec81ba4
# Writing objects: 100% (3/3), done.
# Total 3 (delta 0), reused 0 (delta 0)
ls ../somewhere-else/
# prefix-2b2d8ce85275da98291c5ad8f60680b2dec81ba4.idx
# prefix-2b2d8ce85275da98291c5ad8f60680b2dec81ba4.pack
```

### 自动列出应该打包哪些对象

前述方法手工指定了打包的文件；然而，由于没有打包blob 5ff3和tree 2da9，即便接收者拿到了对象也没有什么卵用（还原不出整个tree 187e，在`git checkout-index`时会失败）。
此时需要祭出Git最复杂的Lv2命令之一：`git rev-list`
（复杂程度与之不相上下的还有`git filter-branch`、`git merge-tree`）。

```bash
git rev-list --objects 187e
# 187e91589a3f4f248f4cc8b1a1eca65b5161cc7b
# cff99442835504ec82ba2b6d6328d898033a5300 3.txt
# 2da98740b77749cb1b6b3acaee43a3644fb3e9e5 dir
# 5ff37e33c444f1ef1a6b3abda4fa05bf78352d12 dir/1.txt
# 95fc5713e4d2debb0e898632c63bfe4a4ce0c665 dir/2.txt
git rev-list --objects 187e | git pack-objects ../somewhere-else/prefix
# Counting objects: 5, done.
# Delta compression using up to 2 threads.
# Compressing objects: 100% (2/2), done.
# a451aab5615fb6d97e2ecb337b7f1d783ed66a70
# Writing objects: 100% (5/5), done.
# Total 5 (delta 0), reused 0 (delta 0)
```

### 查看Packfile

```bash
git verify-pack -v ../somewhere-else/prefix-2b2d8ce85275da98291c5ad8f60680b2dec81ba4.idx
# cff99442835504ec82ba2b6d6328d898033a5300 blob   5 14 12
# 95fc5713e4d2debb0e898632c63bfe4a4ce0c665 blob   5 14 26
# 187e91589a3f4f248f4cc8b1a1eca65b5161cc7b tree   63 73 40
# non delta: 3 objects
# ../somewhere-else/prefix-2b2d8ce85275da98291c5ad8f60680b2dec81ba4.pack: ok
git verify-pack -v ../somewhere-else/prefix-a451aab5615fb6d97e2ecb337b7f1d783ed66a70.idx
# 187e91589a3f4f248f4cc8b1a1eca65b5161cc7b tree   63 73 12
# cff99442835504ec82ba2b6d6328d898033a5300 blob   5 14 85
# 2da98740b77749cb1b6b3acaee43a3644fb3e9e5 tree   66 75 99
# 5ff37e33c444f1ef1a6b3abda4fa05bf78352d12 blob   5 14 174
# 95fc5713e4d2debb0e898632c63bfe4a4ce0c665 blob   5 14 188
# non delta: 5 objects
# ../somewhere-else/prefix-a451aab5615fb6d97e2ecb337b7f1d783ed66a70.pack: ok
```
对于复杂的packfile，可能出现链状结构（只保存了增量修改信息）。详情参见[这里](https://git-scm.com/book/en/v2/Git-Internals-Packfiles)。

### 解压缩Packfile

（先删除所有objects：`rm -rf objects/*`)
```bash
git unpack-objects < ../somewhere-else/prefix-a451aab5615fb6d97e2ecb337b7f1d783ed66a70.pack
# Unpacking objects: 100% (5/5), done.
```

## 跨库直接对象传输

首先创建另一个repo：
```bash
mkdir -p ../another-repo.git/objects ../another-repo.git/refs
echo 'ref: refs/heads/master' > ../another-repo.git/HEAD
# 允许直接传输对象
git config uploadpack.allowAnySHA1InWant true
```

直接索要对象（若不加`--keep`则直接解Packfile）：
```bash
git --git-dir=../another-repo.git fetch-pack --keep ../the-repo.git 187e91589a3f4f248f4cc8b1a1eca65b5161cc7b
# remote: Counting objects: 5, done.
# remote: Compressing objects: 100% (2/2), done.
# remote: Total 5 (delta 0), reused 0 (delta 0)
# Receiving objects: 100% (5/5), done.
# keep    a451aab5615fb6d97e2ecb337b7f1d783ed66a70
# 187e91589a3f4f248f4cc8b1a1eca65b5161cc7b 187e91589a3f4f248f4cc8b1a1eca65b5161cc7b
```
注意：`../the-repo.git`还可以是URL，用于跨域对象传输

## 跨库直接引用传输

创建引用：
```bash
git hash-object -t commit --stdin -w <<EOF
tree 187e91589a3f4f248f4cc8b1a1eca65b5161cc7b
author b1f6c1c4 <b1f6c1c4@gmail.com> 1514736000 +0800
committer b1f6c1c4 <b1f6c1c4@gmail.com> 1514736000 +0800

The commit message
EOF
# bb6d205106a1104778884986d8e3594f35170fae
git update-ref refs/heads/itst bb6d
```

直接索要引用及其对象：
```bash
git --git-dir=../another-repo.git fetch-pack ../the-repo.git refs/heads/itst
# remote: Counting objects: 6, done.
# remote: Compressing objects: 100% (3/3), done.
# remote: Total 6 (delta 0), reused 0 (delta 0)
# Unpacking objects: 100% (6/6), done.
# bb6d205106a1104778884986d8e3594f35170fae refs/heads/itst
```

直接推送引用及其对象：
```bash
git send-pack --force ../another-repo.git 187e91589a3f4f248f4cc8b1a1eca65b5161cc7b
# git send-pack --force ../another-repo.git refs/heads/itst
# Counting objects: 6, done.
# Delta compression using up to 2 threads.
# Compressing objects: 100% (3/3), done.
# Writing objects: 100% (6/6), 343 bytes | 343.00 KiB/s, done.
# Total 6 (delta 0), reused 0 (delta 0)
# To ../another-repo.git
#  * [new branch]      itst -> itst
```

检查远程引用：
```bash
git ls-remote ../another-repo.git
```

## 跨库间接传输

跨域但无法建立网络连接时，先创建bundle：
```bash
git bundle create ../the-bundle refs/heads/itst
# Counting objects: 6, done.
# Delta compression using up to 2 threads.
# Compressing objects: 100% (3/3), done.
# Writing objects: 100% (6/6), 343 bytes | 343.00 KiB/s, done.
# Total 6 (delta 0), reused 0 (delta 0)
```
再解bundle：
```bash
git --git-dir=../another-repo.git bundle unbundle ../the-bundle
# bb6d205106a1104778884986d8e3594f35170fae refs/heads/itst
```

## Lv3命令

首先用Lv0命令修改设置，以讨论设置对Lv3的影响。

### 指明remote的`git push`和`git fetch`

裸remote：
```bash
cat <<EOF >../the-repo.git/config
[remote "another"]
  url = ../another-repo.git
EOF
git push another itst
# Counting objects: 6, done.
# Delta compression using up to 2 threads.
# Compressing objects: 100% (3/3), done.
# Writing objects: 100% (6/6), 343 bytes | 343.00 KiB/s, done.
# Total 6 (delta 0), reused 0 (delta 0)
# To ../another-repo.git
#  * [new branch]      itst -> itst
git fetch another itst
# From ../another-repo
#  * branch            itst       -> FETCH_HEAD
git fetch another itst:tsts
# From ../another-repo
#  * [new branch]      itst       -> tsts
```

带默认fetch的remote：
```bash
cat <<EOF >../the-repo.git/config
[remote "another"]
  url = ../another-repo.git
  fetch = +refs/heads/*:refs/heads/abc/*
  fetch = +refs/heads/*:refs/heads/def/*
EOF
git fetch another itst
# From ../another-repo
#  * branch            itst       -> FETCH_HEAD
#  * [new branch]      itst       -> abc/itst
#  * [new branch]      itst       -> def/itst
```

强制全盘push：
```bash
cat <<EOF >../the-repo.git/config
[remote "another"]
  url = ../another-repo.git
  mirror = true
EOF
git push another itst
# error: --mirror can't be combined with refspecs
git push another
# ......
# To ../another-repo.git/
#  * [new branch]      abc/itst -> abc/itst
#  * [new branch]      def/itst -> def/itst
#  * [new branch]      master -> master
#  * [new branch]      tsts -> tsts
# ......
```

### 未指明remote的`git push`和`git fetch`

```bash
cat <<EOF >../the-repo.git/config
[remote "another"]
  url = ../another-repo.git
[branch "itst"]
  remote = another
  merge = refs/heads/itst
EOF
git symbolic-ref HEAD refs/heads/itst
# git push --verbose
# Pushing to ../another-repo.git
# To ../another-repo.git
#  = [up to date]      itst -> itst
# Everything up-to-date
# 与git fetch无关
```

```bash
cat <<EOF >../the-repo.git/config
[remote "another"]
  url = ../another-repo.git
  fetch = +refs/heads/*:refs/remotes/another/*
[branch "itst"]
  remote = another
EOF
git symbolic-ref HEAD refs/heads/itst
git fetch --verbose
# From ../another-repo
#  = [up to date]      itst       -> another/itst
# 与git push无关
```

### 使用Lv3命令修改设置

```bash
git remote add another ../another-repo.git
cat ../the-repo.git/config
# [remote "another"]
#         url = ../another-repo.git/
#         fetch = +refs/heads/*:refs/remotes/another/*
git remote add another --mirror=fetch ../another-repo.git
cat ../the-repo.git/config
# [remote "another"]
#         url = ../another-repo.git/
#         fetch = +refs/*:refs/*
git remote add another --mirror=push ../another-repo.git
cat ../the-repo.git/config
# [remote "another"]
#         url = ../another-repo.git/
#         mirror = true
git push -u another itst
cat ../the-repo.git/config
# ......
# [branch "itst"]
#         remote = another
#         merge = refs/heads/itst
```

### 关于`git pull`

`git pull`基本上是先`git fetch`再`git merge FETCH_HEAD`；
`git pull --rebase`基本上是先`git fetch`再`git rebase FETCH_HEAD`。
由于这个命令高度不可控，非常不推荐使用。
然而`git pull --ff-only`却非常有用，是先`git fetch`再`git merge --ff-only FETCH_HEAD`。

## 总结

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
    - `git push -u <remote> <ref>`
  - 传输
    - `git push <remote> <local-ref>:<remote-ref>`
    - `git fetch <remote> <remote-ref>:<local-ref>`
  - 一键跟上进度
    - `git pull --ff-only`
  - 不推荐使用的邪恶命令
    - `git pull [--rebase]`

