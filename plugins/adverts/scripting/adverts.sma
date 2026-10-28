#include <amxmodx>
#include <amxmisc>

#define PLUGIN  "Advanced Advertisements & Chat Triggers"
#define VERSION "1.0"
#define AUTHOR  "illusion (modificado por [F]rancisc0001)"

#define MAX_LENGTH 192
#define TASK_DISPLAY_HUD 54879
#define TASK_DISPLAY_CHAT 54880

new g_szConfigFile[64];
new g_szTag[64] = "!g[Server]";

new Array:g_aHudAdverts;
new g_iHudAdvertCount;
new g_iCurrentHudAdvert;

new Array:g_aChatAdverts;
new g_iChatAdvertCount;
new g_iCurrentChatAdvert;

new Trie:g_tChatCommands;

// Cvars
new g_pCvarEnabled;
new g_pCvarInterval;
new g_pCvarRandomOrder;
new g_pCvarEffectType;
new g_pCvarHoldTime;
new g_pCvarFadeIn;
new g_pCvarFadeOut;
new g_pCvarPosX;
new g_pCvarPosY;

new g_pCvarChatEnabled;
new g_pCvarChatInterval;
new g_pCvarChatRandomOrder;

new g_pCvarChatCmdEnabled;
new g_pCvarChatCmdToAll;
new g_pCvarChatCmdCooldown;

new Float:g_flNextChatCmdAllowed[33];

public plugin_init() {
    register_plugin(PLUGIN, VERSION, AUTHOR);
    
    register_dictionary("adverts.txt");
    register_dictionary("common.txt");

    new szConfigsDir[128];
    get_localinfo("amxx_configsdir", szConfigsDir, charsmax(szConfigsDir));
    formatex(g_szConfigFile, charsmax(g_szConfigFile), "%s/adverts.ini", szConfigsDir);
    
    g_pCvarEnabled = register_cvar("amx_adverts_enabled", "1");
    g_pCvarInterval = register_cvar("amx_adverts_interval", "60.0");
    g_pCvarRandomOrder = register_cvar("amx_adverts_random", "0");
    g_pCvarEffectType = register_cvar("amx_adverts_effect", "2");
    g_pCvarHoldTime = register_cvar("amx_adverts_holdtime", "5.0");
    g_pCvarFadeIn = register_cvar("amx_adverts_fadein", "0.1");
    g_pCvarFadeOut = register_cvar("amx_adverts_fadeout", "0.2");
    g_pCvarPosX = register_cvar("amx_adverts_x", "-1.0");
    g_pCvarPosY = register_cvar("amx_adverts_y", "0.2");

    g_pCvarChatEnabled = register_cvar("amx_adverts_chat_enabled", "1");
    g_pCvarChatInterval = register_cvar("amx_adverts_chat_interval", "45.0");
    g_pCvarChatRandomOrder = register_cvar("amx_adverts_chat_random", "0");

    g_pCvarChatCmdEnabled = register_cvar("amx_adverts_chatcmd_enabled", "1");
    g_pCvarChatCmdToAll = register_cvar("amx_adverts_chatcmd_to_all", "0");
    g_pCvarChatCmdCooldown = register_cvar("amx_adverts_chatcmd_cooldown", "5.0");
    
    register_concmd("amx_reloadadverts", "CmdReloadAdverts", ADMIN_CVAR, "- Reloads the advertisements configuration");

    register_clcmd("say", "HookSay");
    register_clcmd("say_team", "HookSay");
    
    g_aHudAdverts = ArrayCreate(MAX_LENGTH);
    g_aChatAdverts = ArrayCreate(MAX_LENGTH);
    g_tChatCommands = TrieCreate();
    
    LoadAdverts();
}

public plugin_cfg() {
    if(!file_exists(g_szConfigFile)) {
        CreateDefaultConfig();
        LoadAdverts();
    }
    
    if(get_pcvar_num(g_pCvarEnabled) || get_pcvar_num(g_pCvarChatEnabled)) {
        if(g_iHudAdvertCount > 0 || g_iChatAdvertCount > 0) {
            set_task(1.0, "StartAdvertTask");
        }
    }
}

public plugin_end() {
    if(g_aHudAdverts != Invalid_Array) {
        ArrayDestroy(g_aHudAdverts);
    }
    if(g_aChatAdverts != Invalid_Array) {
        ArrayDestroy(g_aChatAdverts);
    }
    if(g_tChatCommands != Invalid_Trie) {
        TrieDestroy(g_tChatCommands);
    }
}

CreateDefaultConfig() {
    new File = fopen(g_szConfigFile, "wt");
    if(File) {
        fprintf(File, "; ==============================================^n");
        fprintf(File, "; Adverts Configuration File^n");
        fprintf(File, "; ==============================================^n^n");
        fprintf(File, "[SETTINGS]^n");
        fprintf(File, "tag = !g[Server]^n^n");
        fprintf(File, "[HUD]^n^n");
        fprintf(File, "[CHAT]^n");
        fprintf(File, "ADVERT_WELCOME 2^n");
        fprintf(File, "ADVERT_RULES 2^n");
        fprintf(File, "ADVERT_DISCORD 2^n");
        fprintf(File, "ADVERT_HELP 1^n^n");
        fprintf(File, "rules = ADVERT_RULES^n");
        fprintf(File, "reglas = ADVERT_RULES^n");
        fprintf(File, "discord = ADVERT_DISCORD^n");
        fprintf(File, "help = ADVERT_HELP^n");
        fprintf(File, "ayuda = ADVERT_HELP^n");
        fprintf(File, "menu = ADVERT_HELP^n");
        fclose(File);
    }
}

public LoadAdverts() {
    if(g_aHudAdverts != Invalid_Array) {
        ArrayClear(g_aHudAdverts);
    }
    if(g_aChatAdverts != Invalid_Array) {
        ArrayClear(g_aChatAdverts);
    }
    if(g_tChatCommands != Invalid_Trie) {
        TrieClear(g_tChatCommands);
    }
    
    g_iHudAdvertCount = 0;
    g_iCurrentHudAdvert = 0;
    g_iChatAdvertCount = 0;
    g_iCurrentChatAdvert = 0;
    
    if(!file_exists(g_szConfigFile)) {
        return;
    }
    
    new File = fopen(g_szConfigFile, "rt");
    if(!File) {
        return;
    }
    
    new Array:aHudRawKeys = ArrayCreate(MAX_LENGTH);
    new Array:aHudRawWeights = ArrayCreate(1);
    new iHudMaxWeight = 1;

    new Array:aChatRawKeys = ArrayCreate(64);
    new Array:aChatRawWeights = ArrayCreate(1);
    new iChatMaxWeight = 1;

    new szLine[MAX_LENGTH];
    new iSection = 0; // 0=none, 1=SETTINGS, 2=HUD, 3=CHAT
    while(!feof(File)) {
        fgets(File, szLine, charsmax(szLine));
        trim(szLine);
        
        if(!szLine[0] || szLine[0] == ';' || szLine[0] == '/') {
            continue;
        }

        if(szLine[0] == '[') {
            if(equali(szLine, "[SETTINGS]")) {
                iSection = 1;
            } else if(equali(szLine, "[HUD]")) {
                iSection = 2;
            } else if(equali(szLine, "[CHAT]")) {
                iSection = 3;
            } else {
                iSection = 0;
            }
            continue;
        }

        if(iSection == 0) {
            iSection = 2;
        }
        
        if(iSection == 1) {
            new szKey[32], szVal[64];
            strtok(szLine, szKey, charsmax(szKey), szVal, charsmax(szVal), '=');
            trim(szKey); trim(szVal);
            if(equali(szKey, "tag")) {
                copy(g_szTag, charsmax(g_szTag), szVal);
            }
        }
        else if(iSection == 2) {
            new szEntry[MAX_LENGTH], szWeightStr[16];
            parse(szLine, szEntry, charsmax(szEntry), szWeightStr, charsmax(szWeightStr));
            new iWeight = 1;
            if(szWeightStr[0]) {
                iWeight = str_to_num(szWeightStr);
                if(iWeight < 1) iWeight = 1;
                if(iWeight > 10) iWeight = 10;
            }
            ArrayPushString(aHudRawKeys, szEntry);
            ArrayPushCell(aHudRawWeights, iWeight);
            if(iWeight > iHudMaxWeight) iHudMaxWeight = iWeight;
        } else if(iSection == 3) {
            new szKey[64], szValue[MAX_LENGTH];
            new iPos = containi(szLine, "=");

            if(iPos != -1) {
                copy(szKey, charsmax(szKey), szLine);
                szKey[iPos] = 0;
                trim(szKey);
                copy(szValue, charsmax(szValue), szLine[iPos + 1]);
                trim(szValue);

                if(szKey[0] && szValue[0]) {
                    strtolower(szKey);
                    TrieSetString(g_tChatCommands, szKey, szValue);
                }
            } else {
                new szEntry[64], szWeightStr[16];
                parse(szLine, szEntry, charsmax(szEntry), szWeightStr, charsmax(szWeightStr));
                new iWeight = 1;
                if(szWeightStr[0]) {
                    iWeight = str_to_num(szWeightStr);
                    if(iWeight < 1) iWeight = 1;
                    if(iWeight > 10) iWeight = 10;
                }
                ArrayPushString(aChatRawKeys, szEntry);
                ArrayPushCell(aChatRawWeights, iWeight);
                if(iWeight > iChatMaxWeight) iChatMaxWeight = iWeight;
            }
        }
    }
    
    fclose(File);

    new iHudRawCount = ArraySize(aHudRawKeys);
    new szItemBuf[MAX_LENGTH];
    for(new p = 1; p <= iHudMaxWeight; p++) {
        for(new i = 0; i < iHudRawCount; i++) {
            if(ArrayGetCell(aHudRawWeights, i) >= p) {
                ArrayGetString(aHudRawKeys, i, szItemBuf, charsmax(szItemBuf));
                ArrayPushString(g_aHudAdverts, szItemBuf);
                g_iHudAdvertCount++;
            }
        }
    }
    ArrayDestroy(aHudRawKeys);
    ArrayDestroy(aHudRawWeights);

    new iChatRawCount = ArraySize(aChatRawKeys);
    for(new p = 1; p <= iChatMaxWeight; p++) {
        for(new i = 0; i < iChatRawCount; i++) {
            if(ArrayGetCell(aChatRawWeights, i) >= p) {
                ArrayGetString(aChatRawKeys, i, szItemBuf, charsmax(szItemBuf));
                ArrayPushString(g_aChatAdverts, szItemBuf);
                g_iChatAdvertCount++;
            }
        }
    }
    ArrayDestroy(aChatRawKeys);
    ArrayDestroy(aChatRawWeights);
}

public CmdReloadAdverts(id, level, cid) {
    if(!cmd_access(id, level, cid, 1)) {
        return PLUGIN_HANDLED;
    }
    
    LoadAdverts();
    client_print(id, print_console, "[ADVERTS] Configuration reloaded. Tag='%s' HUD=%d CHAT=%d.", g_szTag, g_iHudAdvertCount, g_iChatAdvertCount);
    StartAdvertTask();
    
    return PLUGIN_HANDLED;
}

public StartAdvertTask() {
    remove_task(TASK_DISPLAY_HUD);
    remove_task(TASK_DISPLAY_CHAT);

    if(get_pcvar_num(g_pCvarEnabled) && g_iHudAdvertCount > 0) {
        set_task(get_pcvar_float(g_pCvarInterval), "DisplayHudAdvert", TASK_DISPLAY_HUD, .flags="b");
        set_task(0.1, "DisplayHudAdvert");
    }

    if(get_pcvar_num(g_pCvarChatEnabled) && g_iChatAdvertCount > 0) {
        set_task(get_pcvar_float(g_pCvarChatInterval), "DisplayChatAdvert", TASK_DISPLAY_CHAT, .flags="b");
        set_task(0.2, "DisplayChatAdvert");
    }
}

public DisplayHudAdvert() {
    if(!get_pcvar_num(g_pCvarEnabled)) {
        return;
    }

    if(!g_iHudAdvertCount || g_aHudAdverts == Invalid_Array) {
        return;
    }

    if(g_iCurrentHudAdvert < 0 || g_iCurrentHudAdvert >= g_iHudAdvertCount) {
        g_iCurrentHudAdvert = 0;
    }
    
    new szAdvert[MAX_LENGTH];
    ArrayGetString(g_aHudAdverts, g_iCurrentHudAdvert, szAdvert, charsmax(szAdvert));
    replace_all(szAdvert, charsmax(szAdvert), "%newline%", "^n");

    new mapname[32], hostname[64];
    get_mapname(mapname, charsmax(mapname));
    get_cvar_string("hostname", hostname, charsmax(hostname));

    new players[32], pnum, i, player, szFormatted[MAX_LENGTH];
    get_players(players, pnum, "ch");

    new colorR = random(256), colorG = random(256), colorB = random(256);

    for(i = 0; i < pnum; i++) {
        player = players[i];
        
        if(_:(GetLangTransKey(szAdvert)) != -1) {
            LookupLangKey(szFormatted, charsmax(szFormatted), szAdvert, player);
        } else {
            copy(szFormatted, charsmax(szFormatted), szAdvert);
        }

        replace_all(szFormatted, charsmax(szFormatted), "%map%", mapname);
        replace_all(szFormatted, charsmax(szFormatted), "%servername%", hostname);
        replace_all(szFormatted, charsmax(szFormatted), "%tag%", g_szTag);

        set_hudmessage(
            colorR, colorG, colorB,
            get_pcvar_float(g_pCvarPosX),
            get_pcvar_float(g_pCvarPosY),
            get_pcvar_num(g_pCvarEffectType),
            get_pcvar_float(g_pCvarFadeIn),
            get_pcvar_float(g_pCvarFadeOut),
            get_pcvar_float(g_pCvarHoldTime),
            0.1,
            -1
        );
        show_hudmessage(player, "%s", szFormatted);
    }
    
    if(get_pcvar_num(g_pCvarRandomOrder)) {
        g_iCurrentHudAdvert = random(g_iHudAdvertCount);
    } else {
        g_iCurrentHudAdvert = (g_iCurrentHudAdvert + 1) % g_iHudAdvertCount;
    }
}

public DisplayChatAdvert() {
    if(!get_pcvar_num(g_pCvarChatEnabled)) {
        return;
    }

    if(!g_iChatAdvertCount || g_aChatAdverts == Invalid_Array) {
        return;
    }

    if(g_iCurrentChatAdvert < 0 || g_iCurrentChatAdvert >= g_iChatAdvertCount) {
        g_iCurrentChatAdvert = 0;
    }

    new szAdvert[MAX_LENGTH];
    ArrayGetString(g_aChatAdverts, g_iCurrentChatAdvert, szAdvert, charsmax(szAdvert));

    new mapname[32], hostname[64];
    get_mapname(mapname, charsmax(mapname));
    get_cvar_string("hostname", hostname, charsmax(hostname));

    new players[32], pnum, i, player, szBody[MAX_LENGTH], szColored[MAX_LENGTH];
    get_players(players, pnum, "ch");

    for(i = 0; i < pnum; i++) {
        player = players[i];

        if(_:(GetLangTransKey(szAdvert)) != -1) {
            LookupLangKey(szBody, charsmax(szBody), szAdvert, player);
        } else {
            copy(szBody, charsmax(szBody), szAdvert);
        }

        replace_all(szBody, charsmax(szBody), "%map%", mapname);
        replace_all(szBody, charsmax(szBody), "%servername%", hostname);
        replace_all(szBody, charsmax(szBody), "%tag%", g_szTag);

        formatex(szColored, charsmax(szColored), "%s !n%s", g_szTag, szBody);
        TranslateChatColors(szColored, charsmax(szColored));

        client_print_color(player, print_team_blue, "%s", szColored);
    }

    if(get_pcvar_num(g_pCvarChatRandomOrder)) {
        g_iCurrentChatAdvert = random(g_iChatAdvertCount);
    } else {
        g_iCurrentChatAdvert = (g_iCurrentChatAdvert + 1) % g_iChatAdvertCount;
    }
}

public HookSay(id) {
    if(!is_user_connected(id)) return PLUGIN_CONTINUE;
    if(!get_pcvar_num(g_pCvarChatCmdEnabled)) return PLUGIN_CONTINUE;
    if(g_tChatCommands == Invalid_Trie) return PLUGIN_CONTINUE;

    new szSaid[192];
    read_args(szSaid, charsmax(szSaid));
    remove_quotes(szSaid);
    trim(szSaid);

    if(!szSaid[0]) return PLUGIN_CONTINUE;

    new szMsg[192];
    copy(szMsg, charsmax(szMsg), szSaid);

    new szToken[64], szRest[192], szMatchedKey[64], szMatchedValue[MAX_LENGTH];
    new bool:bMatched = false;

    while(szMsg[0]) {
        szRest[0] = 0;
        strtok(szMsg, szToken, charsmax(szToken), szRest, charsmax(szRest), ' ');
        copy(szMsg, charsmax(szMsg), szRest);

        trim(szToken);
        if(!szToken[0]) continue;

        if(szToken[0] == '/' || szToken[0] == '!') {
            if(szToken[1]) {
                for(new i = 0; i < charsmax(szToken) - 1; i++) {
                    szToken[i] = szToken[i + 1];
                }
                szToken[charsmax(szToken) - 1] = 0;
            } else continue;
        }

        new len = strlen(szToken);
        while(len > 0 && !IsWordChar(szToken[len - 1])) {
            szToken[len - 1] = 0;
            len--;
        }

        if(!szToken[0]) continue;

        strtolower(szToken);

        if(TrieGetString(g_tChatCommands, szToken, szMatchedValue, charsmax(szMatchedValue))) {
            copy(szMatchedKey, charsmax(szMatchedKey), szToken);
            bMatched = true;
            break;
        }
    }

    if(!bMatched) return PLUGIN_CONTINUE;

    new bool:bExactCommand = false;
    new szExact[192];
    copy(szExact, charsmax(szExact), szSaid);
    trim(szExact);
    if(szExact[0] == '/' || szExact[0] == '!') {
        if(szExact[1]) {
            for(new i = 0; i < charsmax(szExact) - 1; i++) {
                szExact[i] = szExact[i + 1];
            }
            szExact[charsmax(szExact) - 1] = 0;
        }
    }
    trim(szExact);
    strtolower(szExact);
    if(szExact[0] && equali(szExact, szMatchedKey)) {
        bExactCommand = true;
    }

    new Float:flCooldown = get_pcvar_float(g_pCvarChatCmdCooldown);
    if(flCooldown < 0.0) flCooldown = 0.0;

    new Float:flNow = get_gametime();
    if(flNow < g_flNextChatCmdAllowed[id]) {
        if(bExactCommand) return PLUGIN_HANDLED;
        return PLUGIN_CONTINUE;
    }
    g_flNextChatCmdAllowed[id] = flNow + flCooldown;

    new mapname[32], hostname[64];
    get_mapname(mapname, charsmax(mapname));
    get_cvar_string("hostname", hostname, charsmax(hostname));

    new szBody[MAX_LENGTH], szColored[MAX_LENGTH];

    if(get_pcvar_num(g_pCvarChatCmdToAll)) {
        new players[32], pnum, i, player;
        get_players(players, pnum, "ch");
        for(i = 0; i < pnum; i++) {
            player = players[i];
            if(_:(GetLangTransKey(szMatchedValue)) != -1) {
                LookupLangKey(szBody, charsmax(szBody), szMatchedValue, player);
            } else {
                copy(szBody, charsmax(szBody), szMatchedValue);
            }
            replace_all(szBody, charsmax(szBody), "%map%", mapname);
            replace_all(szBody, charsmax(szBody), "%servername%", hostname);
            replace_all(szBody, charsmax(szBody), "%tag%", g_szTag);

            formatex(szColored, charsmax(szColored), "%s !n%s", g_szTag, szBody);
            TranslateChatColors(szColored, charsmax(szColored));

            client_print_color(player, print_team_blue, "%s", szColored);
        }
    } else {
        if(_:(GetLangTransKey(szMatchedValue)) != -1) {
            LookupLangKey(szBody, charsmax(szBody), szMatchedValue, id);
        } else {
            copy(szBody, charsmax(szBody), szMatchedValue);
        }
        replace_all(szBody, charsmax(szBody), "%map%", mapname);
        replace_all(szBody, charsmax(szBody), "%servername%", hostname);
        replace_all(szBody, charsmax(szBody), "%tag%", g_szTag);

        formatex(szColored, charsmax(szColored), "%s !n%s", g_szTag, szBody);
        TranslateChatColors(szColored, charsmax(szColored));

        client_print_color(id, print_team_blue, "%s", szColored);
    }

    if(bExactCommand) return PLUGIN_HANDLED;

    return PLUGIN_CONTINUE;
}

IsWordChar(iChar) {
    if(iChar >= '0' && iChar <= '9') return 1;
    if(iChar >= 'a' && iChar <= 'z') return 1;
    if(iChar >= 'A' && iChar <= 'Z') return 1;
    if(iChar == '_' || iChar == '-') return 1;
    return 0;
}

TranslateChatColors(szText[], iLen) {
    if(!iLen || !szText[0]) return;
    replace_all(szText, iLen, "!g", "^x04");
    replace_all(szText, iLen, "!t", "^x03");
    replace_all(szText, iLen, "!n", "^x01");
}
