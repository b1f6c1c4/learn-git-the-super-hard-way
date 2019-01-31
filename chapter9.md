# 第9章：配置和alias

## 全局gitignore

```bash
cat - <<EOF > ~/.gitignore
*~
*.swp
*.swo
EOF
git config --global core.excludesfile ~/.gitignore
```

## 常用Lv3 -> Lv4

仅缩写：
```bash
git config --global alias.cm commit
git config --global alias.co checkout
git config --global alias.br branch
git config --global alias.fe fetch
git config --global alias.cp cherry-pick
git config --global alias.br branch
```

常用参数：
```bash
git config --global alias.st status -sb
git config --global alias.branches branch -av
git config --global alias.remotes remote -v
git config --global alias.lf log -u
git config --global alias.ch cherry -v
git config --global alias.mf merge --ff-only
git config --global alias.mnf merge --no-ff
git config --global alias.mnfnc merge --no-ff --no-commit
git config --global alias.dc diff --cached
git config --global alias.pf pull --ff-only
git config --global alias.pt push --follow-tags
git config --global alias.pn push --no-verify
git config --global alias.pnf push --no-verify --force-with-lease
git config --global alias.fp fetch -p
git config --global alias.fpa fetch -p --all
git config --global alias.clones clone --depth=1
```

暴力commit：
```bash
git config --global alias.cm commit
git config --global alias.cma commit --amend -C HEAD
git config --global alias.cmn commit --no-verify
git config --global alias.cmna commit --no-verify --amend -C HEAD
git config --global alias.ac '!git add -A && git commit'
git config --global alias.acma '!git add -A && git commit --amend -C HEAD'
git config --global alias.acmn '!git add -A && git commit --no-verify'
git config --global alias.acmna '!git add -A && git commit --no-verify --amend -C HEAD'
```

## Lv5

（摘自第6章）
有一类merge情况是，需要用其他分支 *完全取代* 当前分支的某一目录。
```bash
function git-mnfss() {
  git rm --cached -r -- $1
  git read-tree --prefix $1/ $1
  git checkout-index -fua
  git clean -f -- $1
  git reset --soft $(echo "Merge branch $1" | git commit-tree $(git write-tree) -p HEAD -p $1)
}
```
