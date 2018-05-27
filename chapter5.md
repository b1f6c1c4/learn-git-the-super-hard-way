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
（复杂与之不相上下的还有`git filter-branch`、`git merge-tree`）。

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

## 跨域对象传输

TODO

## 跨域引用传输

TODO

## Lv3命令

TODO

### 总结

- Packfile
  - `git rev-list --objects <object> | git pack-objects <path-prefix>`
  - `git unpack-objects`

