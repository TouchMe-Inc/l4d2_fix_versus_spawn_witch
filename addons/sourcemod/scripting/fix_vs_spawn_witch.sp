#pragma semicolon              1
#pragma newdecls               required

#include <sourcemod>
#include <sdkhooks>
#include <sdktools>


public Plugin myinfo = {
	name = "FixVersusSpawnWitch",
	author = "TouchMe",
	description = "In the second round, the witch always takes the position of the first round witch",
	version = "build_0004",
	url = "https://github.com/TouchMe-Inc/l4d2_fix_vs_spawn_witch"
};


#define SI_CLASS_WITCH "witch"


Handle g_hWitchInfo = null;

int g_iWitchIndex = -1;

enum struct E_WitchInfo
{
	float vOrigin[3];
	float vRotation[3];
}

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
	if (GetEngineVersion() != Engine_Left4Dead2)
	{
		strcopy(sErr, iErrLen, "Plugin only supports Left 4 Dead 2");
		return APLRes_SilentFailure;
	}

	return APLRes_Success;
}

public void OnPluginStart()
{
	g_hWitchInfo = CreateArray(sizeof(E_WitchInfo));
}

public void OnEntityCreated(int iEnt, const char[] sClassName)
{
	if (iEnt > MaxClients && IsValidEntity(iEnt) && StrEqual(sClassName, SI_CLASS_WITCH))
	{
		SDKHook(iEnt, SDKHook_OnTakeDamage, OnTakePropDamage);

		CreateTimer(0.1, OnWitchCreated, EntIndexToEntRef(iEnt), TIMER_FLAG_NO_MAPCHANGE);
	}
}

public void OnMapStart()
{
	ClearArray(g_hWitchInfo);
	g_iWitchIndex = -1;
}

Action OnTakePropDamage(int iVictim, int &iAttacker, int &iInflictor, float &fDamage, int &iDamageType)
{
	if (iDamageType & DMG_BURN) {
		return Plugin_Handled;
	}

	return Plugin_Continue;
}

Action OnWitchCreated(Handle hTimer, int iEntRef)
{
	int iEnt = EntRefToEntIndex(iEntRef);

	if (!IsWitch(iEnt)) {
		return Plugin_Continue;
	}

	if (!InSecondHalfOfRound())
	{
		E_WitchInfo eWitchInfo;

		GetEntPropVector(iEnt, Prop_Send, "m_vecOrigin", eWitchInfo.vOrigin);
		GetEntPropVector(iEnt, Prop_Send, "m_angRotation", eWitchInfo.vRotation);

		PushArrayArray(g_hWitchInfo, eWitchInfo, sizeof(eWitchInfo));
	}

	else
	{
		g_iWitchIndex ++;

		if (g_iWitchIndex < GetArraySize(g_hWitchInfo))
		{
			E_WitchInfo eWitchInfo;

			GetArrayArray(g_hWitchInfo, g_iWitchIndex, eWitchInfo, sizeof(eWitchInfo));

			TeleportEntity(iEnt, eWitchInfo.vOrigin, eWitchInfo.vRotation, NULL_VECTOR);
		}
	}

	CreateTimer(1.0, OnWitchCreatedPost, EntIndexToEntRef(iEnt), TIMER_FLAG_NO_MAPCHANGE);

	return Plugin_Continue;
}

Action OnWitchCreatedPost(Handle hTimer, int iEntRef)
{
	int iEnt = EntRefToEntIndex(iEntRef);

	if (!IsWitch(iEnt)) {
		return Plugin_Continue;
	}

	SDKUnhook(iEnt, SDKHook_OnTakeDamage, OnTakePropDamage);

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
 * Is entity witch.
 *
 * @param iEnt              Witch Index.
 *
 * @return                  Returns true if valid witch, otherwise false.
 */
bool IsWitch(int iEnt)
{
	if (iEnt > MaxClients && IsValidEdict(iEnt) && IsValidEntity(iEnt))
	{
		char sClassName[32];

		if (GetEdictClassname(iEnt, sClassName, sizeof(sClassName)) && StrEqual(sClassName, SI_CLASS_WITCH)) {
			return true;
		}
	}

	return false;
}
