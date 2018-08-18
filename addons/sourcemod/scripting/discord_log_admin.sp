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
    version = "0.3.1",
    url = "http://www.lordfear.ru/"
};

HTTPClient httpClient;
char    g_sHostName[256];
char    g_szApiKey[54];
char    g_bIgnoreFlag[54];
char    g_szNotes[MAXPLAYERS+1][256];
bool    g_bIgnore;
bool    g_bTimeCorrect;

public void OnPluginStart()
{
    httpClient = new HTTPClient("http://api.steampowered.com/ISteamUser/GetPlayerSummaries/v0002");
    CreateConVar("sm_dal_apikey", "", "Api key https://steamcommunity.com/dev/apikey");
    CreateConVar("sm_dal_ignore", "0", "Игнорировать админов по флагу\n1 - включено");
    CreateConVar("sm_dal_ignore_flag", "z", "Флаг для игнора");
    CreateConVar("sm_dal_time_correct", "0", "Коррекция времени в дискорде (в секундах)\n0 - выключено");
    AutoExecConfig(true, "discord_log_admin");
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
    g_bIgnore = GetConVarBool(FindConVar("sm_dal_ignore"));
    GetConVarString(FindConVar("sm_dal_ignore_flag"), g_bIgnoreFlag, sizeof(g_bIgnoreFlag));
    g_bTimeCorrect = GetConVarBool(FindConVar("sm_dal_time_correct"));
}

public Action OnLogAction(Handle source, Identity ident, int iClient, int iTarget, const char[] szMessage)
{
    if(IsValidClient(iClient))
    {
        if(g_bIgnore){
            if(CheckCommandAccess(iClient, "", ReadFlagString(g_bIgnoreFlag), true)){
                return Plugin_Continue;
            }
        }
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
    return Plugin_Continue;
}

public void OnTodoReceived(HTTPResponse response, DataPack hPack)
{
    hPack.Reset();
    int iClient = hPack.ReadCell();
    char szMessage[256];
    char szMessage2[256];
    char szPlayerName[50];
    if (!IsValidClient(iClient)) {
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
    char szAvatar[256];
    if(view_as<JSONArray>(resp.Get("players")).Length == 0) {
        szAvatar = "https://steamcdn-a.akamaihd.net/steamcommunity/public/images/avatars/fe/fef49e7fa7e1997310d705b2a6158ff8dc1cdfeb_full.jpg";
    }else{
        JSONArray players = view_as<JSONArray>(resp.Get("players"));
        JSONObject data = view_as<JSONObject>(players.Get(0));
        data.GetString("avatarmedium", szAvatar, sizeof(szAvatar));
        delete players;
        delete data;
    }
    g_szNotes[iClient] = szAvatar;
    delete res;
    delete resp;
    discord_send_message(iColor, szAvatar, szPlayerName, szMessage2);
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
    if(g_bTimeCorrect){
        Discord_SetTimestamp(GetTime()+GetConVarInt(FindConVar("sm_dal_time_correct")));
    }else{
        Discord_SetTimestamp(GetTime());
    }
    Discord_AddField(g_sHostName, szMessage2, true);
    Discord_EndMessage("admin_logger", true);
}

stock bool IsValidClient(int client)
{
    if (!(1 <= client <= MaxClients) || !IsClientInGame(client) || IsFakeClient(client) || IsClientSourceTV(client) || IsClientReplay(client))
    {
        return false;
    }
    return true;
}