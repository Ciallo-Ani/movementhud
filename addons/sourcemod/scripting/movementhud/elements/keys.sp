static Handle HudSync;

MHudEnumPreference KeysMode;
MHudXYPreference KeysPosition;
MHudRGBPreference KeysNormalColor;
MHudRGBPreference KeysOverlapColor;
MHudBoolPreference KeysMouseDirection;
MHudBoolPreference KeysColorBySpeed;

static const char Modes[KeysMode_COUNT][] =
{
    "Disabled",
    "Blanks as underscores",
    "Blanks invisible"
};

void OnPluginStart_Element_Keys()
{
    HudSync = CreateHudSynchronizer();

    KeysMode = new MHudEnumPreference("keys_mode", "按键 - 显示格式", Modes, sizeof(Modes) - 1, KeysMode_None);
    KeysPosition = new MHudXYPreference("keys_position", "按键 - 显示位置", -1, 800);
    KeysNormalColor = new MHudRGBPreference("keys_color_normal", "按键 - 颜色 - 正常", 255, 255, 255);
    KeysOverlapColor = new MHudRGBPreference("keys_color_overlap", "按键 - 颜色 - 冲突", 255, 0, 0);
    KeysColorBySpeed = new MHudBoolPreference("keys_color_from_speed", "按键 - 颜色 - 由速度决定", false);
    KeysMouseDirection = new MHudBoolPreference("keys_mouse_direction", "按键 - 显示鼠标移动", false);
}

void OnPlayerRunCmdPost_Element_Keys(int client, int target)
{
    int mode = KeysMode.GetInt(client);
    if (mode == KeysMode_None)
    {
        return;
    }

    int buttons = gI_Buttons[target];
    bool showJump = JumpedRecently(target);
    bool colorBySpeed = KeysColorBySpeed.GetBool(client);

    float xy[2];
    KeysPosition.GetXY(client, xy);

    int rgb[3];
    if (!colorBySpeed)
    {
        MHudRGBPreference colorPreference = DidButtonsOverlap(buttons)
            ? KeysOverlapColor
            : KeysNormalColor;

        colorPreference.GetRGB(client, rgb);
    }
    else
    {
        float speed = gF_CurrentSpeed[target];
        GetColorBySpeed(speed, rgb);
    }

    char blank[2];
    blank = (mode == KeysMode_NoBlanks) ? "  " : "—";

    Call_OnDrawKeys(client, xy, rgb);
    SetHudTextParams(xy[0], xy[1], 0.5, rgb[0], rgb[1], rgb[2], 255, _, _, 0.0, 0.0);

    bool showMouseDirection = KeysMouseDirection.GetBool(client);
    if (!showMouseDirection)
    {
        ShowSyncHudText(client, HudSync, "%s  %s  %s\n%s  %s  %s",
            (buttons & IN_DUCK)       ? "C" : blank,
            (buttons & IN_FORWARD)    ? "W" : blank,
            (showJump)                ? "J" : blank,
            (buttons & IN_MOVELEFT)   ? "A" : blank,
            (buttons & IN_BACK)       ? "S" : blank,
            (buttons & IN_MOVERIGHT)  ? "D" : blank
        );
    }
    else
    {
        int mouseX = gI_MouseX[target];

        ShowSyncHudText(client, HudSync, "%s  %s  %s\n%s %s  %s  %s %s",
            (buttons & IN_DUCK)       ? "C" : blank,
            (buttons & IN_FORWARD)    ? "W" : blank,
            (showJump)                ? "J" : blank,
            (mouseX < 0)              ? "←" : blank,
            (buttons & IN_MOVELEFT)   ? "A" : blank,
            (buttons & IN_BACK)       ? "S" : blank,
            (buttons & IN_MOVERIGHT)  ? "D" : blank,
            (mouseX > 0)              ? "→" : blank
        );
    }
}

static bool DidButtonsOverlap(int buttons)
{
    return buttons & (IN_FORWARD | IN_BACK) == (IN_FORWARD | IN_BACK)
        || buttons & (IN_MOVELEFT | IN_MOVERIGHT) == (IN_MOVELEFT | IN_MOVERIGHT);
}
