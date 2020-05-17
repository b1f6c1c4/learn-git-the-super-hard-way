```bash
cat - <<EOF | tee jj
a$(pwd)

b
EOF
# a/root
#
# b
cat jj
# a/root
#
# b
```
