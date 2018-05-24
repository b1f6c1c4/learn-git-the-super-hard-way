# learn-git-the-super-hard-way

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
# object是对象的表达式（一般由引用、对象SHA1、^、~等构成）
# path是以路径
git <command> [options] <object> -- <path>
```
