# 第6章：直接操纵merge

## 基础知识

从物理结构上讲，一个commit表示一个完整的版本；
但是，从逻辑结构上讲，一个commit还可以表示 *相比于之前进行了哪些修改* 。

本章中涉及worktree的命令会明确标出。

```bash
git init --separate-git-dir "$PWD" ../default-tree
```

## 查看更改

在开始之前，先创建几个对象：
```bash
echo '1' | git hash-object -t blob --stdin -w
echo '2' | git hash-object -t blob --stdin -w
echo '3' | git hash-object -t blob --stdin -w
echo '4' | git hash-object -t blob --stdin -w
echo '5' | git hash-object -t blob --stdin -w
echo '6' | git hash-object -t blob --stdin -w
echo '7' | git hash-object -t blob --stdin -w
git mktree <<EOF
100644 blob d00491fd7e5bb6fa28c517a0bb32b8b506539d4d$(printf '\t')1.txt
100755 blob 0cfbf08886fca9a91cb753ec8734c84fcbe52c9f$(printf '\t')2.txt
EOF
git mktree <<EOF
100644 blob d00491fd7e5bb6fa28c517a0bb32b8b506539d4d$(printf '\t')1.txt
100755 blob 00750edc07d6415dcc07ae0351e9397b0222b7ba$(printf '\t')3.txt
EOF
git hash-object -t commit --stdin -w <<EOF
tree a237e8338c09e7d1b2f9749f73f4f583f19fc626
author b1f6c1c4 <b1f6c1c4@gmail.com> 1514736000 +0800
committer b1f6c1c4 <b1f6c1c4@gmail.com> 1514736000 +0800

1=1 2=2
EOF
git hash-object -t commit --stdin -w <<EOF
tree aa250e2798646facc12686e4403ccadbf1565d51
parent 4cfe841426d0435270d049625a766130c108f4c8
author b1f6c1c4 <b1f6c1c4@gmail.com> 1514736000 +0800
committer b1f6c1c4 <b1f6c1c4@gmail.com> 1514736000 +0800

1=1 3=3
EOF
```

- Lv2

基于第一个tree-ish，查看第二个tree-ish的修改：
```bash
git diff-tree a237 aa25
git diff-tree a237 aa25 -- 2.txt
git diff-tree afc3
```

基于tree-ish，查看index的修改：
```bash
git read-tree a237
git diff-index --cached aa25
```

基于tree-ish，查看worktree的修改：
```bash
rm -rf ../default-tree/*
git --work-tree=../default-tree diff-index aa25
```

基于index，查看worktree的修改：
```bash
git --work-tree=../default-tree diff-files
```

- Lv3

* `git diff <tree-ish> <tree-ish> -- [<path>]` 相当于 `git diff-tree -p <tree-ish> <tree-ish> -- [path]`
* `git show <commit-ish> -- [<path>]` 相当于 `git diff-tree -p <commit-ish> -- [<path>]`
* `git diff [<tree-ish>] -- [<path>]` 相当于 `git diff-index -p [<tree-ish>] -- [<path>]`
* `git diff --cached [<tree-ish>] -- [<path>]` 相当于 `git diff-index -p --cached [<tree-ish>] -- [<path>]`
* `git diff -- <path>` 相当于 `git diff-files -p <path>`

## 处理修改

类似于`git bundle create`将若干对象打包成字节流以便离线传送，`git diff-* -p|--patch`将修改打包成字节流以便离线传送。
类似于`git bundle unbundle`将字节流解包成对象，`git apply`将字节流解包出修改。
需要注意的是，`--patch`产生的是human-readable data，但`git bundle`是machine-readable only。

打包修改：
```bash
git diff-tree --patch a237 aa25 | tee ../the.patch
```

解包修改至worktree:
```bash
rm -rf ../default-tree/*
git read-tree a237
git --work-tree=../default-tree checkout-index -fu -a
ls ../default-tree
git -C ../default-tree apply ../the.patch
ls ../default-tree
git ls-files -s
```

解包修改至index：
```bash
git ls-files -s
git apply --cached ../the.patch
git ls-files -s
ls ../default-tree
```

## Merge相关概念简介

Merge是git里面最为复杂也最为重要的部分。
在具体讲解每一个命令之前，先看一下Lv2的big picture：

- 同一份文件，已知原始版本，如何把两人独自进行的修改整合？
  - 出现冲突时以我方为准：`git merge-file --ours C A B`
  - 出现冲突时以对方为准：`git merge-file --theirs C A B`
  - 出现冲突时串联起来：`git merge-file --union C A B`
  - 出现冲突时做出标记，手工解决：`git merge-file C A B`
  - 采用其他工具：（略）
- 同一个tree，已知原始版本，如何把两人独自进行的修改在文件层面上整合？（不涉及文件内容）
  - `git merge-tree C A B`
- 同一个tree，已知原始版本，对方修改以后，如何把我尚未完善的修改建立在别人的基础上？
  - `git read-tree -m H M`
- 同一个tree，已知原始版本，如何把两人独自进行的修改整合？
  - 先解决最简单的冲突，保留复杂冲突的完整信息：`git read-tree -m A C B`
  - 试着解决最简单的几种冲突：`git merge-index git-merge-one-file`
- 同一个tree，已知原始版本，如何把多人独自进行的修改整合？
  - 多次执行`git read-tree -m A C B`即可

## 3-Way merge基本概念之文件层面的`git merge-file`

重要Lv2工具`git merge-file`（无需git dir也无需worktree）：
```bash
cat >fileA <<EOF
lineB
...some stuff...
lineC
EOF
cat >fileB <<EOF
lineBB
...some stuff...
lineC
EOF
cat >fileC <<EOF
lineB
...some stuff...
lineCC
EOF
cat >fileD <<EOF
lineBD
...some stuff...
lineC
EOF
# 计算 fileC + (fileB - fileA)
git merge-file --stdout fileC fileA fileB
```

在遇到冲突的情况下，标记出来手工解决：
```bash
git merge-file --stdout fileD fileA fileB
git merge-file --stdout --diff3 fileD fileA fileB
```

在遇到冲突的情况下，自动解决：
```bash
git merge-file --stdout --our fileD fileA fileB
git merge-file --stdout --their fileD fileA fileB
git merge-file --stdout --union fileD fileA fileB
```

### tree层面：`git merge-tree`

在开始之前，先创建几个对象：
```bash
git mktree <<EOF
100644 blob d00491fd7e5bb6fa28c517a0bb32b8b506539d4d$(printf '\t')1.txt
100755 blob 0cfbf08886fca9a91cb753ec8734c84fcbe52c9f$(printf '\t')2.txt
100755 blob b8626c4cff2849624fb67f87cd0ad72b163671ad$(printf '\t')4.txt
EOF
git hash-object -t commit --stdin -w <<EOF
tree 5de99716b8dd347ce09718e5f628b8c78e656b8c
parent 4cfe841426d0435270d049625a766130c108f4c8
author b1f6c1c4 <b1f6c1c4@gmail.com> 1514736000 +0800
committer b1f6c1c4 <b1f6c1c4@gmail.com> 1514736000 +0800

1=1 2=2 4=4
EOF
```

`git merge-tree C A B`的意义是`(C+(B-A))-C`，参见以下示例
```bash
git ls-tree a237
git ls-tree aa25
git ls-tree 5de9
git merge-tree 5de9 a237 aa25
git merge-tree 5de9 aa25 a237
git merge-tree a237 aa25 5de9
```

当同时存在tree层面和文件层面的修改时，参见以下示例
```bash
# 注意：3.txt包含的是"4"
git mktree <<EOF
100644 blob d00491fd7e5bb6fa28c517a0bb32b8b506539d4d$(printf '\t')1.txt
100755 blob b8626c4cff2849624fb67f87cd0ad72b163671ad$(printf '\t')3.txt
EOF
# merge-tree产生非常规输出（removed in local），暗示需要处理冲突
git merge-tree 47e3 a237 aa25
```

### `git read-tree -m`的Two Tree Merge

`git read-tree -m <tree-ish-H> <tree-ish-M>`试图执行`index=index+(M-H)`。
对于每一个文件，考虑到H、M、index、worktree四处的状态，有22种具体情况，具体处置方法如下表所示（0表示不存在，不同小写字母表示不同版本）（摘自`man git-read-tree`）：

| 编号 | worktree | index | H | M | 处置 |
| --- | --- | --- | --- | --- | --- |
| 0 | . | 0 | 0 | 0 | 0 | keep |
| 1 | . | 0 | 0 | m | index = m |
| 2 | . | 0 | h | 0 | index = 0 |
| 3a | . | 0 | h | h | *SEE NOTE* |
| 3b | . | 0 | h | m | fail |
| 4 | i | i | 0 | 0 | keep |
| 5 | w | i | 0 | 0 | keep |
| 6 | m | m | 0 | m | keep |
| 7 | w | m | 0 | m | keep |
| 8 | i | i | 0 | m | fail |
| 9 | w | i | 0 | m | fail |
| 10 | h | h | h | 0 | index = 0 |
| 11 | w | h | h | 0 | fail |
| 12 | i | i | h | 0 | fail |
| 13a | h | i | h | 0 | fail |
| 13b | w | i | h | 0 | fail |
| 14 | h | h | h | h | keep |
| 15 | w | h | h | h | keep |
| 16 | i | i | h | m | fail |
| 17a | h | i | h | m | fail |
| 17b | m | i | h | m | fail |
| 17c | w | i | h | m | fail |
| 18 | m | m | h | m | keep |
| 19a | h | m | h | m | keep |
| 19b | w | m | h | m | keep |
| 20 | h | h | h | m | index = m |
| 21a | m | h | h | m | fail |
| 21b | w | h | h | m | fail |

对于3a，如果index全空，则执行index=m；若index非空，则keep。

举例如下：
```bash
rm -rf ../default-tree/*
git read-tree 5de9
# 此处要加-u，来确保index和worktree在stat意义下一致
git --work-tree=../default-tree checkout-index -fu -a
git ls-files -s
ls ../default-tree
git ls-tree a237
git ls-tree aa25
git --work-tree=../default-tree read-tree -m a237 aa25
git ls-files -s
ls ../default-tree
# 总结：
# 1.txt hhhh -> keep (#14)
# 2.txt hhh0 -> index = 0 (#10)
# 3.txt 000m -> index = m (#1)
# 4.txt ii00 -> keep (#4)
```

### `git read-tree -m`的3-Way Merge

`git read-tree -m [--aggressive] <tree-ish-A> <tree-ish-C> <tree-ish-B>`的意思是：

* 清空index
* stage数=1，读取`<tree-ish-A>`至index
* stage数=2，读取`<tree-ish-C>`至index
* stage数=3，读取`<tree-ish-B>`至index
* 按下表变换（表中use表示删掉stage123的，创建一个新的stage0条目），若不能变换则不处理

| `--aggressive` | stage1 | stage2 | stage3 | 操作 |
| --- | --- | --- | --- | --- |
| any | a | a | a | use a |
| any | a | x | x | use x |
| any | a | a | b | use b |
| any | a | c | a | use c |
| required | a | 0 | a | use 0 |
| required | a | a | 0 | use 0 |
| required | a | 0 | 0 | use 0 |
| required | 0 | x | x | use x |

举例如下：
```bash
git ls-tree a237
git ls-tree 47e3
git ls-tree aa25
rm -rf ../default-tree/*
git read-tree 47e3
git --work-tree=../default-tree checkout-index -fu -a
git --work-tree=../default-tree read-tree -m a237 47e3 aa25
# 此时可以看见非0的stage数
git ls-files -s
# 总结：
# 1.txt aaa, collapse
# 2.txt a00, non-collapse
# 3.txt 0cb, non-collapse
# 此时无法write-tree：
git write-tree
git --work-tree=../default-tree checkout-index --stage=all -f --all
```

### `git merge-index`和`git merge-one-file`

前述`git read-tree`只解决了最最简单的冲突。为了解决更多冲突，要么手工编辑好再`git update-index`或者`git add`，要么采用自动化工具。

`git merge-index`负责调用其他工具：
```bash
# 注意空格
git merge-index echo -a
```

一种（没有卵用的）操作是调用自带工具`git-merge-one-file`：
```bash
rm -rf ../default-tree/*
git read-tree 47e3
git --work-tree=../default-tree checkout-index -fu -a
git --work-tree=../default-tree read-tree -m --aggressive a237 47e3 aa25
git ls-files -s
# 这个自带工具非常弱，解决不了什么问题，真心不比--aggressive强多少
git --work-tree=../default-tree merge-index git-merge-one-file -a
```

注意：若提示错误
`fatal: unable to read blob object e69de29bb2d1d6434b8b29ae775ad8c2e48c5391`
则执行
`printf '' | git hash-object --stdin -w`

* 问题：在使用外部工具的情况下，有没有更好的解决冲突的办法？
* 回答：有，即著名的recursive merge。但是由于该算法非常复杂，没有Lv2命令。此处不介绍Lv1实现，而只介绍Lv3的使用方法。

## 原始版本的选择：`git merge-base`

为了减少花在查找原始版本（A）的努力，`git merge-base -a <commit>*`可以直接计算出多个commit的极近公共祖先（在偏序关系下没有“最”，只能有“极”）。

```bash
git merge-base -a afc3 d2b7
```

## Lv3

`git merge -s <strategy>`（除了recursive、subtree、ours以外）实际上就是调用`git merge-<strategy>`。

而所谓的subtree merge，本质上就是subtree shift非空的recursive merge。
git会自动计算给B添加的prefix，但也可以通过`-Xsubtree=`来手动指定。

`git merge-resolve --no-ff --no-commit`实际上就是
（参见[`git-merge-resolve`源码](https://github.com/git/git/blob/master/git-merge-resolve.sh)）
- （需要手工指定C）
- 先执行`git read-tree -u -m --aggressive A C B`
- 再执行`git merge-index -o git-merge-one-file -a`
- 在git dir中生成`MERGE_HEAD` `MERGE_MODE` `MERGE_MSG`三个文件

`git merge-octopus --no-ff --no-commit`实际上就是
（参见[`git-merge-octopus`源码](https://github.com/git/git/blob/master/git-merge-octopus.sh)）
- 用`git merge-base`算出C
- 先执行`git read-tree -u -m --aggressive A C B`
- 再执行`git merge-index -o git-merge-one-file -a`
- 对其他分支重复以上过程
- 在git dir中生成`MERGE_HEAD` `MERGE_MODE` `MERGE_MSG`三个文件

`git merge --no-ff --no-commit - ours`实际上就是
- 关于index，什么也不做
- 在git dir中生成`MERGE_HEAD` `MERGE_MODE` `MERGE_MSG`三个文件

`git merge --no-ff --no-commit -s recursive`的基本思路是
（参见`man git-merge`）
- 先用`git merge-base --all`找到所有可能的C
- 把这些C先行merge一下得到C'
- 考虑重命名，对A C' B进行3-way merge
关于recursive，还有很多的参数可以调节，比如
- `-Xours`类似于`git merge-file --ours`
- `-Xtheirs`类似于`git merge-file -theirs`
- `-Xsubtree`指定给B加什么前缀再进行recursive merge

若有`--ff`则表明：若A=C或A=B，则不做任何事情。

若有`--no-commit`则表示：若无冲突，则自动执行`git commit`

需要注意的是，在`MERGE_HEAD`等文件存在时，`git commit`调用`git commit-tree`时会自动带上几个`-p`参数，生成多个parent的commit，其中第1个parent是HEAD，余下的是`MERGE_HEAD`的内容，也即`git merge`的参数。

## Lv4

由于很多时候我们希望主动控制要不要创建merge commit（也即手动决定`--ff-only`或者`--no-ff`，且希望在commit之前仔细检查合并是否正确（如跑单元测试），故本文建议使用如下alias：
```
alias.mf=merge --ff-only
alias.mnf=merge --no-ff
alias.mnfnc=merge --no-ff --no-commit
```

其中`git mf`用于`git fetch`之后，`git mnf`用于日常merge其他简单分支，而`git mnfnc`用于尝试merge（也即`git read-tree -u -m`）、跑单元测试再commit的情况。

## Lv5

有一类merge情况是，需要用其他分支 *完全取代* 当前分支的某一目录。（第8章整章建立在此基础之上）
然而，即便`git merge --no-ff -s subtree -Xsubtree=<prefix>`有时也会出错（毕竟是`git read-tree -m`）。

采用以下脚本即可解决：
```sh
git-mnfss() {
  git rm --cached -r -- $1
  git read-tree --prefix $1/ $1
  git checkout-index -fua
  git clean -f -- $1
  git reset --soft $(echo "Merge branch $1" | git commit-tree $(git write-tree) -p HEAD -p $1)
}
```

## 总结

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

