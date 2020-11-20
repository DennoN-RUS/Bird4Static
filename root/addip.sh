#!/bin/sh

cut_local() {
  grep -vE 'localhost|^0\.|^127\.|^169\.254\.|^10\.|^100\.64\.|^172\.16\.|^192\.168\.|^255\.255\.255\.255'
}

check_ip() {
  # Возвращаемые значения:
  # 0 - корректный IP-адрес без маски
  # 1 - корректный IP-адрес с маской
  # 2 - >255 в одном, нескольких или всех октетах IP-адреса
  # 3 - ¯\_(ツ)_/¯

  if echo "$1" | grep -qE '^([1-9]{1}[0-9]{0,2}\.){1}([0-9]\.|[1-9]{1}[0-9]{0,2}\.){2}([0-9]|[1-9]{1}[0-9]{0,2})(\/(3[0-2]|[12][0-9]|[0-9]))?$'; then
    if [ "$1" != "${1%/*}" ]; then
      for i in 1 2 3 4; do
        [ $(echo "${1%/*}" | cut -d. -f$i) -gt 255 ] && return 2
      done
      return 1
    else
      for i in 1 2 3 4; do
        [ $(echo "$1" | cut -d. -f$i) -gt 255 ] && return 2
      done
      return 0
    fi
  else
    return 3
  fi
}

[ -f "$3" ] && cat /dev/null > $3

while read line; do
  [ -z "$line" ] && continue
  [ "${line:0:1}" = "#" ] && continue

  check_ip "$line"

  # Выполнение команд после вызова check_ip изменит значение переменной "$?"

  case "$?" in
    0) echo "route ${line}/32 via \"$2\";" >> $3
       ;;
    1) echo "route ${line} via \"$2\";" >> $3
       ;;
    3) if ! ipaddr=$(dig +short +tries=4 $line @localhost 2>/dev/null | grep -vE '^$'); then
         logger -s -t ${0##*/} "DNS: не удалось разрешить доменное имя: строка \"${line}\" проигнорирована."
       else
         echo $ipaddr | grep -oE '([0-9]{1,3}\.){3}[0-9]{1,3}' | cut_local | sed 's/^/route /g;s/$/\/32 via "'$2'";/g' >> $3
       fi
       ;;
  esac
done < $1

exit 0
