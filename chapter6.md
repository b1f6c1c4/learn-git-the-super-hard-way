# 第6章：直接操纵commit

## 基础知识

从物理结构上讲，一个commit表示一个完整的版本；
但是，从逻辑结构上将，一个commit还可以表示 *相比于之前进行了哪些修改* 。

本章中涉及worktree的命令会明确标出。

## 查看更改

在开始之前，先创建几个对象：
```bash
echo '1' | git hash-object -t blob --stdin -w
# d00491fd7e5bb6fa28c517a0bb32b8b506539d4d
echo '2' | git hash-object -t blob --stdin -w
# 0cfbf08886fca9a91cb753ec8734c84fcbe52c9f
echo '3' | git hash-object -t blob --stdin -w
# 00750edc07d6415dcc07ae0351e9397b0222b7ba
echo '4' | git hash-object -t blob --stdin -w
# b8626c4cff2849624fb67f87cd0ad72b163671ad
echo '5' | git hash-object -t blob --stdin -w
# 7ed6ff82de6bcc2a78243fc9c54d3ef5ac14da69
echo '6' | git hash-object -t blob --stdin -w
# 1e8b314962144c26d5e0e50fd29d2ca327864913
echo '7' | git hash-object -t blob --stdin -w
# 7f8f011eb73d6043d2e6db9d2c101195ae2801f2
git mktree <<EOF
100644 blob d00491fd7e5bb6fa28c517a0bb32b8b506539d4d	1.txt
100755 blob 0cfbf08886fca9a91cb753ec8734c84fcbe52c9f	2.txt
EOF
# a237e8338c09e7d1b2f9749f73f4f583f19fc626
git mktree <<EOF
100644 blob d00491fd7e5bb6fa28c517a0bb32b8b506539d4d	1.txt
100755 blob 00750edc07d6415dcc07ae0351e9397b0222b7ba	3.txt
EOF
# aa250e2798646facc12686e4403ccadbf1565d51
git hash-object -t commit --stdin -w <<EOF
tree a237e8338c09e7d1b2f9749f73f4f583f19fc626
author b1f6c1c4 <b1f6c1c4@gmail.com> 1514736000 +0800
committer b1f6c1c4 <b1f6c1c4@gmail.com> 1514736000 +0800

1=1 2=2
EOF
# 4cfe841426d0435270d049625a766130c108f4c8
git hash-object -t commit --stdin -w <<EOF
tree aa250e2798646facc12686e4403ccadbf1565d51
parent 4cfe841426d0435270d049625a766130c108f4c8
author b1f6c1c4 <b1f6c1c4@gmail.com> 1514736000 +0800
committer b1f6c1c4 <b1f6c1c4@gmail.com> 1514736000 +0800

1=1 3=3
EOF
# afc38c96c82ea65991322a5d28995b0851ff7edd
```

- Lv2

基于第一个tree-ish，查看第二个tree-ish的修改：
```bash
git diff-tree a237 aa25
# :100755 000000 0cfbf08886fca9a91cb753ec8734c84fcbe52c9f 0000000000000000000000000000000000000000 D      2.txt
# :000000 100755 0000000000000000000000000000000000000000 00750edc07d6415dcc07ae0351e9397b0222b7ba A      3.txt
git diff-tree a237 aa25 -- 2.txt
# :100755 000000 0cfbf08886fca9a91cb753ec8734c84fcbe52c9f 0000000000000000000000000000000000000000 D      2.txt
git diff-tree afc3
# afc38c96c82ea65991322a5d28995b0851ff7edd
# :100755 000000 0cfbf08886fca9a91cb753ec8734c84fcbe52c9f 0000000000000000000000000000000000000000 D      2.txt
# :000000 100755 0000000000000000000000000000000000000000 00750edc07d6415dcc07ae0351e9397b0222b7ba A      3.txt
```

基于tree-ish，查看index的修改：
```bash
git read-tree a237
git diff-index --cached aa25
# :000000 100755 0000000000000000000000000000000000000000 0cfbf08886fca9a91cb753ec8734c84fcbe52c9f A      2.txt
# :100755 000000 00750edc07d6415dcc07ae0351e9397b0222b7ba 0000000000000000000000000000000000000000 D      3.txt
```

基于tree-ish，查看worktree的修改：
```bash
rm -rf ../default-tree/*
git --work-tree=../default-tree diff-index aa25
# :100644 000000 d00491fd7e5bb6fa28c517a0bb32b8b506539d4d 0000000000000000000000000000000000000000 D      1.txt
# :100755 000000 00750edc07d6415dcc07ae0351e9397b0222b7ba 0000000000000000000000000000000000000000 D      3.txt
```

基于index，查看worktree的修改：
```bash
git --work-tree=../default-tree diff-files
# :100644 000000 d00491fd7e5bb6fa28c517a0bb32b8b506539d4d 0000000000000000000000000000000000000000 D      1.txt
# :100755 000000 0cfbf08886fca9a91cb753ec8734c84fcbe52c9f 0000000000000000000000000000000000000000 D      2.txt
```

- Lv3

* `git diff <tree-ish> <tree-ish> -- [<path>]` 相当于 `git diff-tree -p <tree-ish> <tree-ish> -- [path]`
* `git show <commit-ish> -- [<path>]` 相当于 `git diff-tree -p <commit-ish> -- [<path>]`
* `git diff [<tree-ish>] -- [<path>]` 相当于 `git diff-index -p [<tree-ish>] -- [<path>]`
* `git diff --cached [<tree-ish>] -- [<path>]` 相当于 `git diff-index -p --cached [<tree-ish>] -- [<path>]`
* `git diff -- <path>` 相当于 `git diff-files -p <path>`

## 处理修改

类似于`git bundle create`将若干对象打包成字节流以便离线传送，`git diff-* -p|--patch`将修改打包成字节流以便离线传送。
类似于`git bundle unbundle`将字节流解包成对象，`git apply`将字节流解包出修改。
需要注意的是，`--patch`产生的是human-readable data，但`git bundle`是machine-readable only。

打包修改：
```bash
git diff-tree --patch a237 aa25 | tee ../the.patch
# diff --git a/2.txt b/2.txt
# deleted file mode 100755
# index 0cfbf08..0000000
# --- a/2.txt
# +++ /dev/null
# @@ -1 +0,0 @@
# -2
# diff --git a/3.txt b/3.txt
# new file mode 100755
# index 0000000..00750ed
# --- /dev/null
# +++ b/3.txt
# @@ -0,0 +1 @@
# +3
```

解包修改至worktree:
```bash
rm -rf ../default-tree/*
git read-tree a237
git --work-tree=../default-tree checkout-index -f -a
ls ../default-tree
# 1.txt  2.txt
git --work-tree=../default-tree apply ../the.patch
ls ../default-tree
# 1.txt  3.txt
git ls-files -s
# 100644 d00491fd7e5bb6fa28c517a0bb32b8b506539d4d 0       1.txt
# 100755 0cfbf08886fca9a91cb753ec8734c84fcbe52c9f 0       2.txt
```

解包修改至index：
```bash
git ls-files -s
# 100644 d00491fd7e5bb6fa28c517a0bb32b8b506539d4d 0       1.txt
# 100755 0cfbf08886fca9a91cb753ec8734c84fcbe52c9f 0       2.txt
git apply --cached ../the.patch
git ls-files -s
# 100644 d00491fd7e5bb6fa28c517a0bb32b8b506539d4d 0       1.txt
# 100755 00750edc07d6415dcc07ae0351e9397b0222b7ba 0       3.txt
ls ../default-tree
# 1.txt  2.txt
```

## 合并修改

TODO

## 移动commit

TODO

## 总结

- 查看和处理修改
  - Lv2
    - `git diff-tree [-p] <tree-ish> <tree-ish> -- <path>`
    - `git diff-tree [-p] <commit-ish> -- <path>`
    - `git diff-index [-p] [--cached] <tree-ish> -- <path>`
    - `git diff-files [-p] <path>`
    - `git apply [--cached] <patch> -- <path>`
  - Lv3
    - `git diff <tree-ish> <tree-ish> -- <path>`
    - `git show <commit-ish> -- <path>`
    - `git diff [--cached] <tree-ish> -- <path>`
    - `git diff -- <path>`

