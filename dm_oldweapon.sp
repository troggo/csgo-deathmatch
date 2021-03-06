#include <sourcemod>
#include <sdktools>
#include <cstrike>

#pragma semicolon 1

#define WEAPON_SLOTS 	2	// Number of weapon slots to save
#define MAX_WPN_LENGTH 	32	// Max weapon classname length

public Plugin myinfo = {
	name = "Deathmatch: Old Weapon",
	author = "Kyle",
	description = "Spawn with the same weapons you had before death",
	version = "1.0.3",
	url = ""
};

EngineVersion g_Game;
ConVar g_Cvar_Enable;

// Array to hold weapons for all players
char g_PlayerWeapons[MAXPLAYERS + 1][WEAPON_SLOTS][MAX_WPN_LENGTH];

public void OnPluginStart() {

	g_Game = GetEngineVersion();
	if (g_Game != Engine_CSGO) {
		SetFailState("This plugin is for CS:GO only. It may need tweaking for other games");
	}

	g_Cvar_Enable = CreateConVar("dm_enable", "1", "Enable the dm_ SourceMod plugins", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_Cvar_Enable.AddChangeHook(ConVarChange_Enable);

	EnableHooks(g_Cvar_Enable.BoolValue);
}

void EnableHooks(bool enable) {
	static bool events_hooked = false;
	if (enable != events_hooked) {
		if (enable) {
			HookEvent("player_hurt", Event_PlayerHurt);
			HookEvent("player_spawn", Event_PlayerSpawn);
		} else {
			UnhookEvent("player_hurt", Event_PlayerHurt);
			UnhookEvent("player_spawn", Event_PlayerSpawn);
		}
		events_hooked = enable;
	}
}

public void ConVarChange_Enable(ConVar convar, const char[] oldValue, const char[] newValue) {
	EnableHooks(g_Cvar_Enable.BoolValue);
}

public bool OnClientConnect(int client) {
	for (int slot = 0; slot < WEAPON_SLOTS; slot++) {
		g_PlayerWeapons[client][slot] = "";
	}
	return true;
}

public void Event_PlayerHurt(Event event, const char[] name, bool dontBroadcast) {
	int client = GetClientOfUserId(event.GetInt("userid"));
	int clientHealth = GetEntProp(client, Prop_Data, "m_iHealth");
	if (clientHealth <= 0) {
		for (int slot = 0; slot < WEAPON_SLOTS; slot++) {
			SavePlayerWeapon(client, slot);
		}
	}
}

public void Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast) {
	int client = GetClientOfUserId(event.GetInt("userid"));
	for (int slot = 0; slot < WEAPON_SLOTS; slot++) {
		RestorePlayerWeapon(client, slot);
	}
}

void SavePlayerWeapon(int client, int slot) {
	int wpn = GetPlayerWeaponSlot(client, slot);
	if (wpn != -1) {
		GetEntityClassname(wpn, g_PlayerWeapons[client][slot], sizeof(g_PlayerWeapons[][]));
	} else {
		g_PlayerWeapons[client][slot] = "";
	}
}

void RestorePlayerWeapon(int client, int slot) {
	if (StrContains(g_PlayerWeapons[client][slot], "weapon_") > -1) {
		int wpn = GetPlayerWeaponSlot(client, slot);
		if (wpn > -1) {
			RemovePlayerItem(client, wpn);
		}
		GivePlayerItem(client, g_PlayerWeapons[client][slot]);
	}
}
