```bash
git init --separate-git-dir "$PWD" ../default-tree
```

100644 blob d00491fd7e5bb6fa28c517a0bb32b8b506539d4d$(printf '\t')1.txt
100755 blob 0cfbf08886fca9a91cb753ec8734c84fcbe52c9f$(printf '\t')2.txt
100644 blob d00491fd7e5bb6fa28c517a0bb32b8b506539d4d$(printf '\t')1.txt
100755 blob 00750edc07d6415dcc07ae0351e9397b0222b7ba$(printf '\t')3.txt
git --work-tree=../default-tree checkout-index -fu -a
git -C ../default-tree apply ../the.patch
cat >fileA <<EOF
cat >fileB <<EOF
cat >fileC <<EOF
cat >fileD <<EOF
100644 blob d00491fd7e5bb6fa28c517a0bb32b8b506539d4d$(printf '\t')1.txt
100755 blob 0cfbf08886fca9a91cb753ec8734c84fcbe52c9f$(printf '\t')2.txt
100755 blob b8626c4cff2849624fb67f87cd0ad72b163671ad$(printf '\t')4.txt
100644 blob d00491fd7e5bb6fa28c517a0bb32b8b506539d4d$(printf '\t')1.txt
100755 blob b8626c4cff2849624fb67f87cd0ad72b163671ad$(printf '\t')3.txt
git ls-files -s
ls ../default-tree
git ls-tree a237
git ls-tree aa25
# 注意空格
```sh
git-mnfss() {