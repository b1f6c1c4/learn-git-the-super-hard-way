# learn-git-the-super-hard-way

## 目录

0. 创建工作环境（手工`git init`）
1. 直接操纵对象（手工`git commit`）
2. 直接操纵引用（手工`git branch`）
3. TODO: 直接操纵索引（手工`git add`）
4. TODO: 直接操纵远程（手工`git pull`）
5. TODO: 直接操纵commit（手工`git rebase`）
6. TODO: 单repo多分支工作流
7. TODO: 配置和alias

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

`git(1)`的核心用法：
```bash
# 基本用法如下
# work-tree默认为.，但并非所有命令都涉及worktree
# git-dir默认为./.git：
# 若./.git是目录，则就以该目录为repo
# 若./.git是文件，则以该文件内容（一般会是绝对路径）为repo
git [--git-dir=<repo>] [--work-tree=<worktree>] <command> [args]
# 大部分命令的参数列表遵循以下格式：
# object是对象的表达式，一般由引用、对象SHA1、^、~、:等构成，完整列表参见`git rev-parse`（Lv2）
# path是以路径
# --在不引起歧义的情况下可以省略
# 注意：是否存在<path>参数可能对语义有本质的影响
git <command> [options] [<object>] -- [<path>]
```
