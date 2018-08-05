# Discord Admin Log

# Требования:

- [SourceMod 1.8+](https://www.sourcemod.net/downloads.php?branch=stable)
- Ядро плагина - [[Discord] Core](https://hlmod.ru/resources/discord-core.502/)
- [REST in Pawn](https://hlmod.ru/threads/rest-in-pawn.41081/)
- [Steam Web API key Steam Community](https://steamcommunity.com/dev/apikey)

# Переменные:

Добавить в server.cfg или другой конфиг файл исполняемый при загрузке сервера строку
	
```sh
sm_dal_apikey "Ваш Steam API Key"
```

# Установка:

Скомпилировать плагин и закинуть файл discord_log_admin.smx в папку addons\sourcemod\plugins\Discord

Добавить веб-хук в файл addons\sourcemod\configs\Discord.cfg
```sh
"admin_logger" "веб-хук"
```
---
Подробнее по веб-хуккам [[Discord] Core](https://hlmod.ru/threads/discord-core.41406/#post-323669)
