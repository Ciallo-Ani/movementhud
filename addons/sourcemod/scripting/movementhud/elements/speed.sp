static Handle HudSync;

MHudEnumPreference SpeedMode;
MHudXYPreference SpeedPosition;
MHudRGBPreference SpeedNormalColor;
MHudRGBPreference SpeedPerfColor;
MHudBoolPreference SpeedTakeoff;
MHudBoolPreference SpeedWalkOffTakeoff;
MHudBoolPreference SpeedColorBySpeed;
MHudBoolPreference SpeedCrouchIndicator;

static const char Modes[SpeedMode_COUNT][] =
{
    "Disabled",
    "As decimal",
    "As whole number"
};

void OnPluginStart_Element_Speed()
{
    HudSync = CreateHudSynchronizer();

    SpeedMode = new MHudEnumPreference("speed_mode", "速度 - 显示格式", Modes, sizeof(Modes) - 1, SpeedMode_None);
    SpeedPosition = new MHudXYPreference("speed_position", "速度 - 显示位置", -1, 725);
    SpeedNormalColor = new MHudRGBPreference("speed_color_normal", "速度 - 颜色 - 正常", 255, 255, 255);
    SpeedPerfColor = new MHudRGBPreference("speed_color_perf", "速度 - 颜色 - Perf", 0, 255, 0);
    SpeedColorBySpeed = new MHudBoolPreference("speed_color_by_speed", "速度 - 颜色 - 由速度决定", false);
    SpeedTakeoff = new MHudBoolPreference("speed_takeoff", "速度 - 显示离地速度", true);
    SpeedWalkOffTakeoff = new MHudBoolPreference("speed_walkOfftakeoff", "速度 - 显示未起跳离地速度", false);
    SpeedCrouchIndicator = new MHudBoolPreference("speed_crouch", "速度 - 蹲跳指示", true);
}

void OnPlayerRunCmdPost_Element_Speed(int client, int target)
{
    int mode = SpeedMode.GetInt(client);
    if (mode == SpeedMode_None)
    {
        return;
    }

    float speed = gF_CurrentSpeed[target];

    bool showTakeoff = SpeedTakeoff.GetBool(client);
    bool showWalkOffTakeoff = SpeedWalkOffTakeoff.GetBool(client);
    bool colorBySpeed = SpeedColorBySpeed.GetBool(client);
    bool showCrouchJump = SpeedCrouchIndicator.GetBool(client);

    float xy[2];
    SpeedPosition.GetXY(client, xy);

    int rgb[3];
    if (!colorBySpeed)
    {
        MHudRGBPreference colorPreference = gB_DidPerf[target]
            ? SpeedPerfColor
            : SpeedNormalColor;

        colorPreference.GetRGB(client, rgb);
    }
    else
    {
        GetColorBySpeed(speed, rgb);
    }

    Call_OnDrawSpeed(client, xy, rgb);
    SetHudTextParams(xy[0], xy[1], 0.5, rgb[0], rgb[1], rgb[2], 255, _, _, 0.0, 0.0);

    if (mode == SpeedMode_Float)
    {
        if (!showTakeoff || !gB_DidTakeoff[target] || (!showWalkOffTakeoff && !gB_DidJump[target] && !gB_DidFromLadder[target]))
        {
            ShowSyncHudText(client, HudSync, "%.2f", speed);
        }
        else if(showCrouchJump && gB_DidCrouchJump[target])
        {
            ShowSyncHudText(client, HudSync, "%.2f\n  (%.2f)C", speed, gF_TakeoffSpeed[target]);
        }
        else
        {
            ShowSyncHudText(client, HudSync, "%.2f\n(%.2f)", speed, gF_TakeoffSpeed[target]);
        }
    }
    else
    {
        int speedInt = RoundFloat(speed);
        if (!showTakeoff || !gB_DidTakeoff[target] || (!showWalkOffTakeoff && !gB_DidJump[target] && !gB_DidFromLadder[target]))
        {
            ShowSyncHudText(client, HudSync, "%d", speedInt);
        }
        else if(showCrouchJump && gB_DidCrouchJump[target])
        {
            ShowSyncHudText(client, HudSync, "%d\n  (%d)C", speedInt, RoundFloat(gF_TakeoffSpeed[target]));
        }
        else
        {
            ShowSyncHudText(client, HudSync, "%d\n(%d)", speedInt, RoundFloat(gF_TakeoffSpeed[target]));
        }
    }
}
