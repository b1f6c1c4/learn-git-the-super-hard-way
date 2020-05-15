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

```bash
git init --bare .
```

## 创建blob

- Lv1
```bash
echo 'hello' | git hash-object -t blob --stdin -w
```

- Lv2
```bash
echo 'hello' > temp-file
git hash-object -t blob temp-file -w
```

## 查看blob

- Lv0
```bash
# 注意：不可将gunzip的输出直接打印到控制台，否则会因为遇到\0而中止
printf '\x1f\x8b\x08\x00\x00\x00\x00\x00' \
| cat - ./objects/ce/013625030ba8dba906f756967f9e9ca394464a \
| gunzip -dc 2>/dev/null | xxd
```

- Lv2
```bash
git cat-file blob ce01
```

- Lv3
```bash
# 将git show直接作用在blob上，等价于git cat-file blob
git show ce01
```

## 创建tree

- Lv1
注意：要先对文件名排序，再使用`git hash-object`
```bash
(printf '100644 name.ext\x00';
echo '0: ce013625030ba8dba906f756967f9e9ca394464a' | xxd -rp -c 256;
printf '100755 name2.ext\x00';
echo '0: ce013625030ba8dba906f756967f9e9ca394464a' | xxd -rp -c 256) \
| git hash-object -t tree --stdin -w
```

- Lv2
*注意：SHA1和文件名之间必须用tab分隔*，在命令行里输入tab的方法是`<Ctrl-v><Tab>`
```bash
git mktree --missing <<EOF
100644 blob ce013625030ba8dba906f756967f9e9ca394464a$(printf '\t')name.ext
100755 blob ce013625030ba8dba906f756967f9e9ca394464a$(printf '\t')name2.ext
EOF
```

## 查看tree

- Lv0
```bash
# 注意：不可将gunzip的输出直接打印到控制台，否则会因为遇到\0而中止
printf '\x1f\x8b\x08\x00\x00\x00\x00\x00' \
| cat - ./objects/58/417991a0e30203e7e9b938f62a9a6f9ce10a9a \
| gunzip -dc 2>/dev/null | xxd
```

- Lv1
```bash
git cat-file tree 5841 | xxd
```

- Lv2
使用`git ls-tree`可以方便地看到文件夹的内容
```bash
git ls-tree 5841
```

- Lv3
使用`git show`直接作用在tree上可以看到简化版的文件夹内容
```bash
git show 5841
```

## 创建commit

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
```

## 查看commit

- Lv0
```bash
# 注意：不可将gunzip的输出直接打印到控制台，否则会因为遇到\0而中止
printf '\x1f\x8b\x08\x00\x00\x00\x00\x00' \
| cat - ./objects/ef/d4f82f6151bd20b167794bc57c66bbf82ce7dd \
| gunzip -dc 2>/dev/null | xxd
```

- Lv2
使用`git cat-tree`可以方便地看到commit本身的内容
```bash
git cat-file commit efd4
```

- Lv3
使用`git show`直接作用在commit上可以看到commit本身及其tree的diff情况
```bash
git show efd4~
```

## 从commit找到tree和blob

- Lv2
```bash
# 找到commit efd4对应的tree：
# 注意：运行结果与手动写efd4^{tree}无异
git ls-tree efd4
# 找到commit efd4（对应的tree）的/name.ext：
git ls-tree efd4 -- name.ext
```

- Lv3
```bash
# 找到commit efd4对应的tree：
# 注意：运行结果与只写efd4有本质差异
git show efd4^{tree}
# 找到commit efd4（对应的tree）的/name.ext：
# 注意语法与git ls-tree完全不同：
# git ls-tree是给定一个tree，可选地根据路径找到另一个tree或者tree的行
# git show是给定一个对象，自动判断类型并展示
git show efd4:name.ext
```

## 创建tag

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
```

- Lv3
*特别注意：`git tag -a`命令不仅仅创建了tag对象，还建立了新的引用在`refs/tags/the-tag`。*
```bash
# 该命令没有输出
GIT_AUTHOR_NAME=b1f6c1c4 \
GIT_AUTHOR_EMAIL=b1f6c1c4@gmail.com \
GIT_AUTHOR_DATE='1600000000 +0800' \
GIT_COMMITTER_NAME=b1f6c1c4 \
GIT_COMMITTER_EMAIL=b1f6c1c4@gmail.com \
GIT_COMMITTER_DATE='1600000000 +0800' \
git tag -a -m 'The tag message' the-tag efd4:name.ext
# 需要用如下命令找到新创建的对象
git rev-parse the-tag
```

## 查看tag

- Lv0 模仿commit的查看方法即可

- Lv2
```bash
git cat-file tag 9cb6
# 注意：如果想要查看tag指向的对象，只需要修改type即可：
git cat-file blob 9cb6
```

- Lv3
```bash
# 注意：git show同时显示tag本身和tag指向的对象的信息
git show 9cb6
```

## 检查文件系统

查找并删除无用对象：（**有一定危险，可能会删掉有用的东西**）
- Lv2
```bash
(git update-ref HEAD efd4)
git count-objects
# 列出没有在任何引用中使用的对象
git fsck --unreachable
# 列出没有在任何引用或对象中使用的对象
git fsck
# 删除以上（**有一定危险，可能会删掉有用的东西**）
git prune
git count-objects
git fsck --unreachable
git fsck
```

检查文件系统完整性：
- Lv2
```bash
mv objects/ce/013625030ba8dba906f756967f9e9ca394464a ../evil
git fsck --connectivity-only
mv ../evil objects/ce/013625030ba8dba906f756967f9e9ca394464a
git fsck --connectivity-only
```

## “修改”对象

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
```

### 添加replace

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
(git replace --delete 9f31 >/dev/null)
```

- Lv3
无需提前创建，直接使用vim方便地修改对象：（此时要求新旧对象类型一致）
```sh
git replace --edit efd4
```

### 列出所有replace

- Lv3
```bash
git replace -l --format=long
```

### 分别访问新旧对象

除非使用Lv0方式或者`--no-replace-objects`，否则访问efd4的时候总会被重定向到9f31：

- Lv2
```bash
git cat-file commit efd4
# 注意--no-replace-objects是总的参数，不是cat-file自己的
git --no-replace-objects cat-file commit efd4
```

- Lv3
```bash
git show efd4
git --no-replace-objects show efd4
```

### 取消replace，保留新旧两个对象

- Lv0
```bash
rm -f refs/replace/efd4f82f6151bd20b167794bc57c66bbf82ce7dd
```

- Lv3
```bash
(git replace -f efd4 9f31)
git replace --delete efd4
```

## 给对象添加备注

Git支持给任意对象添加备注，其本质是一个commit，其tree列出了备注内容blob和对应的对象SHA1（作为文件名）。
每个对象至多有一个备注。

### 添加备注

- Lv1
```bash
echo 'additional notes' | git hash-object -t blob --stdin -w
git mktree <<EOF
100644 blob 095f841daf9333f3addfbc44d49efab0be903bfe$(printf '\t')efd4f82f6151bd20b167794bc57c66bbf82ce7dd
EOF
git hash-object -t commit --stdin -w <<EOF
tree 9b13933df415639aefdd0ac135b9f68fbdad8bac
author author <author@gmail.com> 1234567890 +0800
committer committer <committer@gmail.com> 1514736120 +0800

Notes added by 'git notes add'
EOF
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

### 查看备注

- Lv2
```bash
git cat-file commit refs/notes/commits
git ls-tree refs/notes/commits
git cat-file blob 095f
git cat-file blob c5a9
```

- Lv3
```bash
git notes list
git notes show efd4
git notes show ce01
git show efd4
```

### 删除备注

- Lv1
```bash
git ls-tree refs/notes/commits | sed '/efd4f82f6151bd20b167794bc57c66bbf82ce7dd/d' | git mktree
git hash-object -t commit --stdin -w <<EOF
tree 121f227d991dbea1913c226305db1aa724ae72df
author author <author@gmail.com> 1234567890 +0800
committer committer <committer@gmail.com> 1514736120 +0800

Notes added by 'git notes add'
EOF
git update-ref refs/notes/commits cb132dbe2c9e9f8d684452078ba659242d5b9cb7
git notes list
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
git notes list
```

## 总结

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

