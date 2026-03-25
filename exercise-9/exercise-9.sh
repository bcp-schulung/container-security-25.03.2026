openssl genrsa -out jane.key 2048
openssl req -new -key jane.key -out jane.csr -subj "/CN=jane/O=developers"
cat jane.csr | base64 | tr -d '\n'
kubectl apply -f jane-csr.yaml
kubectl certificate approve jane
kubectl get csr jane -o jsonpath='{.status.certificate}' | base64 -d > jane.crt
kubectl apply -f jane-role.yaml
kubectl config set-credentials jane \
  --client-certificate=jane.crt \
  --client-key=jane.key
kubectl config set-context jane-dev \
  --cluster=kubernetes \
  --user=jane \
  --namespace=dev