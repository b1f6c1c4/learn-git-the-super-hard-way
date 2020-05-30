# 基础知识

误操作可能引起数据丢失或者软件版本错误。
Git有许多机制可以最小化误操作引起的实际损失。
而灵活运用各种Git命令也可以修正各种错误。

# 可能引起数据丢失的误操作

## 严重误操作

- 误删整个repo（`rm -rf .git`）
    - 立即备份worktree，避免进一步损失
    - 如果所有分支都已push到远端，可以考虑再fetch回来
    - 如果有的commit尚未push，请参考[File recovery](https://wiki.archlinux.org/index.php/File_recovery)
- 误删整个worktree，但是repo还在
    - 对于存在在index中的文件，`git restore --worktree`
    - 对于尚未`git add`的部分，请参考[File recovery](https://wiki.archlinux.org/index.php/File_recovery)
- 误删整个repo和整个worktree
    - 参考以上两条

## 引用误操作

- 在HEAD是直接引用时执行了`git switch`
    - 查看误操作命令的输出，其中包含了HEAD曾经指向的SHA1
    - `git reflog`
- 误操作`git reset --soft`
    - `git reflog`
- 误操作`git branch|tag -f`
    - `git reflog`
- 误操作`git branch|tag -d|-D`
    - 查看误操作命令的输出，其中包含了该引用曾经指向的SHA1
    - 可以尝试`git fsck`，列出所有没有被任何引用/对象所使用的对象的SHA1，然后逐一检查
    - 亦可参考[File recovery](https://wiki.archlinux.org/index.php/File_recovery)，但不推荐
- 误操作`git rebase`
    - 若rebase还在进行，立刻`git rebase --abort`
    - `git reflog`

## worktree的误操作

- 误操作`rm -rf`了worktree的文件
    - 如果尚未`git add`，请参考[File recovery](https://wiki.archlinux.org/index.php/File_recovery)；否则：
    - 对于普通文件/文件夹，`git restore --worktree`
    - 对于submodule，`git submodule update`
- 误操作`git clean`了worktree的文件
    - 请参考[File recovery](https://wiki.archlinux.org/index.php/File_recovery)
- 误操作`git restore --worktree`
    - **这是最危险的情况之一**，唯一的希望是编辑器的缓存。在编辑器里面看一看相应的文件是否从硬盘上重新读取了；如果有，尝试撤销再保存；如果没有，尝试保存。

## index的误操作

- 误操作`git add`覆盖了index中的记录
    - 一般来说index中的记录的对象都应该在repo中存在，故`git fsck`列出所有blob然后再逐一检查即可
    - 然而真正操作起来相当复杂且繁琐，需谨慎
- 误操作`git rm --cached`删除的index中的记录
    - 如果worktree中的文件还在且内容正确，再次`git add`即可
    - 同之前关于误操作`git add`的讨论
- 误操作`git reset [--mixed]`
    - 你可能需要`git reflog`找回HEAD
    - 同之前关于误操作`git add`的讨论
- 误操作`git restore --staged`或者`git read-tree`
    - 同之前关于误操作`git add`的讨论

## index和worktree同时误操作

思路是完全一致的：优先解决worktree的问题，然后再找回index。

- 误操作`git rm -rf`
- 误操作`git reset --hard`
- 误操作`git restore --staged --worktree`
- 误操作`git switch -f`

