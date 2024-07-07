#!/bin/bash

set +o history

if [ ! -e ~/opentofu-termidesk ]; then
  mkdir ~/opentofu-termidesk
fi
cd ~/opentofu-termidesk
printf "\nПерешли в директорию: "; pwd

if [ -s brestLogin.tfvars ]; then
 export ONE_USERNAME=`awk --field-separator \" '{ print $2}' ./brestLogin.tfvars`
else
 read -p 'Логин вашей доменной учётной записи от brest.astralinux.ru: ' ONE_USER
 export ONE_USERNAME=$ONE_USER
fi

if [ ! -s toEncryptMyBrestToken.pem ]; then
    printf "Создаём RSA-ключ в формате PEM, которым зашифруем токен Бреста.\n"
    openssl genpkey -quiet -outform PEM -out toEncryptMyBrestToken.pem -algorithm RSA
    chmod 0400 toEncryptMyBrestToken.pem
    stat toEncryptMyBrestToken.pem
    printf "\nУспешно создано: RSA-ключ в формате PEM.\n"
fi
if [ ! -s brestToken.encrypted ]; then
    printf "Записываем ваш токен для входа в Брест и "
    printf "шифруем его RSA-ключом.\n\n"
    read -sp 'Введите ваш токен доступа от brest.astralinux.ru (вы не увидите его в терминале): ' BR_TOKEN
    touch brestToken
    echo "$BR_TOKEN" > brestToken
    chmod 0600 brestToken
    printf "\nШифруем введённый вами токен.\n"
    openssl pkeyutl -encrypt -in brestToken -out brestToken.encrypted -inkey toEncryptMyBrestToken.pem
    chmod 0400 brestToken.encrypted
    rm -f brestToken
    printf "Успешно создано: зашифрованный файл с переменной, где записан ваш токенот brest.astralinux.ru.\n"
fi
export ONE_PASSWORD=`openssl pkeyutl -decrypt -in brestToken.encrypted -inkey toEncryptMyBrestToken.pem`


ansible-playbook -i $BEGIN_DIR/ansible/inventories/inventory_opennebula.yml $BEGIN_DIR/ansible/playbooks/ca.yml

set -o history
exit 0