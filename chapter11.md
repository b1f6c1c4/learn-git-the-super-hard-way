# 全局gitignore

```bash
cat - >~/.gitignore <<EOF
*~
*.swp
*.swo
EOF
git config --global core.excludesfile ~/.gitignore
```

# Lv3, Lv4

* [shared-git-config](https://github.com/b1f6c1c4/shared-git-config)

# Lv5

（摘自第6章）
有一类merge情况是，需要用其他分支 *完全取代* 当前分支的某一目录。
```sh
git-mnfss() {
  git rm --cached -r -- $1
  git read-tree --prefix $1/ $1
  git checkout-index -fua
  git clean -f -- $1
  git reset --soft $(echo "Merge branch $1" | git commit-tree $(git write-tree) -p HEAD -p $1)
}
```

* [git-freeze](https://github.com/b1f6c1c4/git-freeze)
* [git-get](https://github.com/b1f6c1c4/git-get)
