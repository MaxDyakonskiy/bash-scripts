#!/bin/bash

export BEGIN_DIR=`pwd`

printf "\nЧто вы хотите сделать?\n"
printf "1) Создать ВМ на brest.astralinux.ru (рекомендуется при первом запуске).\n"
printf "2) Настроить созданные ВМ.\n"
read -ep "Введите ваш выбор: " MAIN_CHOISE
  case $MAIN_CHOISE in
    1 | \'1\' | \"1\" | 1\) ) /bin/bash ./deployVMs.sh ;; # Clause №1
    2 | \'2\' | \"2\" | 2\) ) /bin/bash ./setVMs.sh ;; # Clause №2
    *) printf "Недопустимый выбор\n" && exit 1;; # Clause №3
  esac
printf "\nЗакончено!\n\n"
exit 0