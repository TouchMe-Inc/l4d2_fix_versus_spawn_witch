#pragma semicolon              1
#pragma newdecls               required

#include <sourcemod>
#include <sdktools>
#include <colors>


public Plugin myinfo =
{
	name = "FixVersusSpawnWitch",
	author = "TouchMe",
	description = "The plugin corrects the position of the witch in versus mode",
	version = "build_0000",
	url = "https://github.com/TouchMe-Inc/l4d2_versus_spawn_witch"
};


// Gamemode
#define GAMEMODE_VERSUS         "versus"
#define GAMEMODE_VERSUS_REALISM "mutation12"


// Vars
bool
	g_bGamemodeAvailable = false; /**< Only versus mode */

float
	g_vWitchOrigin[3],
	g_vWitchRotation[3];

ConVar
	g_cvGameMode = null; /**< mp_gamemode */

/**
 * Called before OnPluginStart.
 *
 * @param myself      Handle to the plugin
 * @param bLate       Whether or not the plugin was loaded "late" (after map load)
 * @param sErr        Error message buffer in case load failed
 * @param iErrLen     Maximum number of characters for error message buffer
 * @return            APLRes_Success | APLRes_SilentFailure
 */
public APLRes AskPluginLoad2(Handle myself, bool bLate, char[] sErr, int iErrLen)
{
	EngineVersion engine = GetEngineVersion();

	if (engine != Engine_Left4Dead2) {
		strcopy(sErr, iErrLen, "Plugin only supports Left 4 Dead 2");
		return APLRes_SilentFailure;
	}

	return APLRes_Success;
}

/**
 * Called when the plugin is fully initialized and all known external
 * references are resolved.
 */
public void OnPluginStart()
{
	(g_cvGameMode = FindConVar("mp_gamemode")).AddChangeHook(OnGamemodeChanged);

	HookEvent("witch_spawn", Event_WitchSpawn);
}

/**
 * Called when a console variable value is changed.
 *
 * @param convar            Ignored.
 * @param sOldGameMode      Ignored.
 * @param sNewGameMode      String containing new gamemode.
 */
public void OnGamemodeChanged(ConVar hConVar, const char[] sOldGameMode, const char[] sNewGameMode) {
	g_bGamemodeAvailable = IsVersusMode(sNewGameMode);
}

/**
 * Called when the map has loaded, servercfgfile (server.cfg) has been executed, and all
 * plugin configs are done executing. This will always be called once and only once per map.
 * It will be called after OnMapStart().
*/
public void OnConfigsExecuted()
{
	char sGameMode[16];
	GetConVarString(g_cvGameMode, sGameMode, sizeof(sGameMode));
	g_bGamemodeAvailable = IsVersusMode(sGameMode);
}

/**
 * Witch spaned.
 */
public Action Event_WitchSpawn(Event event, char[] sEventName, bool bDontBroadcast)
{
	if (g_bGamemodeAvailable == false) {
		return Plugin_Continue;
	}

	int iWitchId = event.GetInt("witchid");

	CreateTimer(0.1, DelayWitchSpawn, iWitchId, TIMER_FLAG_NO_MAPCHANGE);

	return Plugin_Continue;
}

public Action DelayWitchSpawn(Handle hTimer, int iWitchId)
{
	if (!IsWitch(iWitchId)) {
		return Plugin_Continue;
	}

	if (!InSecondHalfOfRound()) {
		GetEntPropVector(iWitchId, Prop_Send, "m_angRotation", g_vWitchRotation);
		GetEntPropVector(iWitchId, Prop_Send, "m_vecOrigin", g_vWitchOrigin);
		CPrintToChatAll("Первый спавн ведьмы %f %f %f!", g_vWitchOrigin[0], g_vWitchOrigin[1], g_vWitchOrigin[2]);
	} else {
		TeleportEntity(iWitchId, g_vWitchOrigin, g_vWitchRotation, NULL_VECTOR);
		CPrintToChatAll("Второй спавн ведьмы %f %f %f!", g_vWitchOrigin[0], g_vWitchOrigin[1], g_vWitchOrigin[2]);
	}

	return Plugin_Continue;
}

/**
 * Checks if the current round is the second.
 *
 * @return                  Returns true if is second round, otherwise false.
 */
bool InSecondHalfOfRound() {
	return view_as<bool>(GameRules_GetProp("m_bInSecondHalfOfRound"));
}

/**
 * Is the game mode versus.
 *
 * @param sGameMode         A string containing the name of the game mode.
 *
 * @return                  Returns true if verus, otherwise false.
 */
bool IsVersusMode(const char[] sGameMode) {
	return (StrEqual(sGameMode, GAMEMODE_VERSUS, false) || StrEqual(sGameMode, GAMEMODE_VERSUS_REALISM, false));
}

bool IsWitch(int iWitchId)
{
	if (iWitchId > 0 && IsValidEdict(iWitchId) && IsValidEntity(iWitchId))
	{
		char classname[32];

		if (GetEdictClassname(iWitchId, classname, sizeof(classname)) && StrEqual(classname, "witch")) {
			return true;
		}
	}

	return false;
}
