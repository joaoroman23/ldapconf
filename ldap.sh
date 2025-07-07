#!/bin/bash

# Solicita o grupo que terá acesso ao servidor
echo -n "Digite o nome do grupo LDAP que terá acesso ao servidor: "
read LDAP_GROUP

# Atualiza pacotes e instala dependências
apt update && apt install -y sssd libpam-sss libnss-sss libsss-sudo libnss-ldap ldap-utils

# Define URLs dos arquivos de configuração
FILES=(
    "access.conf:/etc/security/access.conf"
    "common-account:/etc/pam.d/common-account"
    "common-session:/etc/pam.d/common-session"
    "nsswitch.conf:/etc/nsswitch.conf"
    "sshd_config:/etc/ssh/sshd_config"
    "sssd.conf:/etc/sssd/sssd.conf"
    "common-auth:/etc/pam.d/common-auth"
)
BASE_URL="https://raw.githubusercontent.com/joaoroman23/ldapconf/refs/heads/main"

# Baixa os arquivos de configuração
for FILE in "${FILES[@]}"; do
    KEY="${FILE%%:*}"
    VALUE="${FILE#*:}"
    wget -O "$VALUE" "$BASE_URL/$KEY"
    chown root:root "$VALUE"
    chmod 644 "$VALUE"
done

chmod 600 /etc/sssd/sssd.conf

# Adiciona filtro de acesso no sssd.conf
echo "ldap_access_filter = (memberOf=cn=$LDAP_GROUP,ou=groups,dc=roman,dc=local)" >> /etc/sssd/sssd.conf

# Adiciona regra de acesso no access.conf
echo "-:ALL EXCEPT ($LDAP_GROUP) : ALL EXCEPT LOCAL" >> /etc/security/access.conf

# Reinicia serviços
systemctl restart sssd
systemctl restart ssh

# Adiciona configuração ao sudoers
echo "%sudo   ALL=(ALL) NOPASSWD:ALL" | EDITOR='tee -a' visudo > /dev/null

echo "Configuração concluída com sucesso!"
