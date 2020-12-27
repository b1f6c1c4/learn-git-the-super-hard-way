考虑如下场景：开发一个**中型、小型或者微型**微服务系统，包含10个组件

方案1：（多repo）创建10个git repo，每个repo一个master一个dev

方案2：（单repo单分支）创建1个git repo，设一个master一个dev

方案3：（单repo多分支）创建1个git repo，弃用master，每个组件单设自己的master和dev等等

| | 方案1 | 方案2 | 方案3 |
| --- | --- | --- | --- |
| 环境配置简易程度 | -------- | ++++++++ | --- |
| 空间独立（同时修改不同组件是否可行） | ++++++++ | -------- | ++++++++ |
| 时间对齐（组件版本是否能够统一） | -------- | ++++++++ | +++++ |
| 组件之间可以互相参照 | -------- | ++++++ | ++++++++ |
| 添加删除组件是否方便 | ++++++++ | -------- | +++++++ |

由此可见，微型项目方案2最优，小型和中型项目方案3最优。
方案3可能存在的问题是：

- 时间对齐无法实现：不存在的，参考下文
- 需要频繁checkout：不存在的，参考下文
- 单个git库过大：不存在的，我已经假设了是**中小型**系统

# 单repo多分支工作流的分支设置

对于小型项目，推荐按以下方式配置分支：

- doc
  - 全部系统设计文档
- master
  - 通过merge componentX整合系统各个部分
- component1
  - 通过merge doc取得与之相关的部分设计文档
- component2
  - 通过merge doc取得与之相关的部分设计文档
- component3
  - 通过merge doc取得与之相关的部分设计文档
- component4
  - 通过merge doc取得与之相关的部分设计文档
- ...

对于中型项目，推荐按以下方式配置分支：

- doc
  - 系统总体设计文档，组件接口文档
- master
  - 在测试稳定后，merge dev
- release
  - 发布之前merge master
- dev
  - 通过merge componentX/master整合系统各个部分
  - 此处进行集成测试
- component1/doc
  - 通过merge doc取得系统总体文档，并添加组件内部设计文档
- component1/master
  - 在测试稳定后，merge component1/dev
- component1/dev
  - 在功能开发完毕后，merge component1/featY
- component1/feat1
  - 在此处开发具体功能
- component1/feat2
  - 在此处开发具体功能
- component1/feat3
  - 在此处开发具体功能
- component2/doc
  - 通过merge doc取得系统总体文档，并添加组件内部设计文档
- component2/master
  - 在测试稳定后，merge component2/dev
- component2/dev
  - 在功能开发完毕后，merge component2/featY
- component2/feat1
  - 在此处开发具体功能
- component2/feat2
  - 在此处开发具体功能
- component2/feat3
  - 在此处开发具体功能
- ...

# 单repo多分支工作流的具体操作

需要注意的是，不同component分支上的worktree完全不同，互相独立，绝对不能够互相merge，也不能共享同一个worktree；
而同一component里面各个小分支的worktree基本一致，只是有开发先后关系（类似于单体应用的不同分支），适合互相merge，也一般共享同一个worktree。

## 创建

首先创建repo，不连带创建worktree：
```bash
mkdir the-project
git init --bare the-project/the-project.git
# Initialized empty Git repository in /root/the-project/the-project.git/
# git -C the-project/the-project.git remote add origin https://github.com/...
```

然后给doc和每一个component分别创建一个（小repo和）worktree：
```bash
cd the-project/the-project.git
# 由于git worktree实在太蠢，这里搞一个workaround
git hash-object -t commit -w --stdin <<EOF
tree 0000000000000000000000000000000000000000

EOF
# 60bc2812cc97ab2d2f2c7168aa101f7bfabcbf88
git update-ref refs/workaround 60bc2812cc97ab2d2f2c7168aa101f7bfabcbf88
git worktree add --no-checkout --detach ../doc refs/workaround
# Preparing worktree (detached HEAD 60bc281)
git --git-dir=worktrees/doc symbolic-ref HEAD refs/heads/doc
git worktree add --no-checkout --detach ../component1 refs/workaround
# Preparing worktree (detached HEAD 60bc281)
git --git-dir=worktrees/component1 symbolic-ref HEAD refs/heads/component1
git worktree add --no-checkout --detach ../component2 refs/workaround
# Preparing worktree (detached HEAD 60bc281)
git --git-dir=worktrees/component2 symbolic-ref HEAD refs/heads/component2
git worktree add --no-checkout --detach ../component3 refs/workaround
# Preparing worktree (detached HEAD 60bc281)
git --git-dir=worktrees/component3 symbolic-ref HEAD refs/heads/component3
git worktree add --no-checkout --detach ../component4 refs/workaround
# Preparing worktree (detached HEAD 60bc281)
git --git-dir=worktrees/component4 symbolic-ref HEAD refs/heads/component4
git update-ref -d refs/workaround
rm -f objects/60/bc2812cc97ab2d2f2c7168aa101f7bfabcbf88
```

## 从其他地方clone

不建议使用`git clone --bare`，因为还需要手工修改fetch信息（参考第5章，这种方式创建的repo默认没有fetch的config项）

建议按上述方法创建，然后再remote add。

## doc分支

直接在根目录（`the-project/doc`）下写文档即可：
```bash
cd the-project/doc
echo 'Some documents' > documents.txt
git add documents.txt
git hash-object -t commit --stdin -w <<EOF
tree $(git write-tree)
author b1f6c1c4 <b1f6c1c4@gmail.com> 1514736000 +0800
committer b1f6c1c4 <b1f6c1c4@gmail.com> 1514736000 +0800

Write documents
EOF
# ffe7520ba83e48bb254b9eb0fd07390d98124ede
git reset --soft ffe7520b
```

## component分支

首先配置开发环境（这里以c++为例）：
```bash
cd the-project/component1
echo 'build/' > .gitignore
cat - >Makefile <<EOF
build/component1: main.cpp
	g++ -std=2a -o $@ $^
EOF
git add .gitignore Makefile
git hash-object -t commit --stdin -w <<EOF
tree $(git write-tree)
author b1f6c1c4 <b1f6c1c4@gmail.com> 1514736010 +0800
committer b1f6c1c4 <b1f6c1c4@gmail.com> 1514736010 +0800

Setup environment
EOF
# 4dbe0f181e875f7a96b3f6079038d353c239a6f4
git reset --soft 4dbe0f1
```

然后从doc分支读取文档：
```bash
cd the-project/component1
# git rm -rf doc/
git read-tree --prefix=doc/ doc
git checkout-index -fua
git hash-object -t commit --stdin -w <<EOF
tree $(git write-tree)
parent $(git rev-parse HEAD)
parent $(git rev-parse doc)
author b1f6c1c4 <b1f6c1c4@gmail.com> 1514736010 +0800
committer b1f6c1c4 <b1f6c1c4@gmail.com> 1514736010 +0800

Merge branch doc
EOF
# 9f1f329f771711c7160c0784d4cf8a7f157d5c27
git reset --soft 9f1f329
```

## 文档更新以后各component的处理

假设文档在doc更新了：
```bash
cd the-project/doc
git rm -f documents.txt
# rm 'documents.txt'
echo 'New documents' > new-documents.txt
git add new-documents.txt
git hash-object -t commit --stdin -w <<EOF
tree $(git write-tree)
parent $(git rev-parse HEAD)
author b1f6c1c4 <b1f6c1c4@gmail.com> 1514736000 +0800
committer b1f6c1c4 <b1f6c1c4@gmail.com> 1514736000 +0800

Move to new documents
EOF
# 9584d01267d5f16c581e521d3bb401f211508eee
git reset --soft 9584d012
```

那么需要在component1分支更新文档：
```bash
cd the-project/component1
git rm -rf doc/
# rm 'doc/documents.txt'
git read-tree --prefix=doc/ doc
git checkout-index -fua
git hash-object -t commit --stdin -w <<EOF
tree $(git write-tree)
parent $(git rev-parse HEAD)
parent $(git rev-parse doc)
author b1f6c1c4 <b1f6c1c4@gmail.com> 1514736010 +0800
committer b1f6c1c4 <b1f6c1c4@gmail.com> 1514736010 +0800

Merge branch doc
EOF
# 7ad8da3b9f5825c63247bf655ef6da68b637453b
git reset --soft 7ad8da3
git config alias.lg "log --graph --pretty=tformat:'%h -%d (%an/%cn) %s' --abbrev-commit"
git lg
# *   7ad8da3 - (HEAD -> component1) (b1f6c1c4/b1f6c1c4) Merge branch doc
# |\  
# | * 9584d01 - (doc) (b1f6c1c4/b1f6c1c4) Move to new documents
# * | 9f1f329 - (b1f6c1c4/b1f6c1c4) Merge branch doc
# |\| 
# | * ffe7520 - (b1f6c1c4/b1f6c1c4) Write documents
# * 4dbe0f1 - (b1f6c1c4/b1f6c1c4) Setup environment
```

## master

master之于component，就是component之于doc；
唯一区别是一个master会merge多个compoent，而且master上自身代码很少
（可能只有README.md、LICENSE、docker-compose.yml等等全局配置）。

和component完全一致，在master上依次read-tree、write-tree、commit-tree，
就可以将不同组件整合到master上。
别忘了多加几个parent。

# FAQ

## master要不要直接merge doc

如果在master上进行一些集成测试，那么应该有doc。
否则可以省略。

## 为什么不用简单方便的`git merge -s subtree doc`

一些诡异的情况下subtree无法完整地复制doc那边的整个tree的情况，
比如删掉的文件还在、新添加的文件没有出现等等。
参考第6章。

## 我应该在哪里build

一般来说应该在每个组件各自的worktree里面build，
比如`node_modules`、`*.o`、`*.pyc`等等。
如果采用docker，那么每个组件分支上应该能生成一个image，
而到了master里面就直接`docker-compose up`了。

如果出于ci的需要，也可以选择在master里面再次build。但这就需要双倍的磁盘空间。

## 如何简化操作

参见第8章。另外别忘了`git push --all`，`git log --all`等等。
