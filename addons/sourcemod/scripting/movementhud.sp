#include <sdkhooks>
#include <sdktools>
#include <topmenus>
#include <sourcemod>
#include <clientprefs>

#include <json_mhud>
#include <base64>

#pragma semicolon 1
#pragma newdecls required

bool gB_IsReady;

#include <movementhud>

enum struct HUDInfo
{
	bool TimerRunning;
	int TimeType;
	float Time;
	bool Paused;
	bool OnGround;
	bool OnLadder;
	bool Noclipping;
	bool Ducking;
	bool HitBhop;
	bool IsTakeoff;
	float Speed;
	int ID;
	bool Jumped;
	bool HitPerf;
	bool HitJB;
	float TakeoffSpeed;
	int Buttons;
	int CurrentTeleport;
}

native int GOKZ_RP_GetPlaybackInfo(int client, any[] info);

#include "movementhud/utils.sp"
#include "movementhud/movement.sp"
#include "movementhud/elements/keys.sp"
#include "movementhud/elements/speed.sp"
#include "movementhud/elements/indicators.sp"

#include "movementhud/preferences.sp"
#include "movementhud/preferences_code.sp"
#include "movementhud/preferences_menu.sp"
#include "movementhud/preferences_defaults.sp"
#include "movementhud/preferences_chatinput.sp"

#include "movementhud/commands.sp"
#include "movementhud/api/natives.sp"
#include "movementhud/api/forwards.sp"

public Plugin myinfo =
{
    name = "MovementHUD 魔改汉化",
    author = "Sikari, Nep",
    description = "Provides customizable displays for movement",
    version = MHUD_VERSION,
    url = MHUD_SOURCE_URL
};

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
    RegPluginLibrary("MovementHUD");

    MarkNativeAsOptional("GOKZ_RP_GetPlaybackInfo");

    OnAskPluginLoad2_Natives();
    OnAskPluginLoad2_Forwards();

    return APLRes_Success;
}

public void OnPluginStart()
{
    OnPluginStart_Commands();
    OnPluginStart_Movement();
    OnPluginStart_Preferences();
    OnPluginStart_PreferencesDefaults();

    OnPluginStart_Element_Speed();
    OnPluginStart_Element_Keys();
    OnPluginStart_Element_Indicators();

    OnPluginStart_PreferencesCode();

    Call_OnReady();
    gB_IsReady = true;

    for (int i = 1; i <= MaxClients; i++)
    {
        if (IsClientConnected(i))
        {
            OnClientPutInServer(i);
        }
    }
}

public void OnClientPutInServer(int client)
{
    OnClientPutInServer_Movement(client);
    OnClientPutInServer_Preferences(client);
    OnClientPutInServer_PreferencesMenu(client);
    OnClientPutInServer_PreferencesChatInput(client);
}

public void OnPlayerRunCmdPost(int client, int buttons, int impulse, const float vel[3], const float angles[3], int weapon, int subtype, int cmdnum, int tickcount, int seed, const int mouse[2])
{
    OnPlayerRunCmdPost_Movement(client, buttons, mouse);

    if (!IsFakeClient(client))
    {
        int target = GetSpectedOrSelf(client);

        OnPlayerRunCmdPost_Element_Keys(client, target);
        OnPlayerRunCmdPost_Element_Speed(client, target);
        OnPlayerRunCmdPost_Element_Indicators(client, target);
    }
}
