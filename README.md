# learn-git-the-super-hard-way

[GitBook](https://app.gitbook.com/@b1f6c1c4/s/learn-git-the-super-hard-way/)

## 目录

0. [创建工作环境](chapter0.md)（`git init`）
1. [直接操纵对象](chapter1.md)（`git commit`）
2. [直接操纵引用](chapter2.md)（`git branch`）
3. [直接操纵索引](chapter3.md)（`git add / restore`）
4. [直接操纵HEAD](chapter4.md)（`git switch`）
5. [直接操纵远程](chapter5.md)（`git pull / push`）
6. [直接操纵merge](chapter6.md)（`git diff / merge`）
7. [直接操纵commit](chapter7.md)（`git rebase`）
8. [检索与查看历史](chapter8.md)（`git log / blame / grep`）
9. [邪恶的submodule](chapter9.md)（`git submodule`）
10. [批处理与自动化](chapter10.md)
11. [配置和alias](chapter11.md)（`git config`）
12. [单repo多分支工作流](chapter12.md)
13. [GPG签名](chapter13.md)
14. [数据的导入和导出](chapter14.md)（`git archive`）
15. [数据抢修与急救](chapter15.md)

**本教程还提供了[cheatsheet](cheatsheet.md)**，可以用来复习并检查学习效果。
如果你已经完全掌握cheatsheet里面的所有命令，那么此教程可能对你来说太过浅显，建议移步[Git Reference](https://git-scm.com/docs)、[Git源码](https://github.com/git/git)。

学习完本教程以后，你应该掌握了git的全部用法的2%。

备注：`git reset`/`git checkout`的详解在第4章。强烈推荐改用功能更强大更直观的`git restore`和`git switch`。

## 先修课程

本教程要求学习者提前学习Linux命令行的基础知识。
请参考[第-1章：Linux命令行复习](chapter-1.md)。

## 基本约定

为了更为本质地了解Git，本文会对同一种操作介绍多种不同的实现方法。
下表描述了不同使用场景下应该如何选择最适合的实现方法。

| 等级 | 含义 | 使用场景 |
| --- | --- | --- |
| Lv0 | 纯粹手工实现，完全不使用Git命令行 | 学习Git内部结构时 |
| Lv1 | 使用底层Git命令行配合手工实现 | 实现极为特殊的Git操作时 |
| Lv2 | 使用底层Git命令行实现 | 实现非常规Git操作时 |
| Lv3 | 使用常规Git命令行实现 | 日常使用 |
| Lv4 | Git Alias | 对Git进行扩展，日常使用 |
| Lv5 | 编写脚本调用Git命令行 | 对Git进行非常规扩展，偶尔使用 |

## Git命令行基础

### 全局命令行参数

- cwd默认为.，表示先cd到那里再运行后续命令
- work-tree默认为`GIT_WORK_TREE`或者`.`，但并非所有命令都涉及worktree
- git-dir默认为`GIT_DIR`或者`./.git`：
  - 若./.git是目录，则就以该目录为repo
  - 若./.git是文件，则以该文件内容（一般会是绝对路径）为repo

```bash
git [-C <cwd>] [--git-dir=<repo>] [--work-tree=<worktree>] <command> [args]
```

### 具体Git命令的参数

大部分命令的参数列表遵循以下格式：
- object是对象的表达式
  - 一般由引用、对象SHA1、^、~、:等构成
  - 完整列表参见`git rev-parse`（Lv2）
- path是路径
- `--`在不引起歧义的情况下可以省略

注意：是否存在`<path>`参数可能对语义有本质的影响

```bash
git <command> [options] [<object>]
git <command> [options] [<object>] -- [<path>]
```

## Git命令列表

本教程涵盖所有的Git常用命令和一半以上的Git非常用命令，
参见[Roadmap](ROADMAP.md)

## License

<a rel="license" href="http://creativecommons.org/licenses/by-nc-sa/4.0/"><img alt="Creative Commons License" style="border-width:0" src="https://i.creativecommons.org/l/by-nc-sa/4.0/88x31.png" /></a><br />This work is licensed under a <a rel="license" href="http://creativecommons.org/licenses/by-nc-sa/4.0/">Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International License</a>.
