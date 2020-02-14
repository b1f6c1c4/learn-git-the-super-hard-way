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
git commit-tree 5841 -p d4da << EOF
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

- Lv1 模仿commit的创建方法即可创建

- Lv3
*特别注意：`git tag`命令不仅仅创建了tag对象，还建立了新的引用在`refs/tags/the-tag`。*
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

## 总结

- Lv1
  - `git hash-object -t <type> [--stdin|<file>] -w` - 创建对象
- Lv2
  - `git mktree --missing` - 创建tree
  - `git commit-tree <tree> -m <message> [-p <parent>]*` - 创建commit
  - `git cat-file <type> <SHA1>` - 查看blob和commit
  - `git ls-tree <SHA1> -- [<path>]` - 查看tree
- Lv3
  - `git tag -a -m <message> <name> <object>` - 同时创建新引用在`refs/tags/<name>`
  - `git show <commit>`
  - `git show <tree>` - 如`HEAD^{tree}`
  - `git show <blob>` - 如`HEAD:index.js`

