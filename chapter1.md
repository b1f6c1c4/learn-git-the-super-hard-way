# 基础知识

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
  - mergetag(s)：见第13章
  - gpgsig：见第13章
  - message：任意字节流
- tag：本质是经过zlib deflate处理的以\n换行的纯文本，包括以下信息：
  - object：给谁做标记，可以是任意对象的SHA1
  - type：object的类型
  - tag：标记名称
  - tagger：姓名、邮箱、秒时间戳、时区
  - message：任意字节流
  - signature：见第13章

本章所有命令都不涉及worktree。后续章节会介绍如何利用worktree来操纵对象（Lv3）。

由于纯手工执行zlib deflate压缩、计算SHA1确实太麻烦，本章不介绍Lv0的对象创建方案，
只介绍Lv1的方案（即使用`git hash-object`来完成上述过程）。

```bash
git init --bare .
# Initialized empty Git repository in /root/
```

# 创建blob

- Lv1

```bash
echo 'hello' | git hash-object -t blob --stdin -w
# ce013625030ba8dba906f756967f9e9ca394464a
```

- Lv2

```bash
echo 'hello' > temp-file
git hash-object -t blob temp-file -w
# ce013625030ba8dba906f756967f9e9ca394464a
```

# 查看blob

- Lv0

```bash
# 注意：不可将gunzip的输出直接打印到控制台，否则会因为遇到\0而中止
printf '\x1f\x8b\x08\x00\x00\x00\x00\x00' \
| cat - ./objects/ce/013625030ba8dba906f756967f9e9ca394464a \
| gunzip -dc 2>/dev/null | xxd
# 00000000: 626c 6f62 2036 0068 656c 6c6f 0a         blob 6.hello.
```

- Lv2

```bash
git cat-file blob ce01
# hello
```

- Lv3

```bash
# 将git show直接作用在blob上，等价于git cat-file blob
git show ce01
# hello
```

# 创建tree

- Lv1
注意：要先对文件名排序，再使用`git hash-object`

```bash
(printf '100644 name.ext\x00';
echo '0: ce013625030ba8dba906f756967f9e9ca394464a' | xxd -rp -c 256;
printf '100755 name2.ext\x00';
echo '0: ce013625030ba8dba906f756967f9e9ca394464a' | xxd -rp -c 256) \
| git hash-object -t tree --stdin -w
# 58417991a0e30203e7e9b938f62a9a6f9ce10a9a
```

- Lv2
*注意：SHA1和文件名之间必须用tab分隔*，在命令行里输入tab的方法是`<Ctrl-v><Tab>`

```bash
git mktree --missing <<EOF
100644 blob ce013625030ba8dba906f756967f9e9ca394464a$(printf '\t')name.ext
100755 blob ce013625030ba8dba906f756967f9e9ca394464a$(printf '\t')name2.ext
EOF
# 58417991a0e30203e7e9b938f62a9a6f9ce10a9a
```

# 查看tree

- Lv0

```bash
# 注意：不可将gunzip的输出直接打印到控制台，否则会因为遇到\0而中止
printf '\x1f\x8b\x08\x00\x00\x00\x00\x00' \
| cat - ./objects/58/417991a0e30203e7e9b938f62a9a6f9ce10a9a \
| gunzip -dc 2>/dev/null | xxd
# 00000000: 7472 6565 2037 3300 3130 3036 3434 206e  tree 73.100644 n
# 00000010: 616d 652e 6578 7400 ce01 3625 030b a8db  ame.ext...6%....
# 00000020: a906 f756 967f 9e9c a394 464a 3130 3037  ...V......FJ1007
# 00000030: 3535 206e 616d 6532 2e65 7874 00ce 0136  55 name2.ext...6
# 00000040: 2503 0ba8 dba9 06f7 5696 7f9e 9ca3 9446  %.......V......F
# 00000050: 4a                                       J
```

- Lv1

```bash
git cat-file tree 5841 | xxd
# 00000000: 3130 3036 3434 206e 616d 652e 6578 7400  100644 name.ext.
# 00000010: ce01 3625 030b a8db a906 f756 967f 9e9c  ..6%.......V....
# 00000020: a394 464a 3130 3037 3535 206e 616d 6532  ..FJ100755 name2
# 00000030: 2e65 7874 00ce 0136 2503 0ba8 dba9 06f7  .ext...6%.......
# 00000040: 5696 7f9e 9ca3 9446 4a                   V......FJ
```

- Lv2
使用`git ls-tree`可以方便地看到文件夹的内容

```bash
git ls-tree 5841
# 100644 blob ce013625030ba8dba906f756967f9e9ca394464a	name.ext
# 100755 blob ce013625030ba8dba906f756967f9e9ca394464a	name2.ext
```

- Lv3
使用`git show`直接作用在tree上可以看到简化版的文件夹内容

```bash
git show 5841
# tree 5841
#
# name.ext
# name2.ext
```

# 创建commit

- Lv1

```bash
git hash-object -t commit --stdin -w <<EOF
tree 58417991a0e30203e7e9b938f62a9a6f9ce10a9a
author b1f6c1c4 <b1f6c1c4@gmail.com> 1514736000 +0800
committer b1f6c1c4 <b1f6c1c4@gmail.com> 1514736000 +0800

The commit message
May have multiple
lines!
EOF
# d4dafde7cd9248ef94c0400983d51122099d312a
```

- Lv2

```bash
GIT_AUTHOR_NAME=b1f6c1c4 \
GIT_AUTHOR_EMAIL=b1f6c1c4@gmail.com \
GIT_AUTHOR_DATE='1600000000 +0800' \
GIT_COMMITTER_NAME=b1f6c1c4 \
GIT_COMMITTER_EMAIL=b1f6c1c4@gmail.com \
GIT_COMMITTER_DATE='1600000000 +0800' \
git commit-tree 5841 -p d4da <<EOF
Message may be read
from stdin
or by the option '-m'
EOF
# efd4f82f6151bd20b167794bc57c66bbf82ce7dd
```

# 查看commit

- Lv0

```bash
# 注意：不可将gunzip的输出直接打印到控制台，否则会因为遇到\0而中止
printf '\x1f\x8b\x08\x00\x00\x00\x00\x00' \
| cat - ./objects/ef/d4f82f6151bd20b167794bc57c66bbf82ce7dd \
| gunzip -dc 2>/dev/null | xxd
# 00000000: 636f 6d6d 6974 2032 3539 0074 7265 6520  commit 259.tree 
# 00000010: 3538 3431 3739 3931 6130 6533 3032 3033  58417991a0e30203
# 00000020: 6537 6539 6239 3338 6636 3261 3961 3666  e7e9b938f62a9a6f
# 00000030: 3963 6531 3061 3961 0a70 6172 656e 7420  9ce10a9a.parent 
# 00000040: 6434 6461 6664 6537 6364 3932 3438 6566  d4dafde7cd9248ef
# 00000050: 3934 6330 3430 3039 3833 6435 3131 3232  94c0400983d51122
# 00000060: 3039 3964 3331 3261 0a61 7574 686f 7220  099d312a.author 
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
git cat-file commit efd4
# tree 58417991a0e30203e7e9b938f62a9a6f9ce10a9a
# parent d4dafde7cd9248ef94c0400983d51122099d312a
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
git show efd4~
# commit d4dafde7cd9248ef94c0400983d51122099d312a
# Author: b1f6c1c4 <b1f6c1c4@gmail.com>
# Date:   Mon Jan 1 00:00:00 2018 +0800
#
#     The commit message
#     May have multiple
#     lines!
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

# 从commit找到tree和blob

- Lv2

```bash
# 找到commit efd4对应的tree：
# 注意：运行结果与手动写efd4^{tree}无异
git ls-tree efd4
# 100644 blob ce013625030ba8dba906f756967f9e9ca394464a	name.ext
# 100755 blob ce013625030ba8dba906f756967f9e9ca394464a	name2.ext
# 找到commit efd4（对应的tree）的/name.ext：
git ls-tree efd4 -- name.ext
# 100644 blob ce013625030ba8dba906f756967f9e9ca394464a	name.ext
```

- Lv3

```bash
# 找到commit efd4对应的tree：
# 注意：运行结果与只写efd4有本质差异
git show efd4^{tree}
# tree efd4^{tree}
#
# name.ext
# name2.ext
# 找到commit efd4（对应的tree）的/name.ext：
# 注意语法与git ls-tree完全不同：
# git ls-tree是给定一个tree，可选地根据路径找到另一个tree或者tree的行
# git show是给定一个对象，自动判断类型并展示
git show efd4:name.ext
# hello
```

# 创建tag

注意：你可以让tag指向tag，虽然没有什么卵用

- Lv1 模仿commit的创建方法即可创建

- Lv2

```bash
git mktag <<EOF
object efd4f82f6151bd20b167794bc57c66bbf82ce7dd
type commit
tag simple-tag
tagger b1f6c1c4 <b1f6c1c4@gmail.com> 1527189535 +0000

The tag message
EOF
# aba3692b60790d098d3f6682555214f3bf09f7da
```

- Lv3
*特别注意：`git tag -a`命令不仅仅创建了tag对象，还建立了新的引用在`refs/tags/the-tag`。*

```bash
# 该命令没有输出
GIT_COMMITTER_NAME=b1f6c1c4 \
GIT_COMMITTER_EMAIL=b1f6c1c4@gmail.com \
GIT_COMMITTER_DATE='1600000000 +0800' \
git tag -a -m 'The tag message' the-tag efd4:name.ext
# 需要用如下命令找到新创建的对象
git rev-parse the-tag
# 9cb6a0ecbdc1259e0a88fa2d8ac4725195b4964d
```

# 查看tag

- Lv0 模仿commit的查看方法即可

- Lv2

```bash
git cat-file tag 9cb6
# object ce013625030ba8dba906f756967f9e9ca394464a
# type blob
# tag the-tag
# tagger b1f6c1c4 <b1f6c1c4@gmail.com> 1600000000 +0800
#
# The tag message
# 注意：如果想要查看tag指向的对象，只需要修改type即可：
git cat-file blob 9cb6
# hello
```

- Lv3

```bash
# 注意：git show同时显示tag本身和tag指向的对象的信息
git show 9cb6
# tag the-tag
# Tagger: b1f6c1c4 <b1f6c1c4@gmail.com>
# Date:   Sun Sep 13 20:26:40 2020 +0800
#
# The tag message
# hello
```

# 检查文件系统

查找并删除无用对象：（**有一定危险，可能会删掉有用的东西**）
- Lv2

```bash
(git update-ref HEAD efd4)
git count-objects
# 6 objects, 24 kilobytes
# 列出没有在任何引用中使用的对象
git fsck --unreachable
# unreachable tag aba3692b60790d098d3f6682555214f3bf09f7da
# 列出没有在任何引用或对象中使用的对象
git fsck
# dangling tag aba3692b60790d098d3f6682555214f3bf09f7da
# 删除以上（**有一定危险，可能会删掉有用的东西**）
git prune
git count-objects
# 5 objects, 20 kilobytes
git fsck --unreachable
git fsck
```

检查文件系统完整性：
- Lv2

```bash
mv objects/ce/013625030ba8dba906f756967f9e9ca394464a ../evil
git fsck --connectivity-only
# broken link from     tag 9cb6a0ecbdc1259e0a88fa2d8ac4725195b4964d
#               to    blob ce013625030ba8dba906f756967f9e9ca394464a
# missing blob ce013625030ba8dba906f756967f9e9ca394464a
mv ../evil objects/ce/013625030ba8dba906f756967f9e9ca394464a
git fsck --connectivity-only
```

# “修改”对象

Git对象本身是无法修改的，但是Git提供了一种机制使得我们可以用一个新的对象来覆盖某个现成对象，
在访问原对象的时候会被自动定向到新的对象中。

若要将efd4替换为另外的一个commit，首先先创建一个commit：
```bash
git hash-object -t commit --stdin -w <<EOF
tree 58417991a0e30203e7e9b938f62a9a6f9ce10a9a
parent d4dafde7cd9248ef94c0400983d51122099d312a
author Mx. Evil <evil@gmail.com> 1600000000 -0400
committer Mx. Evil <evil@gmail.com> 1600000000 -0400

OOF.. This is a fake one... hahahaha!
EOF
# 9f3162e7fd9f1d41b704c0064c62714d7e699643
```

## 添加replace

- Lv0

```bash
mkdir -p refs/replace/
echo '9f3162e7fd9f1d41b704c0064c62714d7e699643' >refs/replace/efd4f82f6151bd20b167794bc57c66bbf82ce7dd
```

- Lv2

```bash
(git replace --delete efd4 >/dev/null)
git replace -f efd4 9f31
```

注意：若成环会导致错误
```bash
(git replace --delete efd4 >/dev/null)
git replace -f efd4 9f31
git replace -f 9f31 efd4
git cat-file commit efd4
# fatal: replace depth too high for object efd4f82f6151bd20b167794bc57c66bbf82ce7dd
(git replace --delete 9f31 >/dev/null)
```

- Lv3
无需提前创建，直接使用vim方便地修改对象：（此时要求新旧对象类型一致）

```sh
git replace --edit efd4
```

## 列出所有replace

- Lv3

```bash
git replace -l --format=long
# efd4f82f6151bd20b167794bc57c66bbf82ce7dd (commit) -> 9f3162e7fd9f1d41b704c0064c62714d7e699643 (commit)
```

## 分别访问新旧对象

除非使用Lv0方式或者`--no-replace-objects`，否则访问efd4的时候总会被重定向到9f31：

- Lv2

```bash
git cat-file commit efd4
# tree 58417991a0e30203e7e9b938f62a9a6f9ce10a9a
# parent d4dafde7cd9248ef94c0400983d51122099d312a
# author Mx. Evil <evil@gmail.com> 1600000000 -0400
# committer Mx. Evil <evil@gmail.com> 1600000000 -0400
#
# OOF.. This is a fake one... hahahaha!
# 注意--no-replace-objects是总的参数，不是cat-file自己的
git --no-replace-objects cat-file commit efd4
# tree 58417991a0e30203e7e9b938f62a9a6f9ce10a9a
# parent d4dafde7cd9248ef94c0400983d51122099d312a
# author b1f6c1c4 <b1f6c1c4@gmail.com> 1600000000 +0800
# committer b1f6c1c4 <b1f6c1c4@gmail.com> 1600000000 +0800
#
# Message may be read
# from stdin
# or by the option '-m'
```

- Lv3

```bash
git show efd4
# commit efd4f82f6151bd20b167794bc57c66bbf82ce7dd
# Author: Mx. Evil <evil@gmail.com>
# Date:   Sun Sep 13 08:26:40 2020 -0400
#
#     OOF.. This is a fake one... hahahaha!
git --no-replace-objects show efd4
# commit efd4f82f6151bd20b167794bc57c66bbf82ce7dd
# Author: b1f6c1c4 <b1f6c1c4@gmail.com>
# Date:   Sun Sep 13 20:26:40 2020 +0800
#
#     Message may be read
#     from stdin
#     or by the option '-m'
```

## 取消replace，保留新旧两个对象

- Lv0

```bash
rm -f refs/replace/efd4f82f6151bd20b167794bc57c66bbf82ce7dd
```

- Lv3

```bash
(git replace -f efd4 9f31)
git replace --delete efd4
# Deleted replace ref 'efd4f82f6151bd20b167794bc57c66bbf82ce7dd'
```

# 给对象添加备注

Git支持给任意对象添加备注，其本质是一个commit，其tree列出了备注内容blob和对应的对象SHA1（作为文件名）。
每个对象至多有一个备注。

## 添加备注

- Lv1

```bash
echo 'additional notes' | git hash-object -t blob --stdin -w
# 095f841daf9333f3addfbc44d49efab0be903bfe
git mktree <<EOF
100644 blob 095f841daf9333f3addfbc44d49efab0be903bfe$(printf '\t')efd4f82f6151bd20b167794bc57c66bbf82ce7dd
EOF
# 9b13933df415639aefdd0ac135b9f68fbdad8bac
git hash-object -t commit --stdin -w <<EOF
tree 9b13933df415639aefdd0ac135b9f68fbdad8bac
author author <author@gmail.com> 1234567890 +0800
committer committer <committer@gmail.com> 1514736120 +0800

Notes added by 'git notes add'
EOF
# a692dfc071d3e1043cb69b57d5f43b01335066f3
mkdir -p ./refs/notes/
echo 'a692dfc071d3e1043cb69b57d5f43b01335066f3' >>./refs/notes/commits
```

- Lv3

```bash
GIT_AUTHOR_NAME=author \
GIT_AUTHOR_EMAIL=author@gmail.com \
GIT_AUTHOR_DATE='1234567890 +0800' \
GIT_COMMITTER_NAME=committer \
GIT_COMMITTER_EMAIL=committer@gmail.com \
GIT_COMMITTER_DATE='1514736120 +0800' \
git notes add -f -m 'notes for blob' ce01
```

`git notes edit`会打开vim并编辑notes。

## 查看备注

- Lv2

```bash
git cat-file commit refs/notes/commits
# tree 7a83bc1272e9f212118152c47f239c9b9482d0de
# parent a692dfc071d3e1043cb69b57d5f43b01335066f3
# author author <author@gmail.com> 1234567890 +0800
# committer committer <committer@gmail.com> 1514736120 +0800
#
# Notes added by 'git notes add'
git ls-tree refs/notes/commits
# 100644 blob c5a9a385e3dbe4e65d6db1957bfe18dbf85c517c	ce013625030ba8dba906f756967f9e9ca394464a
# 100644 blob 095f841daf9333f3addfbc44d49efab0be903bfe	efd4f82f6151bd20b167794bc57c66bbf82ce7dd
git cat-file blob 095f
# additional notes
git cat-file blob c5a9
# notes for blob
```

- Lv3

```bash
git notes list
# c5a9a385e3dbe4e65d6db1957bfe18dbf85c517c ce013625030ba8dba906f756967f9e9ca394464a
# 095f841daf9333f3addfbc44d49efab0be903bfe efd4f82f6151bd20b167794bc57c66bbf82ce7dd
git notes show efd4
# additional notes
git notes show ce01
# notes for blob
git show efd4
# commit efd4f82f6151bd20b167794bc57c66bbf82ce7dd
# Author: b1f6c1c4 <b1f6c1c4@gmail.com>
# Date:   Sun Sep 13 20:26:40 2020 +0800
#
#     Message may be read
#     from stdin
#     or by the option '-m'
#
# Notes:
#     additional notes
```

## 删除备注

- Lv1

```bash
git ls-tree refs/notes/commits | sed '/efd4f82f6151bd20b167794bc57c66bbf82ce7dd/d' | git mktree
# 121f227d991dbea1913c226305db1aa724ae72df
git hash-object -t commit --stdin -w <<EOF
tree 121f227d991dbea1913c226305db1aa724ae72df
author author <author@gmail.com> 1234567890 +0800
committer committer <committer@gmail.com> 1514736120 +0800

Notes added by 'git notes add'
EOF
# cb132dbe2c9e9f8d684452078ba659242d5b9cb7
git update-ref refs/notes/commits cb132dbe2c9e9f8d684452078ba659242d5b9cb7
git notes list
# c5a9a385e3dbe4e65d6db1957bfe18dbf85c517c ce013625030ba8dba906f756967f9e9ca394464a
```

- Lv3

```bash
# 由于需要重新创建commit，必须指定author和committer
GIT_AUTHOR_NAME=author \
GIT_AUTHOR_EMAIL=author@gmail.com \
GIT_AUTHOR_DATE='1234567890 +0800' \
GIT_COMMITTER_NAME=committer \
GIT_COMMITTER_EMAIL=committer@gmail.com \
GIT_COMMITTER_DATE='1514736120 +0800' \
git notes remove ce01
# Removing note for object ce01
git notes list
```

# 总结

- Lv1
  - `git hash-object -t <type> [--stdin|<file>] -w`
- Lv2
  - `git mktree --missing`
  - `git commit-tree <tree> -m <message> [-p <parent>]*`
  - `git mktag`
  - `git cat-file <type> <SHA1>`
  - `git ls-tree <SHA1> -- [<path>]`
  - `git count-objects`
  - `git fsck [--unreachable] [--connectivity-only]`
  - `git prune` - **有一定危险，可能会删掉有用的东西**
  - `git replace -f <original> <replacement>`
- Lv3
  - `git tag -a -m <message> <name> <object>` - 同时创建新引用在`refs/tags/<name>`
  - `git show <commit>`
  - `git show <tree>` - 如`HEAD^{tree}`
  - `git show <blob>` - 如`HEAD:index.js`
  - `git replace --edit <original>`
  - `git replace -l --format=long`
  - `git replace --delete <original>`
  - `git notes add | list | show <object> | remove <object>`

