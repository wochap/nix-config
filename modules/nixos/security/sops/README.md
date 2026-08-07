# sops

```sh
# first time creating key
mkdir -p ~/.config/sops/age
age-keygen -o ~/.config/sops/age/keys.txt

# reading age file key
age-keygen -y ~/.config/sops/age/keys.txt

# encrypt a YAML secret file
sops --encrypt --in-place path/to/secret.yaml

# edit an encrypted YAML file
sops path/to/secret.yaml
```
