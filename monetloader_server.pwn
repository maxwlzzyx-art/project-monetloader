--[[
     MONETLOADER - SERVER SIDE (PAWN/C++)
     Admin validation & teleport command handler
     
     Compile dengan sampctl atau pAWN compiler
     Tambahkan ke gamemode Anda
]]

#if defined _monetloader_teleport_included
    #endinput
#endif
#define _monetloader_teleport_included

#include <a_samp>

// Constants
#define MONETLOADER_VERSION "1.0"
#define MONETLOADER_CMD_TELEPORT "/tpx"
#define MONETLOADER_ADMIN_LEVEL 1 // Level admin minimum

// Dialog ID
#define DIALOG_MONETLOADER_TP 9999

// Variable
new bool:PlayerUsingMonetLoader[MAX_PLAYERS];

// Callback ketika client kirim teleport request
public OnPlayerTeleportRequest(playerid, interiorID, Float:x, Float:y, Float:z)
{
    // Check admin level
    if (GetPlayerAdminLevel(playerid) < MONETLOADER_ADMIN_LEVEL)
    {
        SendClientMessage(playerid, 0xFF0000FF, "[MONETLOADER] Anda tidak memiliki akses ke fitur ini!");
        return 0;
    }
    
    // Teleport player
    SetPlayerInterior(playerid, interiorID);
    SetPlayerPos(playerid, x, y, z);
    SetPlayerFacingAngle(playerid, 0.0);
    
    // Notify
    new str[128];
    format(str, sizeof(str), "[MONETLOADER] Anda teleport ke interior #%d", interiorID);
    SendClientMessage(playerid, 0x00FF40FF, str);
    
    return 1;
}

// Function untuk get admin level
// CUSTOM SESUAI SERVER ANDA!
forward GetPlayerAdminLevel(playerid);
public GetPlayerAdminLevel(playerid)
{
    // Contoh: Gunakan variabel admin dari script kamu
    // return PlayerInfo[playerid][pAdminLevel];
    
    // Atau check dari database
    // SELECT admin_level FROM accounts WHERE player_id = playerid
    
    // Default jika belum di-implement
    return 0; // 0 = bukan admin, >0 = admin
}

// Dialog response handler
public OnDialogResponse(playerid, dialogid, response, listitem, inputtext[])
{
    if (dialogid == DIALOG_MONETLOADER_TP)
    {
        if (response)
        {
            // Trigger callback ke client
            // Gunakan external protocol atau direct call
        }
    }
    return 0;
}

// Fungsi untuk broadcast teleport info
stock BroadcastTeleportInfo(playerid, interiorName[])
{
    new str[128];
    format(str, sizeof(str), "[MONETLOADER] %s menggunakan teleport interior %s", 
        GetPlayerNameEx(playerid), interiorName);
    
    // Optional: Log ke file
    // printf("[MONETLOADER_LOG] %s", str);
    
    return 1;
}

// Helper: Get player name
stock GetPlayerNameEx(playerid)
{
    new name[MAX_PLAYER_NAME];
    GetPlayerName(playerid, name, sizeof(name));
    return name;
}

// Optional: Admin command untuk manage teleport
public OnPlayerCommandText(playerid, cmdtext[])
{
    if (!strcmp(cmdtext, MONETLOADER_CMD_TELEPORT, true))
    {
        if (GetPlayerAdminLevel(playerid) < MONETLOADER_ADMIN_LEVEL)
        {
            SendClientMessage(playerid, 0xFF0000FF, "Anda tidak memiliki akses!");
            return 1;
        }
        
        SendClientMessage(playerid, 0x00FF40FF, "[MONETLOADER] Menu teleport interior telah dibuka!");
        SendClientMessage(playerid, 0xFFFFFFFF, "Gunakan ImGui menu untuk memilih interior.");
        
        PlayerUsingMonetLoader[playerid] = true;
        return 1;
    }
    
    return 0;
}

// Hook OnPlayerDisconnect untuk cleanup
public OnPlayerDisconnect(playerid, reason)
{
    PlayerUsingMonetLoader[playerid] = false;
    return 1;
}
