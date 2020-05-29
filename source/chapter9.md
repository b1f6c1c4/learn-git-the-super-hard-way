# 基础知识

在worktree内部创建新的repo/worktree是坏的，因为一个文件受两个repo管辖。
一个workaround是将这个小的repo/worktree变成大repo的一个submodule。

一个submodule的信息可以分为静态与动态两大部分，总共分散在5个位置：
- `.gitmodules`文件中包含一部分静态信息：
  - submodule (name)：名字
  - path：应该放在worktree的哪个路径里面
  - url：在哪里能够找到包含该commit的repo
  - branch：没有什么卵用
  - update：如何处理下级repo的更改
- index中包含另一部分静态信息：
  - commit：上级repo期待哪个commit
- `.git/config`文件中包含一部分动态信息：
  - submodule (name)
  - active：启用/禁用
  - url
  - update
- `.git/modules/<name>/`是下级repo，包含一部分动态信息
- `<path>`是下级repo的worktree，包含一部分动态信息

```bash
git config --global alias.lg "log --graph --pretty=tformat:'%h -%d <%an/%cn> %s' --abbrev-commit"
```

# 添加/更新submodule的静态部分（`.gitmodules`/index）

非常简单，直接修改`.gitmodules`和index：

- Lv1

```bash
git init parent
cd parent
cat - >.gitmodules <<EOF
[submodule "static/name"]
    path = whatever/path
    url = https://github.com/b1f6c1c4/git-get.git
    update = none
EOF
git config --file=.gitmodules --list
git update-index --add --cacheinfo 160000,bff56f7a1c9585780950dce5c1964410e0aa2ecc,whatever/path
git ls-files -s
```

- Lv2
```bash
(rm -rf parent)
git init parent
cd parent
git config --file=.gitmodules submodule.static/name.path whatever/path
git config --file=.gitmodules submodule.static/name.url https://github.com/b1f6c1c4/git-get.git
git config --file=.gitmodules submodule.static/name.update none
cat .gitmodules
git update-index --add --cacheinfo 160000,bff56f7a1c9585780950dce5c1964410e0aa2ecc,whatever/path
git ls-files -s
```

非常遗憾的是，没有Lv3的方法能够做到这一点。

# 用`.gitmodules`来更新`.git/config`

- Lv2

```bash
cd parent
git config --type=bool submodule.static/name.active true
git config submodule.static/name.url \
  "$(git config --file=.gitmodules submodule.static/name.url)"
git config submodule.static/name.update \
  "$(git config --file=.gitmodules submodule.static/name.update)"
cat .git/config
```

- Lv3

```bash
cd parent
(git config --remove-section submodule.static/name)
git submodule init -- whatever/path
cat .git/config
```

# 用`.git/config`和index来更新repo和worktree

`git submodule update`是实现这个功能的Lv3命令。
其基本语法是
`git submodule update [--checkout|--rebase|--merge] -- <path>`
若未指定那三个选项，其功能根据`git config submodule.<name>.update`而定，共有5种：
- checkout（此为默认情况）
- rebase
- merge
- none
- !...

下面将分别介绍。

## `git submodule update --checkout == git clone`

- Lv2

```bash
cd parent
(git submodule --quiet init -- whatever/path)
git config --list | grep -F submodule.static/name
# 首先创建repo和worktree
mkdir -p .git/modules/static/name
git init --separate-git-dir .git/modules/static/name whatever/path
git -C whatever/path config core.worktree ../../../../whatever/path
ls -A .git/modules/static/name whatever/path
# 然后设置remote
git -C whatever/path remote add origin \
  "$(git config submodule.static/name.url)"
# 然后fetch
git -C whatever/path fetch origin
# 然后创建默认分支（根据远端的HEAD是谁而决定）
# （其实这一步实际上并没有什么卵用）
git -C whatever/path symbolic-ref refs/remotes/origin/HEAD refs/remotes/origin/master
git -C whatever/path update-ref refs/heads/master refs/remotes/origin/master
git -C whatever/path config branch.master.remote origin
git -C whatever/path config branch.master.merge refs/heads/master
# 然后switch到目标commit
git -C whatever/path switch --detach \
  "$(git ls-files -s -- whatever/path | awk "{ print $2; }")"
git -C whatever/path branch -av
ls -A whatever/path
cat .git/modules/static/name/config
```

由于其中有`git fetch`，巨量无关数据一并被下载了下来。

- Lv3

```bash
cd parent
(rm -rf .git/modules whatever/path)
git submodule update --checkout -- whatever/path
git -C whatever/path branch -av
ls -A whatever/path
cat .git/modules/static/name/config
```

这里面依然有`git fetch`。
为了解决这个问题，可以使用`git-get`：

- Lv5: [git-get](https://github.com/b1f6c1c4/git-get)

## `git submodule update --checkout [-f] == git switch [-f] <commit>`

假设index发生了变动：

```bash
git -C parent update-index --cacheinfo 160000,e97348c1ba3072a1c108218f6ba88c3177a7456f,whatever/path
```

- Lv2

```bash
cd parent
git -C whatever/path switch -f --detach \
  "$(git ls-files -s -- whatever/path | awk "{ print $2; }")"
git -C whatever/path status
```

- Lv3

```bash
cd parent
git submodule update --checkout -f -- whatever/path
git -C whatever/path status
```

## `git submodule update --rebase == git rebase <commit>`

（先回到原来的HEAD位置）
```bash
(git -C parent update-index --cacheinfo 160000,bff56f7a1c9585780950dce5c1964410e0aa2ecc,whatever/path)
(git -C parent submodule --quiet update --checkout -f -- whatever/path)
```

假设repo中HEAD发生了变动：

```bash
cd parent
git -C whatever/path switch --detach 2dd5
```

然后index又发生了变动：

```bash
git -C parent update-index --cacheinfo 160000,e97348c1ba3072a1c108218f6ba88c3177a7456f,whatever/path
```

现在希望能够把下级repo中新的改动rebase到e973上：

- Lv2

```bash
cd parent
git -C whatever/path lg HEAD e973
GIT_COMMITTER_NAME=committer \
GIT_COMMITTER_EMAIL=committer@gmail.com \
GIT_COMMITTER_DATE='1514736120 +0800' \
git -C whatever/path rebase --quiet e973
git -C whatever/path lg HEAD e973
```

- Lv3

```bash
cd parent
(git -C whatever/path switch --detach 2dd5 2>/dev/null)
git -C whatever/path lg HEAD e973
GIT_COMMITTER_NAME=committer \
GIT_COMMITTER_EMAIL=committer@gmail.com \
GIT_COMMITTER_DATE='1514736120 +0800' \
git submodule update --rebase -- whatever/path 2>/dev/null
git -C whatever/path lg HEAD e973
```

## `git submodule update --merge == git merge <commit>`

（先回到原来的HEAD位置）
```bash
(git -C parent update-index --cacheinfo 160000,bff56f7a1c9585780950dce5c1964410e0aa2ecc,whatever/path)
(git -C parent submodule update --checkout -f -- whatever/path 2>/dev/null)
```

假设repo中HEAD发生了变动：

```bash
cd parent
git -C whatever/path switch --detach 2dd5
```

然后index又发生了变动：

```bash
git -C parent update-index --cacheinfo 160000,e97348c1ba3072a1c108218f6ba88c3177a7456f,whatever/path
```

现在希望能够在下级repo中merge上级以为的新的改动：

- Lv2

```bash
cd parent
git -C whatever/path lg HEAD e973
GIT_AUTHOR_NAME=author \
GIT_AUTHOR_EMAIL=author@gmail.com \
GIT_AUTHOR_DATE='1234567890 +0800' \
GIT_COMMITTER_NAME=committer \
GIT_COMMITTER_EMAIL=committer@gmail.com \
GIT_COMMITTER_DATE='1514736120 +0800' \
git -C whatever/path merge e973
git -C whatever/path lg HEAD e973
```

- Lv3

```bash
cd parent
(git -C whatever/path switch --quiet --detach 2dd5)
git -C whatever/path lg HEAD e973
GIT_AUTHOR_NAME=author \
GIT_AUTHOR_EMAIL=author@gmail.com \
GIT_AUTHOR_DATE='1234567890 +0800' \
GIT_COMMITTER_NAME=committer \
GIT_COMMITTER_EMAIL=committer@gmail.com \
GIT_COMMITTER_DATE='1514736120 +0800' \
git submodule update --merge -- whatever/path
git -C whatever/path lg HEAD e973
```

## 其他两种`git config submodule.<name>.update`

```bash
cd parent
git config submodule.static/name.update none
git submodule update -- whatever/path
```

```bash
cd parent
git config submodule.static/name.update '!true'
git submodule update -- whatever/path
git config submodule.static/name.update '!false'
git submodule update -- whatever/path
git config submodule.static/name.update '!echo'
git submodule update -- whatever/path
```

# 用`.gitmodules`和index来创建repo和worktree

分两步：用`.gitmodules`来更新`.git/config`；再用`.git/config`和index来更新repo和worktree。
Lv2不再赘述。

- Lv3
```bash
cd parent
(rm -rf .git/modules whatever/path)
git submodule update --init --checkout -- whatever/path
```

# 用repo来更新index

（先回到原来的HEAD位置）
```bash
(git -C parent update-index --cacheinfo 160000,bff56f7a1c9585780950dce5c1964410e0aa2ecc,whatever/path)
(git -C parent submodule --quiet update --checkout -f -- whatever/path)
```

假设repo中HEAD发生了变动：

```bash
cd parent
git -C whatever/path switch --detach 2dd5
```

现在希望index也跟着变动：

- Lv1

```bash
cd parent
git ls-files -s
git update-index --cacheinfo "160000,$(git -C whatever/path rev-parse HEAD),whatever/path"
git ls-files -s
```

- Lv2

```bash
cd parent
(git update-index --cacheinfo 160000,bff56f7a1c9585780950dce5c1964410e0aa2ecc,whatever/path)
git ls-files -s
git update-index -- whatever/path
git ls-files -s
```

- Lv3

```bash
cd parent
(git update-index --cacheinfo 160000,bff56f7a1c9585780950dce5c1964410e0aa2ecc,whatever/path)
git ls-files -s
git add whatever/path
git ls-files -s
```

# 用`.gitmodules`来更新`.git/config`和repo的URL

```bash
cd parent
git config --file=.gitmodules submodule.static/name.url https://localhost
```

- Lv2

```bash
cd parent
git config submodule.static/name.url \
  "$(git config --file=.gitmodules submodule.static/name.url)"
git -C whatever/path remote set-url origin \
  "$(git config --file=.gitmodules submodule.static/name.url)"
```

- Lv3

```bash
cd parent
git submodule sync -- whatever/path
git config --get submodule.static/name.url
git -C whatever/path remote -v
```

# 一次性添加`.gitmodules`、`.git/config`、index、repo、worktree

- Lv2

先添加`.gitmodules`和index，然后用`.gitmodules`更新`.git/config`，
然后用`.git/config`和index创建repo和worktree。

- Lv3

注意：只能指定一个branch，不能指定某个commit。
包括`git fetch`，可能造成大量资源浪费。

```bash
(rm -rf parent && git init --quiet parent)
cd parent
git submodule add -b example-repo0 -f --name static/name -- https://github.com/b1f6c1c4/git-get.git whatever/path
cat .gitmodules
cat .git/config
git ls-files -s
ls -A .git/modules/static/name
ls -A whatever/path
```

# 删除`.git/config`和worktree

- Lv2

```bash
cd parent
git config --remove-section submodule.static/name
rm -rf whatever/path
```

- Lv3

```bash
cd parent
(git submodule --quiet update --init -- whatever/path)
git submodule deinit -f -- whatever/path
cat .gitmodules
cat .git/config
git ls-files -s
ls -A .git/modules/static/name
ls -A whatever/path
```

# 删除`.gitmodules`和index

- Lv2

```bash
cd parent
git config --file=.gitmodules --remove-section submodule.static/name
git update-index --force-remove whatever/path
rm -rf whatever/path
git update-index -fu -- whatever/path
cat .gitmodules
cat .git/config
git ls-files -s
ls -A .git/modules/static/name
ls -A whatever/path
```

- Lv3

```bash
cd parent
(git submodule --quiet add -b example-repo0 -f --name static/name -- https://github.com/b1f6c1c4/git-get.git whatever/path)
git config --file=.gitmodules --remove-section submodule.static/name
git rm -f whatever/path
# 注意：git rm -f 要求先 git add .gitmodules
git add .gitmodules
git rm -f whatever/path
cat .gitmodules
cat .git/config
git ls-files -s
ls -A .git/modules/static/name
ls -A whatever/path
```

非常遗憾的是，repo必须手工`rm -rf`。

# 由repo和worktree创建`.gitmodules`和index

假设如此创建repo和worktree：
```bash
(rm -rf parent && git init --quiet parent)
cd parent
git clone https://github.com/b1f6c1c4/git-get.git whatever/path
```

现在欲将`parent/whatever/path`纳入`parent`当成submodule管理。

- Lv2

```bash
cd parent
git config --file=.gitmodules submodule.static/name.path whatever/path
git config --file=.gitmodules submodule.static/name.url \
  "$(git -C whatever/path config --get remote.origin.url)"
git update-index --add --cacheinfo "160000,$(git -C whatever/path rev-parse HEAD),whatever/path"
git -C whatever/path config core.worktree ../../../../whatever/path
mkdir -p .git/modules/static/
mv whatever/path/.git .git/modules/static/name
echo 'gitdir: ../../.git/modules/static/name' > whatever/path/.git
git submodule status
```

- Lv3

```bash
(rm -rf parent && git init parent)
cd parent
(git clone --quiet https://github.com/b1f6c1c4/git-get.git whatever/path)
# 遗憾的是，没有办法简化前几步
git config --file=.gitmodules submodule.static/name.path whatever/path
git config --file=.gitmodules submodule.static/name.url \
  "$(git -C whatever/path config --get remote.origin.url)"
git update-index --add --cacheinfo "160000,$(git -C whatever/path rev-parse HEAD),whatever/path"
git submodule absorbgitdirs -- whatever/path
git submodule status
```

# 总结

- 一次性添加submodule的五个部分：
  - `git submodule add [-b <branch>] [--name <name>] -- <url> <path>`
- 分别修改submodule的五个部分：
  - `.gitmodules`
    - Lv0: `vim .gitmodules`
    - Lv2: `git config --file=.gitmodules submodule.<name>.<key> <value>`
  - `$GIT_DIR/config`
    - Lv0: `vim .git/config`
    - Lv2: `git config submodule.<name>.<key> <value>`
  - index
    - Lv2：`git update-index [--add|--force-remove] --cacheinfo 160000,<sha1>,<path>`
  - repo (`$GIT_DIR/modules/<name>`)
    - `git -C <path> ...`
  - worktree (`$GIT_WORK_TREE/<path>`)
    - `git -C <path> ...`
- 用静态更新动态：
  - `git submodule init -- <path>`
    - 用`.gitmodules`来更新`.git/config`
  - `git submodule update --init [--recursive] --checkout -- <path>`
    - 用`.gitmodules`和index来创建repo和worktree
  - `git submodule sync -- <path>`
    - 用`.gitmodules`来更新`.git/config`和repo的URL
  - `git gets -- <path>`
    - 快速下载指定commit
- 用静态和动态更新动态：
  - `git submodule update [--recursive] [--checkout|--rebase|--merge] -- <path>`
    - 用`.git/config`和index来更新repo和worktree，共5种选项
- 用动态更新静态：
  - `git update-index -- <path>` - 用repo来更新index
  - `git add <path>` - 用repo来更新index
  - `git submodule absorbgitdirs -- <path>`
    - 有repo、worktree、`.gitmodules`和index之后，用该命令创建`.git/config`并将repo移动到正确位置
- 删除：
  - `git submodule deinit -f -- <path>`
    - 删除`.git/config`和worktree
  - 其他部分需要逐一删除
