# На Debian-подобных системах используется 'update-ca-certificates'
# На RHEL-подобных системах используется 'update-ca-trust'
if [ `which update-ca-certificates` ]; then
  printf "Успешно определили, что на системе используется 'update-ca-certificates'."
  sudo cp ~/opentofu-termidesk/ca_root.pem /usr/local/share/ca-certificates/ca_root.crt
  sudo cp ~/opentofu-termidesk/ca_intermediate.pem /usr/local/share/ca-certificates/ca_intermediate.crt
  sudo update-ca-certificates
elif [ `which update-ca-trust` ]; then
  printf "Успешно определили, что на системе используется 'update-ca-trust'."
  sudo cp ~/opentofu-termidesk/ca_root.pem /usr/share/pki/ca-trust-source/anchors/ca_root.pem
  sudo cp ~/opentofu-termidesk/ca_intermediate.pem /usr/share/pki/ca-trust-source/anchors/ca_intermediate.pem
  sudo update-ca-trust extract
else
  printf "На вашей системе нет подходящей программы для обновления сертификатов."
  exit 1
fi
