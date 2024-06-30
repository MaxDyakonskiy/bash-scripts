#!/bin/bash

set +o history

printf "\nВы запустили скрипт для автоматического развёртывания стенда, где вы сможете протестировать Термидеск 5.0.\n"
printf "Стенд будет создан на корпоративном Бресте, который доступен по адресу: https://opennebula.test.lan.\n"
printf "Пожалуйста, выберите действие из списка ниже:\n"
printf "1) Подготовить базовые образы ALSE\n"
printf "2) Создать или настроить инфраструктуру стенда, используя базовые образы по-умолчанию (рекомендуется)\n"
read -erp "Ваш выбор: " BRANCH_CHOISE
case $BRANCH_CHOISE in
  1 | \'1\' | \"1\" | 1\) ) BRANCH_GOTO=goToPacker;; # Clause №1
  2 | \'2\' | \"2\" | 2\) ) BRANCH_GOTO=goToTofu;; # Clause №2
  *) printf "Недопустимый выбор\n" && exit 1;; # Clause №3
esac

if [ $BRANCH_GOTO = goToPacker ]; then
  printf "Какой образ вы хотите подготовить?\n"
  printf "1) ALSE-1.7.4.11\n"
  printf "2) ALSE-1.7.5.16\n"
  read -erp "Ваш выбор: " PACKER_CHOISE
  case $PACKER_CHOISE in
    1 | \'1\' | \"1\" | 1\) ) PACKER_GOTO='image-tm-alse-1.7.4.11.pkr.hcl';; # Clause №1
    2 | \'2\' | \"2\" | 2\) ) PACKER_GOTO='image-tm-alse-1.7.5.16.pkr.hcl';; # Clause №2
    *) printf "Недопустимый выбор\n" && exit 1;; # Clause №3
  esac
  packer build packer/${PACKER_GOTO}
fi

if [ $BRANCH_GOTO = goToTofu ]; then
  # Скопируем нужные файлы из git и перейдём в ваш домашний каталог.
  if [ ! -e ~/opentofu-termidesk ]; then
    mkdir ~/opentofu-termidesk
  fi
  cp --remove-destination opentofu/deployBrest/main.tf ~/opentofu-termidesk
  cd ~/opentofu-termidesk
  printf "Вышли из каталогов git и перешли в ваш домашний каталог: "; pwd; printf "\n\n"

  ### Создадим переменную для логина и RSA-пару, которой затем зашифруем токен для
  # доступа к Бресту
  if [ ! -s brestLogin.tfvars ]; then
    touch brestLogin.tfvars
    read -p 'Введите логин вашей доменной УЗ от opennebula.test.lan: ' BR_LOGIN
    echo "brest_username=\"$BR_LOGIN\"" > brestLogin.tfvars
    chmod 0400 brestLogin.tfvars
    printf "\nУспешно создано: обычный файл с переменной, где записан ваш логин от brest.astralinux.ru.\n"
  fi

  # 1. Функция 'rsadecrypt' в Terraform не умеет работать с зашифрованными ключами
  # на момент версии 1.8.х, поэтому создаём закрытый ключ, незащищённый паролем.
  # 2. Функция 'rsadecrypt' в Terraform умеет работать только с PEM-форматом,
  # который генерирует OpenSSl: инструменты 'gpg' и 'gpgsm' не подходят.
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
    printf "Успешно создано: зашифрованный файл с переменной, где записан ваш токен от opennebula.test.lan.\n"
  fi

  # Функция 'rsadecrypt' добавляет
  # метасимволы к расшифрованной строке, отчего строка больше не может нас
  # авторизовать. Я не знаю, как это исправить, потому что в выводе OpenSSL никаких
  # метасимволов нет, поэтому просто декларируем переменную.
  export TF_VAR_brest_password=`openssl pkeyutl -decrypt -in brestToken.encrypted -inkey toEncryptMyBrestToken.pem`

  # Имейте в виду, что OpenTofu не считывает переменную '~', только '$HOME'.
  # См. также про chdir: https://developer.hashicorp.com/terraform/cli/commands
  printf "Запускаем OpenTofu в следующей директории: "; pwd; printf "\n"

  # Проверку введённого значения будет выполнять команда 'tofu'
  printf "Ввведите команду и аргументы для OpenTofu (полный список доступен на вашей системе вызовом 'tofu -help').\n"
  printf "Если вы запустили скрит первый раз, рекомендуем ввести слово 'start' (без кавычек).\n"
  printf "В таком случае мы передадим несколько команд в OpenTofu, которые подготовят базовую инфраструктуру.\n"
  read -erp "Ваша команда: " TOFU_COMMAND

  if [[ $TOFU_COMMAND == 'plan' ]] || [[ $TOFU_COMMAND == 'apply' ]] || [[ $TOFU_COMMAND == 'destroy' ]]; then
    # Если вокруг названия файла поставить кавычки, OpenTofu падает в ошибку
    MANDATORY_ARGS=' -input=false -var-file=brestLogin.tfvars'
    TOFU_COMMAND+=${MANDATORY_ARGS}
  fi
  if [[ $TOFU_COMMAND == 'start' ]]; then
    tofu init
    tofu plan -input=false -var-file=brestLogin.tfvars
    tofu apply -input=false -var-file=brestLogin.tfvars
  fi
  tofu $TOFU_COMMAND
  # OpenTofu не умеет нормально парсить блоки 'template_section' в провайдере OpenNebula.
  # Поэтому не обращайте внимание на то, что он хочет уничтожить соответствующие сущности (при повторном 'apply'):
  # это неправда, он их не уничтожит.

  export -n TF_VAR_brest_password
fi

set -o history
