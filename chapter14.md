# 基础知识

Git对象采用独特的方式存放。
理论上说，有了`git hash-object`和`git cat-file`，任何数据都可以导入导出。
然而这样做并不方便；于是有了worktree，可以通过`git update-index`和`git checkout-index`来导入导出数据。
那么有没有这两种方法以外的方式呢？

本章在第1章的基础之上继续。

# tree导入导出：`git archive`

- Lv2
使用`git checkout-index`即可

- Lv3

```bash
date -Ins
# 2020-12-27T22:03:27,794980462+00:00
(git ls-tree efd4)
# 100644 blob ce013625030ba8dba906f756967f9e9ca394464a	name.ext
# 100755 blob ce013625030ba8dba906f756967f9e9ca394464a	name2.ext
git archive --prefix=ar- -o ar.tar efd4^{tree} -- name2.ext
tar tvf ar.tar
# -rwxrwxr-x root/root         6 2020-12-27 22:03 ar-name2.ext
```

反过来则没有简单方法，只能先`tar x`再`git add`

注意：如果指定了一个commit或者tag，则文件的日期会被设置成committer date。
另外commit的SHA1会被存储在tar/zip中的备注，可以通过`git get-tar-commit-id`访问：
```bash
(git show --format=fuller efd4)
# commit efd4f82f6151bd20b167794bc57c66bbf82ce7dd
# Author:     b1f6c1c4 <b1f6c1c4@gmail.com>
# AuthorDate: Sun Sep 13 20:26:40 2020 +0800
# Commit:     b1f6c1c4 <b1f6c1c4@gmail.com>
# CommitDate: Sun Sep 13 20:26:40 2020 +0800
#
#     Message may be read
#     from stdin
#     or by the option '-m'
git archive --prefix=ar- -o ar-c.tar efd4 -- name2.ext
tar tvf ar-c.tar --full-time
# -rwxrwxr-x root/root         6 2020-09-13 12:26:40 ar-name2.ext
git get-tar-commit-id <ar.tar
git get-tar-commit-id <ar-c.tar
# efd4f82f6151bd20b167794bc57c66bbf82ce7dd
```

# 任意对象导入导出

- 二进制格式 - `git bundle create` / `git bundle unbundle` - 参见第5章
- 适合于机器的文本格式（类似与脚本） - `git fast-export` / ` git fast-import`
- 适合于人类的文本格式（类似于e-mail）
  - `git format-patch` / `git am`
  - `git request-pull`
  - `git send-email` / `git imap-send`

然而真正需要这些的场景实在太罕见了——上传至GitHub就可以非常好地完成数据的导入导出功能——
这些命令也就不再介绍了。

# 与其他版本控制软件交互操作

节选自`git help -a`：
```
   Interacting with Others
      archimport           Import a GNU Arch repository into Git
      cvsexportcommit      Export a single commit to a CVS checkout
      cvsimport            Salvage your data out of another SCM people love to hate
      cvsserver            A CVS server emulator for Git
      p4                   Import from and submit to Perforce repositories
      quiltimport          Applies a quilt patchset onto the current branch
      svn                  Bidirectional operation between a Subversion repository and Git
```

# 总结

- 常用Lv3
  - `git archive [--prefix=<prefix>] [-o <output>] <tree-ish> -- <path>...`
- 不常用
  - `git bundle create` / `git bundle unbundle` - 参见第5章
  - `git fast-export` / ` git fast-import`
  - `git format-patch` / `git am` / `git request-pull` / `git send-email` / `git imap-send`
