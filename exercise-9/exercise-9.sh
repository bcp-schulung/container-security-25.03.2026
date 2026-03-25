openssl genrsa -out jane.key 2048
openssl req -new -key jane.key -out jane.csr -subj "/CN=jane/O=developers"
cat jane.csr | base64 | tr -d '\n'