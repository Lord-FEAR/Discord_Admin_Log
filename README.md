# Discord Admin Log

# Требования:

- [SourceMod 1.8+](https://www.sourcemod.net/downloads.php?branch=stable)
- Ядро плагина - [[Discord] Core](https://hlmod.ru/resources/discord-core.502/)
- [REST in Pawn](https://hlmod.ru/threads/rest-in-pawn.41081/)
- [Steam Web API key Steam Community](https://steamcommunity.com/dev/apikey)

# Переменные:

cfg/sourcemod/discord_log_admin.cfg
	
```sh
// Api key https://steamcommunity.com/dev/apikey
// -
// Default: ""
sm_dal_apikey ""

// Игнорировать админов по флагу
// 1 - включено
// -
// Default: "0"
sm_dal_ignore "0"

// Флаг для игнора
// -
// Default: "z"
sm_dal_ignore_flag "z"

// Коррекция времени в дискорде (в секундах)
// 0 - выключено
// -
// Default: "0"
sm_dal_time_correct "0"
```

# Установка:

- Скомпилировать плагин
- Закинуть файл discord_log_admin.smx в папку addons/sourcemod/plugins/Discord
- Закинуть файл discord_log_admin.cfg в папку cfg/sourcemod/discord_log_admin.cfg
- Добавить веб-хук в файл addons/sourcemod/configs/Discord.cfg
```sh
"admin_logger" "веб-хук"
```
---
Подробнее по веб-хуккам [[Discord] Core](https://hlmod.ru/threads/discord-core.41406/#post-323669)

Поддержка [Discord](https://discord.gg/2F2X9VA)

Тема на [hlmod.ru](https://hlmod.ru/resources/discord-admin-log.603/)
