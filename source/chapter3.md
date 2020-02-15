# 第3章：直接操纵索引

## 基础知识

Git索引位于`<repo>/index`，本质是一个复杂的二进制文件。
具体格式参见[这里](https://github.com/git/git/blob/master/Documentation/technical/index-format.txt)，大概包括以下内容：
- 路径和文件名
- mode
- stage数（第6章讨论merge时会用到，正常情况为0）
- 修改时间
- 文件大小
- （其他标识文件唯一性的信息）
- 文件内容对应的blob的SHA1

由于直接修改该文件非常复杂，所以本章不介绍Lv0的方案。

如未提前说明，本章所有命令都需要`--git-dir`和`--work-tree`。
不过为了避免繁琐的`--git-dir`和`--work-tree`，本章所有命令都会在worktree里面执行：
```bash
cd default-tree
```
也就意味着忽略掉`--git-dir`和`--work-tree`也能正常工作。读者需要判断哪些命令可以不依赖`--work-tree`。

## 添加/修改index

- Lv1
```bash
# 注意：此处故意忽略掉-w，导致blob对象并没有被真正创建
echo 'content' | git hash-object -t blob --stdin
# d95f3ad14dee633a758d2e331151e950dd13e4ed
# blob不一定需要真正存在
git update-index --add --cacheinfo 100644,d95f3ad14dee633a758d2e331151e950dd13e4ed,dir/fn
```

- Lv2
```bash
# 要先有文件才能添加到index
mkdir dir
echo 'content' > dir/fn
# 以下命令只修改index，不创建blob
git update-index --add --info-only -- dir/fn
# 以下命令既修改index，也创建blob
git update-index --add -- dir/fn
```

若想手动改变mode，只需`git update-index --chmod +x -- <path>`

- Lv3
```bash
# 要先有文件才能添加到index
mkdir dir
echo 'content' > dir/fn
# 以下命令既修改index，也创建blob
git add -f dir/fn
```

如果想只添加一部分内容，使用`git add -p`

## 删除index

- Lv2
```bash
git update-index --force-remove -- dir/fn
```

- Lv3
```bash
git rm --cached -- dir/fn
```

## 移动index

没有简单办法。
Lv2方法，使用`git update-index --cacheinfo`无法指定文件stat信息
Lv3方法，使用`git mv`不仅移动了index还移动了worktree里的文件

## 复制index

没有简单办法。
Lv2方法，使用`git update-index --cacheinfo`无法指定文件stat信息

## 查看index

- Lv2
（其中0为stage数，正常情况为0）
```bash
git ls-files -s
# 100644 d95f3ad14dee633a758d2e331151e950dd13e4ed 0       dir/fn
git ls-files -s -- dir/
# 100644 d95f3ad14dee633a758d2e331151e950dd13e4ed 0       dir/fn
```

## 利用tree更新index

- Lv2
```bash
# 整个index替换掉
git read-tree 5841
# git ls-files -s
# 100644 ce013625030ba8dba906f756967f9e9ca394464a 0       name.ext
# 100755 ce013625030ba8dba906f756967f9e9ca394464a 0       name2.ext
# 合并到某个文件夹
git read-tree --prefix=dir/ 5841
# git ls-files -s
# 100644 d95f3ad14dee633a758d2e331151e950dd13e4ed 0       dir/fn
# 100644 ce013625030ba8dba906f756967f9e9ca394464a 0       dir/name.ext
# 100755 ce013625030ba8dba906f756967f9e9ca394464a 0       dir/name2.ext
# 注意特殊情况
git read-tree --prefix=dir/fn/ 5841
# git ls-files -s
# 100644 ce013625030ba8dba906f756967f9e9ca394464a 0       dir/fn/name.ext
# 100755 ce013625030ba8dba906f756967f9e9ca394464a 0       dir/fn/name2.ext
```

- Lv3
```bash
# 整个index替换掉
git restore --source 5841 --staged -- :/
# 替换掉某个文件夹
git restore --source 5841 --staged -- dir/
# 以下为等价的旧语法
# git reset 5841 -- :/
# git reset 5841 -- dir/
```

## 利用index更新worktree

注意：添加修改都可以，但是无法删除worktree里面多出来的文件。
请参阅本章最后一节（`git clean`）。

- Lv2
```bash
# 整个worktree替换掉
git checkout-index -fu -a
# 全部加前缀（不必是文件夹路径）
git checkout-index --prefix -fu -a
# 只有一部分文件
git checkout-index -fu -- dir/fn
```

- Lv3
```bash
# 整个worktree替换掉
git restore --worktree -- :/
# 只有一部分文件
git restore --worktree -- dir/fn
# 以下为等价的旧语法
# git checkout -f -- :/
# git checkout -f -- dir/fn
```

## 利用index创建tree

- Lv2
```bash
# 用整个index创建tree
git write-tree
# 6e3eae41f3af12d20b09a136d3e20b2d862aacfc
# 用一个子目录创建tree
git write-tree --prefix=dir/
# 264fb87379112c8d2b5b04f91fefc48e25959206
```
注意：当存在非0的stage数时（一般是由`git read-tree -m`导致的，见第6章），`git write-tree`会失败

- Lv3
注意：`git commit`创建tree并创建commit
```bash
git commit --allow-empty -m 'The message'
```

## 利用tree更新worktree

- Lv1
```bash
# 准备：
echo 0 >f
git add f
git commit -m '0'
echo 1 >f
git add f
echo 2 >f
# 执行：
git cat-file blob HEAD:f >f
# 检查：
git cat-file blob $(git ls-files -s -- f | awk '{ print $2; }')
cat f
```

- Lv3
```bash
# 准备：
echo 0 >f
git add f
git commit -m '0'
echo 1 >f
git add f
echo 2 >f
# 执行：
git restore --source HEAD --worktree -- f
# 检查：
git cat-file blob $(git ls-files -s -- f | awk '{ print $2; }')
cat f
```

## 利用tree同时更新index和worktree

- Lv2
一步一步来即可

- Lv3
```bash
# 准备：
echo 0 >f
git add f
git commit -m '0'
echo 1 >f
git add f
echo 2 >f
# 执行：
git restore --source HEAD --index --worktree -- f
# 检查：
git cat-file blob $(git ls-files -s -- f | awk '{ print $2; }')
cat f
```

注意：`git restore --worktree`没有对应的旧语法。

## 详解`git restore`

- `git restore [--source <tree-ish>] [--staged] [--worktree] -- <path>`
  - 若`<tree-ish>`留空：
    - 不写`--staged`也不写`--worktree`：`<tree-ish>`表示index
    - `--worktree`：`<tree-ish>`表示index
    - `--staged --worktree`：`<tree-ish>`表示index，而`--staged`被忽略了
    - `--staged`：`<tree-ish>`表示HEAD
  - 不写`--staged`也不写`--worktree`则默认`--worktree`

等价旧语法：
- `git restore [--worktree] -- <path>`=`git checkout -f -- <path>`
- `git restore --staged --worktree -- <path>`=`git checkout -f -- <path>`
- `git restore [--source <tree-ish>] --staged -- <path>`=`git reset [<tree-ish>] -- <path>`
- `git restore --source <tree-ish> --staged --worktree -- <path>`=`git checkout -f <tree-ish> -- <path>`
- `git restore --source <tree-ish> [--worktree] -- <path>` 没有等价的旧语法！

## 交互式修改index

有时候我们希望将一个文件的部分更改放入index中，此时使用`git add -p`即可。
如果不小心放多了，使用`git restore -p`即可。（旧语法`git reset -p`）

## 删除worktree中多出来的文件（`git clean`）

**警告：该命令十分危险，可能一瞬删掉你的全部心血！**

```bash
touch extra
# 检查多出来了什么文件
git clean -nd
# 统统删掉
git clean -fd
```

把以下命令的`-n`换成`-f`就能真正删掉文件了
（**非常危险，请一定先`git clean -n`看看什么会消失再真的去`-f`**）：
```bash
echo 'fff' >.gitignore
git add .gitignore
touch fff
touch extra
# 准备删掉多出来的non-ignored文件
git clean -nd
# 准备删掉多出来的所有文件
git clean -ndx
# 准备删掉多出来的ignored文件
git clean -ndX
```

## 总结

- Lv1
  - `git update-index --add --cacheinfo <mode>,<SHA1>,<path>`
- 不常用Lv2
  - `git update-index --add [--info-only] -- <path>`
  - `git update-index --force-remove -- <path>`
  - `git checkout-index -fu [--prefix=<pf>] -a`
  - `git checkout-index -fu [--prefix=<pf>] -- <path>`
- 常用Lv2
  - `git update-index --chmod +x -- <path>`
  - `git ls-files -s`
  - `git ls-files -s -- <path>`
  - `git read-tree [--prefix=<pf>] <tree-ish>`
  - `git write-tree [--prefix=<pf>]`
- Lv3
  - `git add -f -- <path>`
  - `git rm --cached -- <path>`
  - `git mv`
  - `git restore [--source <tree-ish>] [--staged] [--worktree] -- <path>`
  - `git commit`
  - `git clean -nd [-x|-X] [-- <path>]`（把`-n`换成`-f`就会真的删除，**非常危险**）
- 交互式修改index
  - `git add -p`
  - `git restore -p`

