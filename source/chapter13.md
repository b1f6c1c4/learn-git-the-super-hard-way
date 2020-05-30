# 基础知识

GnuPG (`gpg`) 可以用来对任意信息对称/非对称加密、签名。
在Git中再次加密意义不大（`git fetch`/`git push`时信道已经是安全的了），但是签名却有很大用处。
Git中有两种对象可以签名：commit和tag。

在开始之前，先导入私钥：
```bash
gpg --armor --import <<EOF
-----BEGIN PGP PRIVATE KEY BLOCK-----

lQHYBF6/LzQBBADbUJy0qahjTV/4LGdqXFr4PPmJQReFTdpIH6GHJuuwxoT4OJ9k
xJiMcAuesf0QYNZc5DnM7uoxRYStNggt/jAln2end8jNaCpUiZ0SyBBlhdv5yGPq
zaUSD7+5Y8GLpd+s/polyGyCX/L9Mn0/rkn0zJfMaRfvQaA+mR7YJjwL1QARAQAB
AAP8DpYUMgzVmvMmtpwHbcLCNx/hDdCjNpW4tpLJ/LHpO4rchaDIcxyDM9Xw4+dd
GCWEpE12jat3Lns76YQ+M4bkH0Dh8UBd+waX68+kcUC+0GH880CawLy3+4PR3wW6
qXYWlwqEA51iL8/3jLIQe8NiohU83SGRkMJho579ZcW92cECAN9x6Qwl/NbFsxP6
eD/xJv/STG0n0Lz48iZ69IIrDAabtSkYjRQrRTqC9f9QB81vCdR6QWCa4Q3mCGm7
KU35QEECAPtEqFzo7s+QgmpqxRoJ8joizO/BDU6jCWnieZSQbFfbyKpod05Z3Zge
7HwRWF12S97g1g2Z8n+HDjmMi5ygJpUCAIOnZK2wgRivsCnTc7AqGRglbPRqMmAz
5p4CNd5LWU8IoBcKAvhX4YEj5/aQ4YYtlPZGVSBa15l7bx7x8syheMWlT7QZU2ln
bmVyIDxzaWduZXJAZ21haWwuY29tPojOBBMBCgA4FiEEs092T1lcEcqWb2lru7hm
2TB0/18FAl6/LzQCGwMFCwkIBwIGFQoJCAsCBBYCAwECHgECF4AACgkQu7hm2TB0
/19GKgQAn3ZfX1+50QNS27c+xhzyJeVutwV6kUsBCSmWYfJ0q4CGbLDMECJ8Sv8X
gJvIC+Ep3gUNZ3oFv1T7ql7tgPbyw99kYWTuhDNtxcPNfBTfULYzzxgrBERITaVC
yO57uB50x88xJUwRNmt2PK/m0hrstmEH6IjaJqKCr/juLjDmnEudAdgEXr8vNAEE
ALhR/Z4xaCi4riHT/2IDoca0CIMp+RwOLQAtK5s+0ldyT8OBUA32J2MiFKOMJw/D
QL3ImBUkKuwRfI6610KkGPTXny5z5b1vOk4QQUncG5UOyFIv8FWep9uZTbnFLzbb
Kj0+HiZoTxJBw99M7b1/4vmjOHj2H4wTN2foHgeL8uXXABEBAAEAA/0SAX8fQ9/9
0Q4VuOeC/tbVb0NA8587Dzl0gcp3kntVgTxrMrKMLUaWEmoQu1bE3UPxpkBmbvo7
GyQ0rz+Vv4ETyNJFEkkf4eltuRHLgC3aav3hGAyVEUnlMgS8bpu6DgiPhE2yJ/x5
d0VBUxzAh8MOVLjlZvONRC8sjFmJA3ibgQIAyU6mUusr3k4OQETWyz+cEHHOw85A
qgWLOc4R0AYF01meV9zNcCVI2jVxyUct5+db01Ndsxk+vpflhHFOUXF3VwIA6mXc
thgDDYqjDWDCZmjT5iCpWINB88MyYUYtcgMlARKVQTqytH6G0TfpzCgGU4XJNM4W
3Nxtc0MC56dB7b11gQH+PyRO79LGXvMw+cVqejU+3VkElraNXrdWuDKeiCXHt0BW
EUg/SjFVomxjktOUfr35CqBMAAayi5JNuR5kCUSnjJbEiLYEGAEKACAWIQSzT3ZP
WVwRypZvaWu7uGbZMHT/XwUCXr8vNAIbDAAKCRC7uGbZMHT/X3YaBACsOjO0kFFk
4nIE2Fl/VawPU0T7vcfgF4MsPoZLSyj9YhQvNJrmPRcetkK4hNOlauS05UHS0nPH
0xONCobsjndOZ8UfS4/qrKRuHpPeA0f5SHnsdAUJNeMt2MCoT9aTU6Pzs2ES+/o9
L93cMAl+Cmb1MeRlT04sWqncgLjJ4zgZ/Q==
=kxtM
-----END PGP PRIVATE KEY BLOCK-----
EOF
gpg --import-ownertrust <<EOF
B34F764F595C11CA966F696BBBB866D93074FF5F:6:
EOF
gpg --list-secret-keys
```

本章在第6章的基础之上继续。

# 创建带签名的commit

- Lv1
```bash
# 首先用gpg对commit的内容进行签名
gpg --armor --detach-sign <<EOF | tee sig
tree a237e8338c09e7d1b2f9749f73f4f583f19fc626
author b1f6c1c4 <b1f6c1c4@gmail.com> 1514736000 +0800
committer b1f6c1c4 <b1f6c1c4@gmail.com> 1514736000 +0800

1=1 2=2
EOF
# 然后添加到gpgsig
git hash-object -t commit --stdin -w <<EOF | tee commit1-a237
tree a237e8338c09e7d1b2f9749f73f4f583f19fc626
author b1f6c1c4 <b1f6c1c4@gmail.com> 1514736000 +0800
committer b1f6c1c4 <b1f6c1c4@gmail.com> 1514736000 +0800
gpgsig$(sed 's/^/ /' sig)

1=1 2=2
EOF
rm sig
git cat-file commit $(cat commit1-a237)
```

- Lv2

```bash
GIT_AUTHOR_NAME=b1f6c1c4 \
GIT_AUTHOR_EMAIL=b1f6c1c4@gmail.com \
GIT_AUTHOR_DATE='1600000000 +0800' \
GIT_COMMITTER_NAME=b1f6c1c4 \
GIT_COMMITTER_EMAIL=b1f6c1c4@gmail.com \
GIT_COMMITTER_DATE='1600000000 +0800' \
git commit-tree a237 -SB34F764F595C11CA966F696BBBB866D93074FF5F <<EOF | tee commit2-a237
1=1 2=2
EOF
git cat-file commit $(cat commit2-a237)
```

- Lv3
```sh
git commit -SB34F764F595C11CA966F696BBBB866D93074FF5F
```

# 验证commit的签名

- Lv1

```bash
git cat-file commit $(cat commit2-a237) | awk 'BEGIN { a=1; } ! /^ / { a=1; } /^gpgsig/ { a=0; } { if (a) print $0; }' | tee cnt
git cat-file commit $(cat commit2-a237) | awk 'BEGIN { a=0; } ! /^ / { a=0; } { if (a) print "gpgsig" $0; if ($1=="gpgsig") { a=$1; print $0; } }' | sed 's/^gpgsig //' | tee sig
gpg --verify sig cnt
rm sig cnt
```

- Lv2

```bash
git verify-commit $(cat commit1-a237)
```

# 创建带签名的tag

- Lv1

```bash
# 首先用gpg对tag的内容进行签名
gpg --armor --detach-sign <<EOF | tee sig
object efd4f82f6151bd20b167794bc57c66bbf82ce7dd
type commit
tag simple-tag
tagger b1f6c1c4 <b1f6c1c4@gmail.com> 1527189535 +0000

The tag message
EOF
# 然后添加到gpgsig
git hash-object -t tag --stdin -w <<EOF | tee tag1-efd4
object efd4f82f6151bd20b167794bc57c66bbf82ce7dd
type commit
tag simple-tag
tagger b1f6c1c4 <b1f6c1c4@gmail.com> 1527189535 +0000

The tag message
$(cat sig)
EOF
rm sig
git update-ref refs/tags/tag1-efd4 $(cat tag1-efd4)
rm tag1-efd4
git cat-file tag tag1-efd4
```

- Lv3
```bash
GIT_COMMITTER_NAME=b1f6c1c4 \
GIT_COMMITTER_EMAIL=b1f6c1c4@gmail.com \
GIT_COMMITTER_DATE='1600000000 +0800' \
git tag -a -m 'The tag message' tag2-0cfb 0cfb -s -u B34F764F595C11CA966F696BBBB866D93074FF5F
git cat-file tag tag2-0cfb
```

# 验证tag的签名

- Lv1

```bash
git cat-file tag tag2-0cfb | awk 'BEGIN { a=1; } /^-----BEGIN PGP SIGNATURE-----/ { a=0; } { if (a) print $0; }' | tee cnt
git cat-file tag tag2-0cfb | awk 'BEGIN { a=0; } /^-----BEGIN PGP SIGNATURE-----/ { a=1; } { if (a) print $0; }' | tee sig
gpg --verify sig cnt
rm sig cnt
```

- Lv2

```bash
git verify-tag tag1-efd4
```

- Lv3
```bash
# stdout输出tag内容，stderr输出签名信息
git tag --verify tag1-efd4 2>tmp
cat tmp
rm tmp
```

# 带签名的tag与merge

第6章中提到，对于带有签名（见第13章）的tag，其被merge时会将其信息存储于新创建的commit的mergetag中，以备后续检查。

首先做好tag：
```bash
GIT_COMMITTER_NAME=b1f6c1c4 \
GIT_COMMITTER_EMAIL=b1f6c1c4@gmail.com \
GIT_COMMITTER_DATE='1600000000 +0800' \
git tag -a -m 'Tag for B' tag-obj-B-signed f1d1 -s -u B34F764F595C11CA966F696BBBB866D93074FF5F
GIT_COMMITTER_NAME=b1f6c1c4 \
GIT_COMMITTER_EMAIL=b1f6c1c4@gmail.com \
GIT_COMMITTER_DATE='1600000000 +0800' \
git tag -a -m 'Tag for C' tag-obj-C-signed br-C -s -u B34F764F595C11CA966F696BBBB866D93074FF5F
```

- Lv1
较为复杂，略

- Lv3

进行merge：
```bash
git update-ref --no-deref HEAD 6784
git -C ../default-tree reset --hard
git -C ../default-tree clean -fdx
GIT_AUTHOR_NAME=b1f6c1c4 \
GIT_AUTHOR_EMAIL=b1f6c1c4@gmail.com \
GIT_AUTHOR_DATE='1600000000 +0800' \
GIT_COMMITTER_NAME=b1f6c1c4 \
GIT_COMMITTER_EMAIL=b1f6c1c4@gmail.com \
GIT_COMMITTER_DATE='1600000000 +0800' \
git -C ../default-tree merge -SB34F764F595C11CA966F696BBBB866D93074FF5F --no-ff 7f24 tag-obj-B-signed tag-obj-E tag-obj-C-signed
git cat-file commit HEAD
```
可以发现带有签名的tag整体出现在了mergetag中。
注意：即便不使用`-S<keyid>`添加`gpgsig`，`mergetag`依然会存在。

验证签名：
```bash
# 注意：即便HEAD自己没有gpgsig，--show-signature依然会检查其mergetag的签名
git show -s --show-signature HEAD
```

# 其他

## 关于`git log`
可以在`git log`中检查签名：
```sh
git log --show-signature
```
然而第8章中的`git lg/la/ls`均已将签名检查融入其中，无需再添加`--show-signature`。

## 关于`git config`

设置`user.signingKey`可以省去每次输入`<keyid>`。
设置`commit.gpgSign`可以在每次`git commit`时都`-S`。
设置`tag.gpgSign`可以在每次`git tag`时都`-a -s`；注意这导致无法创建普通的`refs/tags/...`而不创建tag object。

## 关于GitHub

GitHub对于在网页上作出的更改，会使用以下信息进行签名：
```
fpr: 5DE3 E050 9C47 EA3C F04A  42D3 4AEE 18F8 3AFD EB23
uid: GitHub (web-flow commit signing) <noreply@github.com>
```

为了验证这些commit的有效性，以下两种方法可以二选一：
```sh
curl https://github.com/web-flow.gpg | gpg --import
gpg --search-keys 5DE3E0509C47EA3CF04A42D34AEE18F83AFDEB23
```

# 总结

- 创建签名
  - Lv2
    - `git commit-tree -S[<keyid>] ...`
  - Lv3
    - `git commit -S[<keyid>] ...`
    - `git tag -a -s [-u <keyid>]`
- 验证签名
  - Lv2
    - `git verify-commit <commit-ish>`
    - `git verify-tag <tag-ish>`
  - Lv3
    - `git show -s --show-signature <commit-ish>`
    - `git tag --verify <tag-ish>`
    - `git log --show-signature ...`

