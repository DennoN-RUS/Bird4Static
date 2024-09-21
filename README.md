# Bird4Static
Здесь выложены файлы для работы bird с сервисами antifilter.download или antifilter.network

Есть 3 режима работы - скачивание файла с нужного сервиса, установка бгп соединения с одним из сервисов, и работа только с пользовательскими файлами

Есть возможность настройки с одним впн, так и с двумя (один основной, второй резервный + пользовательское перенаправление в определенный)

Предназначено для роутеров Keenetic с установленным на них entware, а так же для любой системы с opkg пакетами, и у которых система расположена в каталоге */opt/

## Установка
1) Зайти по ssh в среду entware

2) Выполнить:
    ```bash
    opkg install git git-http
    git clone https://github.com/DennoN-RUS/Bird4Static.git
    chmod +x ./Bird4Static/*.sh
    ./Bird4Static/install.sh 
    ```
    Далее выбирать нужные параметры.

Более подробная инструкция установки и описание [тут](https://github.com/DennoN-RUS/Bird4Static/wiki/Установка)

---
Канал в телеграме: [тут](https://t.me/bird4static)

Чат в телеграме: [тут](https://t.me/bird4static_chat)

Поддержать проект можно через [yoomoney](https://yoomoney.ru/to/41001872039390) и [cloudtips](https://pay.cloudtips.ru/p/76ea7dde)
