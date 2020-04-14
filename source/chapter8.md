# 第8章：检索与查看历史

## 检查分支的commit

- Lv2

若要根据parent关系，列出一个引用的所有commit，只需使用`git rev-list <commit-ish>`。
加上`-v`可以列出更多内容。
然而这并不能满足日常工作需求：
没有语法高亮、没有具体修改内容、没有非线性关系、
没有自动分页、没有tag。
所以Lv2的`git rev-list`命令并没有什么实际意义。

- Lv3

Lv3的`git log`的基本语法是`git log <commit-ish> [-- <path>]`。
但是依然没有好到哪里去。
我们必须添加一些参数，最好封装成Lv4。
根据实际使用需求，分成4种情况：

### 查看当前分支的简要历史

- Lv4: `git lg`

`git log --color --graph --pretty=format:'%Cred%h%Creset -%C(magenta)%d %Cgreen(%aI)%Creset %s %C(bold blue)<%an>%Creset' --abbrev-commit`

### 查看整个repo的简要历史

- Lv4: `git la`

`git log --color --graph --pretty=format:'%Cred%h%Creset -%C(magenta)%d %Cgreen(%aI)%Creset %s %C(bold blue)<%an>%Creset' --abbrev-commit --all`

### 查看当前分支的历史文件修改摘要

- Lv4: `git ls`

`git log --color --graph --pretty=format:'%Cred%h%Creset -%C(magenta)%d %Cgreen(%aI)%Creset %s %C(bold blue)<%an>%Creset' --abbrev-commit --decorate --numstat`

### 查看当前分支的历史文件修改详情

- Lv4: `git lf`

`git log -p`

## 检查某个文件的历史

有两种视角：

### 分支视角：列出当前分支中和该文件有关的所有commit

- Lv4: `git lf [--follow] -- <path>`

添加`--follow`可以兼容文件重命名。

### 内容视角：对文件的每一行列出哪个commit修改了它

- Lv3: `git blame -n -- <path>`

## 搜索关键词

### 在worktree中搜索

注意：只能搜索在index中有对应项的文件。

- Lv1

`git ls-files -s -- <path> | awk '{ print $2; }' | xargs -0 grep [-i] [-w] [-P] <regex>`

- Lv3

`git grep [-i] [-w] [-P] <regex> -- <path>`

### 在index中搜索

- Lv1

`git ls-files -s -- <path> | awk '{ print $2; }' | xargs -n 1 bash -c 'git cat-file blob $1 | grep [-i] [-w] [-P] <regex>' ''`

- Lv3

`git grep --cached [-i] [-w] [-P] <regex> -- <path>`

### 在tree中搜索

- Lv1

`git ls-tree -r <tree-ish> -- <path> | awk '{ print $3; }' | xargs -r -n 1 bash -c 'git cat-file blob $1 | grep [-i] [-w] [-P] <regex>' ''`

- Lv3

`git grep [-i] [-w] [-P] <regex> <tree-ish> -- <path>`

### 在当前分支中搜索

注意：一般正常人都会先在HEAD中搜索，找不到了再尝试在当前分支中搜索。
因此我们可以认为关键词一定会在`git lf`中出现至少两次（一次添加一次删除）。

- Lv2: `git grep <regex> $(git rev-list HEAD)`
- Lv3: `git lf` 然后使用pager的搜索功能
- Lv3: `git log -G <regex>`

### 在整个repo的所有所有引用的最新commit中搜索

- Lv2: `git grep <regex> $(git rev-parse --all)`

### 在整个repo的所有历史中搜索

过于暴力，走投无路了再用这个：

- Lv2: `git grep <regex> $(git rev-list --all)`

### 在HEAD及其所有submodule中搜索

TODO
