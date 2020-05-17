```bash
cat - <<EOF | tee jj
a$(pwd)

b
EOF
cat jj
```
