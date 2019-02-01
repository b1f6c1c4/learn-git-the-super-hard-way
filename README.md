# learn-git-the-super-hard-way

## 目录

0. 创建工作环境（手工`git init`）
1. 直接操纵对象（手工`git commit`）
2. 直接操纵引用（手工`git branch`）
3. 直接操纵索引（手工`git add`）
4. 直接操纵HEAD（`git checkout`和`git reset`）
5. 直接操纵远程（手工`git pull`）
6. 直接操纵merge（手工`git diff`和`git merge`）
7. 直接操纵commit（手工`git rebase`）
8. 单repo多分支工作流
9. 配置和alias

## 本教程适用范围

（以下几个条件同时满足）
- 对Linux命令行有所了解
- 有探索精神和造轮子精神
- 希望系统地学习Git

## 本教程不适用范围

（以下几个条件满足任意一条）
- 完全没用过命令行或者太不熟练
- 拒绝主动思考，只想着别人告诉你答案
- 希望尽快学会Git开始工作
- 赶DDL

## 和其他Git学习资料配合使用

方案一：从简单到困难
- 看任意一份快速入门教程
- 学习简单的命令行
- 看官网Tutorial
- 学习命令行
- 清空原有的知识，看本教程
- 回顾官网Tutorial，牢记日常Git操作
- 日常只需要使用普通Git操作就好，遇到困难问题再复习本教程

方案二：从困难到简单
- 学习命令行
- 扫一眼官网Tutorial，了解Git的目的
- 清空原有的知识，看本教程
- 看官网Tutorial，牢记日常Git操作
- 日常只需要使用普通Git操作就好，遇到困难问题再复习本教程

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

work-tree默认为.，但并非所有命令都涉及worktree
git-dir默认为./.git：
若./.git是目录，则就以该目录为repo
若./.git是文件，则以该文件内容（一般会是绝对路径）为repo
```bash
git [--git-dir=<repo>] [--work-tree=<worktree>] <command> [args]
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

