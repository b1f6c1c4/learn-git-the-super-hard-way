以下命令只需知道其存在，到了真正需要用到的时候再查询其帮助也不迟。

# Git批处理

一些复杂的Git操作需要利用xargs。而Git提供了一些化简的办法。

- `git for-each-ref` - 对每个引用进行处理（比`git show-ref`更灵活）
- `git filter-branch` - 对每个commit进行处理（比`git rebase`更灵活）
- `git submodule foreach --recursive` - 对每个submodule进行处理

# 自动化debug

- `git bisect` - 二分查找法定位bug位于哪个commit

# 在特定情况下执行特定脚本：hooks

- `vim .git/hooks/pre-commit` - 在commit前做检查
- `vim .git/hooks/commit-msg` - 自动撰写commit message
- `vim .git/hooks/pre-push` - 在push前做检查
- `vim .git/hooks/...`

# 自动处理CRLF/LF

- `git config --global core.autocrlf true|false|input`

# 自动处理行尾/文件末尾空格

- `git stripspace`
- `git config --global core.whitespace ...`
