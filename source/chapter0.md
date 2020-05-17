# 第0章：创建工作环境

## 基础知识

- Git是一个著名的版本控制软件。它将软件的版本（代码+配置+测试+……）存放在一种特殊的数据库（Git repo）中。通过执行一些命令用户可以对数据库中的软件的版本进行增删改查等操作。
- 在绝大多数情况下，Git repo的具体形式是硬盘上的一个文件夹。
- 为了方便用户操作，每一个repo都可以配套一个worktree（但是至多只能有一个，可以没有）。worktree也是一个硬盘上的文件夹，它将和repo配合使用。
- 为了方便多个repo之间共享数据，一个repo可以放弃所有对象（第1章）和绝大部分引用（第2章）等信息的所有权，将其全权托管给另一个repo。这种所谓链接只能在同一台计算机上实现。
  - 很多人认为一个repo可以有多个worktree，严格意义上讲其实是有好多个repo都链接到了同一个repo，每一个小repo贡献一个worktree，看起来是一个大repo有多个worktree的样子。

## 创建Git repo并选配worktree

### Lv0

```bash
# Git repo以.git结尾只是惯例
mkdir the-repo.git
# 所有的Git repo都必须包括objects文件夹，用来保存对象
mkdir the-repo.git/objects
# 所有的Git repo都必须包括refs文件夹，用来保存普通引用
mkdir the-repo.git/refs
# 所有的Git repo都必须包括HEAD文件（这是一个特殊引用）
# 但是HEAD指向的目标不一定需要真实存在
# 在初始化时指向refs/heads/master只是惯例
echo 'ref: refs/heads/master' > the-repo.git/HEAD
```

至此一个最简单的Git repo创建完毕，采用`git symbolic-ref`（Lv2）检验是否创建成功：
```bash
# Git需要知道repo在哪里，用--git-dir来指定
# 将在第2章详细介绍此命令
git --git-dir=the-repo.git symbolic-ref HEAD
```

现在添加worktree：
```bash
# worktree不需要进行任何复杂操作
# 任意文件夹都可以被视作worktree
mkdir default-tree
```

采用`git status`（Lv3）检验是否创建成功：
```bash
# Git需要知道worktree在哪里，用--work-tree来指定
# 将在第3章详细介绍此命令
git --git-dir=the-repo.git --work-tree=default-tree status
```

每次调用git命令都需要手工指定repo和worktree的位置非常麻烦。
绝大多数情况下，worktree和repo是一一对应的。
为了简化命令行调用方式，可以在worktree下添加.git文件：
```bash
echo "gitdir: $(pwd)/the-repo.git" > default-tree/.git
```
这样的话Git就有办法根据worktree的位置找到repo的位置了。
然而非常遗憾的是，以下命令并不能成功：
```bash
git --work-tree=default-tree status
```
原因是`--work-tree`必须和`--git-dir`配合使用。
解决办法就是`cd`过去：
```bash
cd default-tree
git status
```
另外一种办法是使用`-C`，表示先执行`cd`再执行`git`
```bash
git -C default-tree status
```

注意`cd`进repo有时会报错，因为目前没有任何办法从repo找到worktree，
而一部分命令必须要有worktree才能正常工作（比如`git status`）：
```bash
git -C the-repo.git symbolic-ref HEAD
git -C the-repo.git status
```

再进一步，如果希望避免使用绝对路径（repo移动了位置依然可以找到），
可以把repo放在worktree里面：
```bash
# 删掉.git文件
rm default-tree/.git
# worktree里面的.git不再是文件了，它就是repo！
mv the-repo.git default-tree/.git

# 检查一下：
git -C default-tree symbolic-ref HEAD
git -C default-tree status
git -C default-tree/.git symbolic-ref HEAD
# 下面这个命令依然报错，原因同上
git -C default-tree/.git status
```

### Lv3

日常创建repo、不选配worktree：
```bash
(rm -rf the-repo.git) # 重新开始，删掉之前的repo
git init --bare the-repo.git
```

日常创建repo、选配worktree、把repo放在worktree里面：
```bash
(rm -rf default-tree) # 重新开始，删掉之前的worktree
git init default-tree
```

日常创建repo、选配worktree、把repo和worktree分开放置：
```bash
(rm -rf the-repo.git default-tree)
git init --separate-git-dir the-repo.git default-tree
```

## 添加新repo并链接到原repo，以实现“一个repo多个worktree”

### Lv0

```bash
(rm -rf the-repo.git default-tree) # 删掉之前的东西
(git init --bare the-repo.git) # 现在我们有一个repo但没有worktree

# 惯例是将小repo放在这个位置：
# 请注意，虽然路径名称写了个worktrees，但是这里真正放的还是repo
mkdir -p the-repo.git/worktrees/another/

# 为了和大repo建立起联系，创建commondir文件：
# 文件内容就是大repo相对于小repo的路径
echo '../..' > the-repo.git/worktrees/another/commondir

# 小repo无需objects或者refs

# 小repo也是repo，必须要有HEAD
# 注意：让不同worktree的HEAD指向同一个引用会导致一个worktree的修改影响另一个
# 这虽然合法但是违背了worktree的初衷
echo 'ref: refs/heads/another' > the-repo.git/worktrees/another/HEAD
```

至此一个最简单的小repo创建完毕，采用`git symbolic-ref`（Lv2）检验是否创建成功：
```bash
# 特别注意此处的git-dir已经发生变化
git --git-dir=the-repo.git/worktrees/another symbolic-ref HEAD

# 下面这样也可以
git -C the-repo.git/worktrees/another symbolic-ref HEAD
```

和普通repo一样，添加worktree非常简单：
```bash
mkdir another-tree
```

采用`git status`（Lv3）检验是否创建成功：
```bash
git --git-dir=the-repo.git/worktrees/another --work-tree=another-tree status
```

给小repo简化命令行调用方式完全相同：
```bash
echo "gitdir: $(pwd)/the-repo.git/worktrees/another" > another-tree/.git
git -C another-tree status
```

现在小repo知道大repo的存在，但是大repo却不知道小repo的存在。
这不太合理。为此需要登记一下小repo的位置。
这样做的好处是`git worktree list`（Lv3）中可以正确地列举出小repo。
```bash
# 在登记之前，git worktree list没有任何发现，指定小repo也没用
git --git-dir=the-repo.git worktree list
git --git-dir=the-repo.git/worktrees/another worktree list

# 现在进行登记：将小repo的worktree的.git文件的绝对路径登记在小repo的gitdir中
echo "$(pwd)/another-tree/.git" > the-repo.git/worktrees/another/gitdir

# 非常令人困惑的是，这看似跟大repo没有什么关系，但这样做确实有用：
git --git-dir=the-repo.git worktree list

# 注意此处git-dir写大repo还是小repo都能得到一样的结果
git --git-dir=the-repo.git/worktrees/another worktree list

# 即便.git文件被删掉了，这种联系依然还能暂时存在：
rm another-tree/.git
git --git-dir=the-repo.git worktree list
git --git-dir=the-repo.git/worktrees/another worktree list
# 但是需要注意的是，此时执行git worktree prune将会删除整个小repo：
# 参考本章后面关于git worktree prune的描述
## git --git-dir=the-repo.git worktree prune
## ls the-repo.git/worktrees/
## # ls: cannot access 'the-repo.git/worktrees/': No such file or directory
# 把.git加回来，以免之后误git worktree prune
(echo "gitdir: $(pwd)/the-repo.git/worktrees/another" > another-tree/.git)
```

注意：如果没有遵循惯例把小repo放在大repo的`worktrees/xxx`位置，
那么gitdir文件还是必须往同样的位置去放，即便那里已经不是小repo了：
```bash
# 在奇怪的位置创建小repo并选配worktree
mkdir -p third-repo.git third-tree
echo '../the-repo.git' > third-repo.git/commondir
echo 'ref: refs/heads/third' > third-repo.git/HEAD
echo "gitdir: $(pwd)/third-repo.git" > third-tree/.git

# 检查小repo是否创建成功
git -C third-tree status

# 建立联系：把gitdir放在跟之前一样的位置，即便那里不是小repo
mkdir the-repo.git/worktrees/third/
echo "$(pwd)/third-tree/.git" > the-repo.git/worktrees/third/gitdir

# 检查大小repo是否有联系
git --git-dir=the-repo.git worktree list
git --git-dir=the-repo.git/worktrees/another worktree list
git --git-dir=third-repo.git worktree list
```
可以看到，虽然不在常规位置的小repo能够被成功识别，
但是`git worktree list`却无法正确列出其HEAD的内容。

### Lv3

使用`git worktree add`可以添加小repo并选配worktree。
然而该命令至少需要一个commit对象才能正常工作。
这里就不演示了。
该命令语法是：
```sh
git --git-dir=the-repo.git worktree add [--no-checkout] <worktree> <commit-ish>
```
此处的`--no-checkout`是用来指示是否要在创建完worktree以后执行`git restore -W`。参见第3章。

## 删除小repo

### Lv0

```sh
# 直接删掉
rm -rf the-repo.git/worktrees/another
# gitdir在上一行也跟着删掉了，不用再来一次了
# rm -rf the-repo.git/worktrees/another/gitdir
# 这个其实可以不删，不过留着容易让人误会
rm -f another-tree/.git
```

### Lv3

```bash
# 删掉the-repo.git/worktrees/another/gitdir所指向的对象
rm -f another-tree/.git
# 主动让git检验各个worktree是否存在；
# 在发现the-repo.git/worktrees/another/的worktree已经找不到了之后，
# 它会主动删掉对应的小repo（由于是小repo，所以基本不会损失什么数据）：
# 注意：此处填写小repo，甚至填写另一个小repo都是可以的
git --git-dir=the-repo.git worktree list
git --git-dir=the-repo.git worktree prune
git --git-dir=the-repo.git worktree list
```

## 基于别的repo创建新的repo

除了创建空白repo以外，还有一种方法是基于另一个repo创建新的repo。这个功能非常有用：GitHub上有很多repo，如果能够直接将其复制下来，或者说基于它创建自己的repo，那么就能够在别人的基础之上进行修改了。
这个功能涉及到远程文件传输，因此在第5章中会详细介绍。

## 总结

（以下均为Lv3）
- 创建空repo，选配worktree
  - `git init --bare <repo>` - 不要worktree
  - `git init --separate-git-dir <repo> <worktree>`
  - `git init <worktree>` - repo在`<worktree>/.git`
- “单”repo多worktree
  - `git worktree list`
  - `git worktree add [--no-checkout] <worktree> <commit-ish>`
  - `git worktree prune`

## 扩展阅读

[gitrepository-layout](https://git-scm.com/docs/gitrepository-layout)

