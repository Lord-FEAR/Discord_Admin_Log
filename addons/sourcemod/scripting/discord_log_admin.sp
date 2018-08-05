#include <sourcemod>
#include <clientprefs>
#include <discord_extended>
#include <ripext>

#pragma semicolon 1
#pragma newdecls required

public Plugin myinfo =
{
	name = "[Discord] Admin Log",
	author = "Lord FEAR",
	description = "Discord Admin Log",
	version = "0.3",
	url = "http://www.lordfear.ru/"
};

HTTPClient httpClient;
char    g_sHostName[256];
char    g_szApiKey[54];
char    g_szNotes[MAXPLAYERS+1][256];

public void OnPluginStart()
{
	httpClient = new HTTPClient("http://api.steampowered.com/ISteamUser/GetPlayerSummaries/v0002");
	CreateConVar("sm_dal_apikey", "", "Api key");
}

public void OnClientDisconnect(int iClient) {
    g_szNotes[iClient][0] = 0;
}

public void OnConfigsExecuted()
{
	GetConVarString(FindConVar("hostname"), g_sHostName, sizeof(g_sHostName));
	GetConVarString(FindConVar("sm_dal_apikey"), g_szApiKey, sizeof(g_szApiKey));
	if(!g_szApiKey[0])
	{
		LogError("Введите Steam Web API ключ! https://steamcommunity.com/dev/apikey");
	}
}

public Action OnLogAction(Handle source, Identity ident, int iClient, int iTarget, const char[] szMessage)
{
	if(iClient > 0 && IsClientInGame(iClient))
	{

		if(!g_szNotes[iClient][0])
		{
			char cPlayerID[64];
			char szURL[128];
			GetClientAuthId(iClient, AuthId_SteamID64, cPlayerID, sizeof(cPlayerID));
			FormatEx(szURL, sizeof(szURL), "?key=%s&steamids=%s", g_szApiKey, cPlayerID);

			DataPack hPack = new DataPack();
			hPack.WriteCell(iClient);
			hPack.WriteString(szMessage);
			httpClient.Get(szURL, OnTodoReceived, hPack);
		}
		else
		{
			char szPlayerName[50];
			char szMessage2[256];
			Format(szPlayerName, sizeof(szPlayerName), "%N", iClient);
			Format(szMessage2, sizeof(szMessage2), "```\n%s\n```", szMessage);
			int iColor = getColor(szMessage2);
			discord_send_message(iColor, g_szNotes[iClient], szPlayerName, szMessage2);
		}
	}
}

public void OnTodoReceived(HTTPResponse response, DataPack hPack)
{
	hPack.Reset();
	int iClient = hPack.ReadCell();
	char szMessage[256];
	char szMessage2[256];
	char szPlayerName[50];
	if (iClient == 0 || !IsClientInGame(iClient)) {
		delete hPack;
		return;
	}
	Format(szPlayerName, sizeof(szPlayerName), "%N", iClient);
	hPack.ReadString(szMessage, sizeof(szMessage));
	Format(szMessage2, sizeof(szMessage2), "```\n%s\n```", szMessage);
	delete hPack;
	if (response.Status != HTTPStatus_OK) {
		// Failed to retrieve todo
		return;
	}
	if (response.Data == null) {
		// Invalid JSON response
		return;
	}

    // Indicate that the response is a JSON object

	int iColor = getColor(szMessage);

	JSONObject res = view_as<JSONObject>(response.Data);
	JSONObject resp = view_as<JSONObject>(res.Get("response"));
	JSONArray players = view_as<JSONArray>(resp.Get("players"));
	JSONObject data = view_as<JSONObject>(players.Get(0));
	
	char szAvatar[256];
	data.GetString("avatarmedium", szAvatar, sizeof(szAvatar));
	g_szNotes[iClient] = szAvatar;
	discord_send_message(iColor, szAvatar, szPlayerName, szMessage2);
	delete res;
	delete resp;
	delete players;
	delete data;
}

public int getColor(char[] szMessage)
{
	if(StrContains(szMessage, "banned", true) != -1 || StrContains(szMessage, "teleported", true) != -1 || StrContains(szMessage, "slayed", true) != -1) 
		return 0xFF0000;
	else if(StrContains(szMessage, "slapped", true) != -1 || StrContains(szMessage, "triggered", true) != -1 || StrContains(szMessage, "initiated", true) != -1) 
		return 0x00ff00;
	
	return 0xFFFFFF;
}

public void discord_send_message(int iColor, char[] szAvatar, char[] szPlayerName, char[] szMessage2)
{
	Discord_StartMessage();
	Discord_SetColor(iColor);
	Discord_SetAvatar(szAvatar);
	Discord_SetUsername(szPlayerName);
	Discord_AddField(g_sHostName, szMessage2, true);
	Discord_EndMessage("admin_logger", true);
}