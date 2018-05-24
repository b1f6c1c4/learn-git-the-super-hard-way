# 第1章：直接操纵对象

## 基础知识

Git对象放在`<repo>/objects/`中，分四种：
- blob：文件内容，本质是前缀和文件原文
- tree：文件夹内容，本质是经过zlib deflate处理的二进制数组，每个元素包括以下信息：
  - 类型（文件夹040000，普通文件100644，可执行文件100755）
  - 文件名
  - 对应文件（blob）或者文件夹（tree）的SHA1
- commit：本质是经过zlib deflate处理的以\n换行的纯文本，包括以下信息：
  - tree：代表根目录内容的tree的SHA1
  - parent(s)：其他commit的SHA1
  - author：姓名、邮箱、秒时间戳、时区
  - committer：姓名、邮箱、秒时间戳、时区
  - message：任意字节流
- tag：本质是经过zlib deflate处理的以\n换行的纯文本，包括以下信息：
  - object：给谁做标记，可以是任意对象的SHA1
  - type：object的类型
  - tag：标记名称
  - tagger：姓名、邮箱、秒时间戳、时区
  - message：任意字节流

本章所有命令都不涉及worktree。后续章节会介绍如何利用worktree来操纵对象（Lv3）。

由于纯手工执行zlib deflate压缩、计算SHA1确实太麻烦，本章不介绍Lv0的对象创建方案，
只介绍Lv1的方案（即使用`git hash-object`来完成上述过程）。

## 创建blob

- Lv1
```bash
echo 'hello' | git --git-dir=the-repo.git hash-object -t blob --stdin -w
# ce013625030ba8dba906f756967f9e9ca394464a
```

- Lv2
```bash
echo 'hello' > temp-file
git --git-dir=the-repo.git hash-object -t blob temp-file -w
# ce013625030ba8dba906f756967f9e9ca394464a
```

## 查看blob

- Lv0
```bash
# 注意：不可将gunzip的输出直接打印到控制台，否则会因为遇到\0而中止
printf '\x1f\x8b\x08\x00\x00\x00\x00\x00' \
| cat - the-repo.git/objects/ce/013625030ba8dba906f756967f9e9ca394464a \
| gunzip -dc 2>/dev/null | xxd
# 00000000: 626c 6f62 2036 0068 656c 6c6f 0a         blob 6.hello.
```

- Lv2
```bash
git --git-dir=the-repo.git cat-file blob ce00
# hello
```

- Lv3
```bash
# 将git show直接作用在blob上，等价于git cat-file blob
git --git-dir=the-repo.git show ce00
# hello
```

## 创建tree

- Lv1
```bash
(printf '100644 name.ext\x00';
echo '0: ce013625030ba8dba906f756967f9e9ca394464a' | xxd -rp -c 256;
printf '100755 name2.ext\x00';
echo '0: ce013625030ba8dba906f756967f9e9ca394464a' | xxd -rp -c 256) \
| git --git-dir=the-repo.git hash-object -t tree --stdin -w
# 58417991a0e30203e7e9b938f62a9a6f9ce10a9a
```

## 查看tree

- Lv0
```bash
# 注意：不可将gunzip的输出直接打印到控制台，否则会因为遇到\0而中止
printf '\x1f\x8b\x08\x00\x00\x00\x00\x00' \
| cat - the-repo.git/objects/58/417991a0e30203e7e9b938f62a9a6f9ce10a9a \
| gunzip -dc 2>/dev/null | xxd
# 00000000: 7472 6565 2037 3300 3130 3036 3434 206e  tree 73.100644 n
# 00000010: 616d 652e 6578 7400 ce01 3625 030b a8db  ame.ext...6%....
# 00000020: a906 f756 967f 9e9c a394 464a 3130 3037  ...V......FJ1007
# 00000030: 3535 206e 616d 6532 2e65 7874 00ce 0136  55 name2.ext...6
# 00000040: 2503 0ba8 dba9 06f7 5696 7f9e 9ca3 9446  %.......V......F
# 00000050: 4a                                       J```
```

- Lv1
```bash
git --git-dir=the-repo.git cat-file tree 5841 | xxd
# 00000000: 3130 3036 3434 206e 616d 652e 6578 7400  100644 name.ext.
# 00000010: ce01 3625 030b a8db a906 f756 967f 9e9c  ..6%.......V....
# 00000020: a394 464a 3130 3037 3535 206e 616d 6532  ..FJ100755 name2
# 00000030: 2e65 7874 00ce 0136 2503 0ba8 dba9 06f7  .ext...6%.......
# 00000040: 5696 7f9e 9ca3 9446 4a                   V......FJ
```

- Lv2
使用`git ls-tree`可以方便地看到文件夹的内容
```bash
git --git-dir=the-repo.git ls-tree 5841
# 100644 blob ce013625030ba8dba906f756967f9e9ca394464a    name.ext
# 100755 blob ce013625030ba8dba906f756967f9e9ca394464a    name2.ext
```

- Lv3
使用`git show`直接作用在tree上可以看到简化版的文件夹内容
```bash
git --git-dir=the-repo.git show 5841
# tree 5841
#
# name.ext
# name2.ext
```

## 创建commit

- Lv1
```bash
git --git-dir=the-repo.git hash-object -t commit --stdin -w <<EOF
tree 58417991a0e30203e7e9b938f62a9a6f9ce10a9a
author b1f6c1c4 <b1f6c1c4@gmail.com> 1514736000 +0800
committer b1f6c1c4 <b1f6c1c4@gmail.com> 1514736000 +0800

The commit message
May have multiple
lines!
EOF
# bce83a8c51fdad7b2e11155826b9794590950268
```

- Lv2
```bash
GIT_AUTHOR_NAME=b1f6c1c4 \
GIT_AUTHOR_EMAIL=b1f6c1c4@gmail.com \
GIT_AUTHOR_DATE='1600000000 +0800' \
GIT_COMMITTER_NAME=b1f6c1c4 \
GIT_COMMITTER_EMAIL=b1f6c1c4@gmail.com \
GIT_COMMITTER_DATE='1600000000 +0800' \
git --git-dir=the-repo.git commit-tree 5841 -p bce8 << EOF
Message may be read
from stdin
or by the option '-m'
EOF
# f9abcba958cf80eb717122e2486d825e6b150d9c
```

## 查看commit

- Lv0
```bash
# 注意：不可将gunzip的输出直接打印到控制台，否则会因为遇到\0而中止
printf '\x1f\x8b\x08\x00\x00\x00\x00\x00' \
| cat - the-repo.git/objects/f9/abcba958cf80eb717122e2486d825e6b150d9c \
| gunzip -dc 2>/dev/null | xxd
# 00000000: 636f 6d6d 6974 2032 3539 0074 7265 6520  commit 259.tree
# 00000010: 3538 3431 3739 3931 6130 6533 3032 3033  58417991a0e30203
# 00000020: 6537 6539 6239 3338 6636 3261 3961 3666  e7e9b938f62a9a6f
# 00000030: 3963 6531 3061 3961 0a70 6172 656e 7420  9ce10a9a.parent
# 00000040: 6263 6538 3361 3863 3531 6664 6164 3762  bce83a8c51fdad7b
# 00000050: 3265 3131 3135 3538 3236 6239 3739 3435  2e11155826b97945
# 00000060: 3930 3935 3032 3638 0a61 7574 686f 7220  90950268.author
# 00000070: 6231 6636 6331 6334 203c 6231 6636 6331  b1f6c1c4 <b1f6c1
# 00000080: 6334 4067 6d61 696c 2e63 6f6d 3e20 3136  c4@gmail.com> 16
# 00000090: 3030 3030 3030 3030 202b 3038 3030 0a63  00000000 +0800.c
# 000000a0: 6f6d 6d69 7474 6572 2062 3166 3663 3163  ommitter b1f6c1c
# 000000b0: 3420 3c62 3166 3663 3163 3440 676d 6169  4 <b1f6c1c4@gmai
# 000000c0: 6c2e 636f 6d3e 2031 3630 3030 3030 3030  l.com> 160000000
# 000000d0: 3020 2b30 3830 300a 0a4d 6573 7361 6765  0 +0800..Message
# 000000e0: 206d 6179 2062 6520 7265 6164 0a66 726f   may be read.fro
# 000000f0: 6d20 7374 6469 6e0a 6f72 2062 7920 7468  m stdin.or by th
# 00000100: 6520 6f70 7469 6f6e 2027 2d6d 270a       e option '-m'.
```

- Lv2
使用`git cat-tree`可以方便地看到commit本身的内容
```bash
git --git-dir=the-repo.git cat-file commit f9ab
# tree 58417991a0e30203e7e9b938f62a9a6f9ce10a9a
# parent bce83a8c51fdad7b2e11155826b9794590950268
# author b1f6c1c4 <b1f6c1c4@gmail.com> 1600000000 +0800
# committer b1f6c1c4 <b1f6c1c4@gmail.com> 1600000000 +0800
#
# Message may be read
# from stdin
# or by the option '-m'
```

- Lv3
使用`git show`直接作用在commit上可以看到commit本身及其tree的diff情况
```bash
git --git-dir=the-repo.git show f9ab~
# commit bce83a8c51fdad7b2e11155826b9794590950268
# Author: b1f6c1c4 <b1f6c1c4@gmail.com>
# Date:   Mon Jan 1 00:00:00 2018 +0800
#
#     The commit message
#
# diff --git a/name.ext b/name.ext
# new file mode 100644
# index 0000000..ce01362
# --- /dev/null
# +++ b/name.ext
# @@ -0,0 +1 @@
# +hello
# diff --git a/name2.ext b/name2.ext
# new file mode 100755
# index 0000000..ce01362
# --- /dev/null
# +++ b/name2.ext
# @@ -0,0 +1 @@
# +hello
```

## 从commit找到tree和blob

- Lv2
```bash
# 找到commit f9ab对应的tree：
# 注意：运行结果与手动写f9ab^{tree}无异
git --git-dir=the-repo.git ls-tree f9ab
# 100644 blob ce013625030ba8dba906f756967f9e9ca394464a    name.ext
# 100755 blob ce013625030ba8dba906f756967f9e9ca394464a    name2.ext
# 找到commit f9ab（对应的tree）的/name.ext：
git --git-dir=the-repo.git ls-tree f9ab -- name.ext
# 100644 blob ce013625030ba8dba906f756967f9e9ca394464a    name.ext
```

- Lv3
```bash
# 找到commit f9ab对应的tree：
# 注意：运行结果与只写f9ab有本质差异
git --git-dir=the-repo.git show f9ab^{tree}
# tree f9ab^{tree}
#
# name.ext
# name2.ext
# 找到commit f9ab（对应的tree）的/name.ext：
# 注意语法与git ls-tree完全不同：
# git ls-tree是给定一个tree，可选地根据路径找到另一个tree或者tree的行
# git show是给定一个对象，自动判断类型并展示
git --git-dir=the-repo.git show f9ab:name.ext
# hello
```

## 创建tag

- Lv1 模仿commit的创建方法即可创建

- Lv3
*特别注意：`git tag`命令不仅仅创建了tag对象，还建立了新的引用在`refs/tags/the-tag`。*
```bash
# 该命令没有输出
GIT_COMMITTER_DATE='1600000000 +0800' \
git --git-dir=the-repo.git tag -a -m 'The tag message' the-tag f9ab:name.ext
# 需要用如下命令找到新创建的对象
git --git-dir=the-repo.git rev-parse the-tag
# 9cb6a0ecbdc1259e0a88fa2d8ac4725195b4964d
```

## 查看tag

- Lv0 模仿commit的查看方法即可

- Lv2
```bash
git --git-dir=the-repo.git cat-file tag 9cb6
# object ce013625030ba8dba906f756967f9e9ca394464a
# type blob
# tag the-tag
# tagger b1f6c1c4 <b1f6c1c4@gmail.com> 1527189535 +0000
#
# The tag message
# 注意：如果想要查看tag指向的对象，只需要修改type即可：
git --git-dir=the-repo.git cat-file blob 9cb6
# hello
```

- Lv3
```bash
# 注意：git show同时显示tag本身和tag指向的对象的信息
git --git-dir=the-repo.git show 9cb6
# tag the-tag
# Tagger: b1f6c1c4 <b1f6c1c4@gmail.com>
# Date:   Sun Sep 13 20:26:40 2020 +0800
#
# The tag message
# hello
```

## 总结

- Lv1
  - `git hash-object -t <type> [--stdin|<file>] -w` - 创建对象
- Lv2
  - `git commit-tree <tree> -m <message> [-p <parent>]*` - 创建commit
  - `git cat-file <type> <SHA1>` - 查看blob和commit
  - `git ls-tree <SHA1> -- [<path>]` - 查看tree
- Lv3
  - `git tag -a -m <message> <name> <object>` - 同时创建新引用在`refs/tags/<name>`
  - `git show <commit>`
  - `git show <tree>` - 如`HEAD^{tree}`
  - `git show <blob>` - 如`HEAD:index.js`

