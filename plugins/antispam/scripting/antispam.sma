#include <amxmodx>
#include <fakemeta>

#define PLUGIN  "Anti-Spam & Chat Filter"
#define VERSION "1.0"
#define AUTHOR  "Francisc0001"

new const PREFIX_MSG[] = "^4[AntiSpam] ^1";
new const CONSOLE_PREFIX[] = "[AntiSpam] ";
new const FILE_CONFIG[] = "antispam.ini";

#if !defined MAX_PLAYERS
#define MAX_PLAYERS 32
#endif

new Array:g_aBlockedWords;
new Array:g_aWhitelistWords;

#define MAX_MSG_LEN 192

// Default settings loaded from antispam.ini [settings]
new Float:g_fMuteDuration = 60.0;
new g_iBanDuration = 15;
new Float:g_fReoffenseWindow = 45.0;
new Float:g_fRepeatTimeWindow = 3.0;
new g_szRenamePrefix[32] = "Player";

new g_szLastMsg[MAX_PLAYERS + 1][MAX_MSG_LEN];
new Float:g_fLastMsgTime[MAX_PLAYERS + 1];
new g_iRepeatCount[MAX_PLAYERS + 1];
new g_iOffenseLevel[MAX_PLAYERS + 1];
new Float:g_fLastOffenseTime[MAX_PLAYERS + 1];
new Float:g_fMuteExpireTime[MAX_PLAYERS + 1];

new g_fwdOnSanction;

enum
{
	SEC_NONE = 0,
	SEC_SETTINGS,
	SEC_BLACKLIST,
	SEC_WHITELIST
};

public plugin_natives()
{
	register_library("antispam");
	register_native("antispam_is_user_muted", "_native_is_user_muted");
	register_native("antispam_get_user_mute_time", "_native_get_user_mute_time");
	register_native("antispam_set_user_mute", "_native_set_user_mute");
	register_native("antispam_has_blacklisted_word", "_native_has_blacklisted_word");
	register_native("antispam_is_ip_address", "_native_is_ip_address");
}

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR);
	register_dictionary("antispam.txt");
	register_dictionary("common.txt");

	register_clcmd("say", "cmd_HandleSay");
	register_clcmd("say_team", "cmd_HandleSay");

	register_concmd("antispam_reload", "cmd_ReloadConfig", ADMIN_RCON, "Reloads antispam.ini");

	register_forward(FM_ClientUserInfoChanged, "fw_ClientUserInfoChanged");

	g_fwdOnSanction = CreateMultiForward("antispam_on_sanction", ET_IGNORE, FP_CELL, FP_CELL, FP_STRING);

	g_aBlockedWords = ArrayCreate(64, 1);
	g_aWhitelistWords = ArrayCreate(32, 1);

	load_config();
}

public plugin_end()
{
	if (g_aBlockedWords != Invalid_Array)
	{
		ArrayDestroy(g_aBlockedWords);
		g_aBlockedWords = Invalid_Array;
	}

	if (g_aWhitelistWords != Invalid_Array)
	{
		ArrayDestroy(g_aWhitelistWords);
		g_aWhitelistWords = Invalid_Array;
	}
}

public client_putinserver(id)
{
	resetPlayerData(id);
	if (!is_user_bot(id))
	{
		checkPlayerName(id);
	}
}

public client_disconnected(id)
{
	resetPlayerData(id);
}

resetPlayerData(id)
{
	g_szLastMsg[id][0] = 0;
	g_fLastMsgTime[id] = 0.0;
	g_iRepeatCount[id] = 0;
	g_iOffenseLevel[id] = 0;
	g_fLastOffenseTime[id] = 0.0;
	g_fMuteExpireTime[id] = 0.0;
}

public fw_ClientUserInfoChanged(id, buffer)
{
	if (!is_user_connected(id) || is_user_bot(id))
		return FMRES_IGNORED;

	new szNewName[32], szOldName[32];
	get_user_name(id, szOldName, charsmax(szOldName));
	engfunc(EngFunc_InfoKeyValue, buffer, "name", szNewName, charsmax(szNewName));

	if (equal(szNewName, szOldName))
		return FMRES_IGNORED;

	new bool:bIsIP = is_ip_address(szNewName);
	new bool:bIsWord = has_blacklisted_word(szNewName);

	if (bIsIP || bIsWord)
	{
		new szReason[32];
		if (is_user_admin(id))
			copy(szReason, charsmax(szReason), bIsIP ? "NICK_IP_ADMIN" : "NICK_WORD_ADMIN");
		else
			copy(szReason, charsmax(szReason), bIsIP ? "NICK_IP_BLOCKED" : "NICK_WORD_BLOCKED");

		logIncident(id, szReason, szNewName);

		// If player is not admin, force rename
		if (!is_user_admin(id))
		{
			new szCleanName[32];
			formatex(szCleanName, charsmax(szCleanName), "%s_%d", g_szRenamePrefix, id);
			engfunc(EngFunc_SetClientKeyValue, id, buffer, "name", szCleanName);

			new szLangKey[32];
			copy(szLangKey, charsmax(szLangKey), bIsIP ? "ANTISPAM_NICK_IP_BLOCKED" : "ANTISPAM_NICK_WORD_BLOCKED");
			client_print_color(id, print_team_red, "%s%L", PREFIX_MSG, id, szLangKey, szCleanName);
			return FMRES_HANDLED;
		}
		else
		{
			client_print_color(id, print_team_red, "%s%L", PREFIX_MSG, id, "ANTISPAM_ADMIN_WARN");
		}
	}

	return FMRES_IGNORED;
}

checkPlayerName(id)
{
	if (!is_user_connected(id) || is_user_bot(id))
		return;

	new szName[32];
	get_user_name(id, szName, charsmax(szName));

	new bool:bIsIP = is_ip_address(szName);
	new bool:bIsWord = has_blacklisted_word(szName);

	if (bIsIP || bIsWord)
	{
		new szReason[32];
		if (is_user_admin(id))
			copy(szReason, charsmax(szReason), bIsIP ? "NICK_IP_ADMIN" : "NICK_WORD_ADMIN");
		else
			copy(szReason, charsmax(szReason), bIsIP ? "NICK_IP_BLOCKED" : "NICK_WORD_BLOCKED");

		logIncident(id, szReason, szName);

		if (!is_user_admin(id))
		{
			new szCleanName[32];
			formatex(szCleanName, charsmax(szCleanName), "%s_%d", g_szRenamePrefix, id);
			set_user_info(id, "name", szCleanName);

			new szLangKey[32];
			copy(szLangKey, charsmax(szLangKey), bIsIP ? "ANTISPAM_NICK_IP_BLOCKED" : "ANTISPAM_NICK_WORD_BLOCKED");
			client_print_color(id, print_team_red, "%s%L", PREFIX_MSG, id, szLangKey, szCleanName);
		}
		else
		{
			client_print_color(id, print_team_red, "%s%L", PREFIX_MSG, id, "ANTISPAM_ADMIN_WARN");
		}
	}
}

public cmd_HandleSay(id)
{
	if (!is_user_connected(id) || is_user_bot(id))
		return PLUGIN_CONTINUE;

	new Float:fGametime = get_gametime();

	// 0. Check if player is currently auto-muted
	if (!is_user_admin(id) && g_fMuteExpireTime[id] > fGametime)
	{
		new iRemaining = floatround(g_fMuteExpireTime[id] - fGametime, floatround_ceil);
		client_print_color(id, print_team_red, "%s%L", PREFIX_MSG, id, "ANTISPAM_MUTED_REMAINING", iRemaining);
		return PLUGIN_HANDLED;
	}

	new szArgs[MAX_MSG_LEN];
	read_args(szArgs, charsmax(szArgs));
	remove_quotes(szArgs);
	trim(szArgs);

	if (szArgs[0] == 0)
		return PLUGIN_CONTINUE;

	// 1. IP address or blacklisted word/domain detection
	new bool:bIsIP = is_ip_address(szArgs);
	new bool:bIsWord = has_blacklisted_word(szArgs);
	if (bIsIP || bIsWord)
	{
		new szLangKey[32];
		copy(szLangKey, charsmax(szLangKey), bIsIP ? "ANTISPAM_IP_BLOCKED" : "ANTISPAM_WORD_BLOCKED");
		client_print_color(id, print_team_red, "%s%L", PREFIX_MSG, id, szLangKey);
		escalateSanction(id, fGametime, true, szArgs);
		return PLUGIN_HANDLED;
	}

	// 2. Command or whitelist bypass (starts with '/', '!', '.' or in whitelist)
	if (szArgs[0] == '/' || szArgs[0] == '!' || szArgs[0] == '.' || is_game_command(szArgs))
	{
		return PLUGIN_CONTINUE;
	}

	// 3. Admin bypass
	if (is_user_admin(id))
	{
		return PLUGIN_CONTINUE;
	}

	// 4. Repeated rapid flood check
	new bool:bIsRepeat = bool:equal(szArgs, g_szLastMsg[id]);
	new bool:bIsFast = bool:(g_fLastMsgTime[id] > 0.0 && (fGametime - g_fLastMsgTime[id]) < g_fRepeatTimeWindow);

	if (bIsRepeat && bIsFast)
	{
		g_iRepeatCount[id]++;
	}
	else
	{
		g_iRepeatCount[id] = 1;
		copy(g_szLastMsg[id], charsmax(g_szLastMsg[]), szArgs);
	}

	g_fLastMsgTime[id] = fGametime;

	if (bIsRepeat && bIsFast && g_iRepeatCount[id] >= 4)
	{
		escalateSanction(id, fGametime, false, szArgs);
		return PLUGIN_HANDLED;
	}

	return PLUGIN_CONTINUE;
}

escalateSanction(id, Float:fGametime, bool:bIsIPOrWord, const szMessage[])
{
	// Admin warning only
	if (is_user_admin(id))
	{
		if (bIsIPOrWord)
		{
			logIncident(id, "ADMIN_PUBLICIDAD_O_PALABRA", szMessage);
			client_print_color(id, print_team_red, "%s%L", PREFIX_MSG, id, "ANTISPAM_ADMIN_WARN");
		}
		return;
	}

	// Normal player escalation
	if (g_fLastOffenseTime[id] > 0.0 && (fGametime - g_fLastOffenseTime[id]) < g_fReoffenseWindow)
	{
		g_iOffenseLevel[id]++;
	}
	else
	{
		g_iOffenseLevel[id] = bIsIPOrWord ? 2 : 1;
	}

	g_fLastOffenseTime[id] = fGametime;

	new szName[32];
	get_user_name(id, szName, charsmax(szName));

	switch (g_iOffenseLevel[id])
	{
		case 1:
		{
			logIncident(id, "ADVERTENCIA_CHAT", szMessage);
			client_print_color(id, print_team_red, "%s%L", PREFIX_MSG, id, "ANTISPAM_WARN");
		}
		case 2:
		{
			g_fMuteExpireTime[id] = fGametime + g_fMuteDuration;
			logIncident(id, "AUTO_MUTE", szMessage);
			client_print_color(id, print_team_red, "%s%L", PREFIX_MSG, id, "ANTISPAM_AUTO_MUTED", floatround(g_fMuteDuration));
			client_print_color(0, print_team_grey, "%s%L", PREFIX_MSG, LANG_PLAYER, "ANTISPAM_ANNOUNCE_MUTE", szName, floatround(g_fMuteDuration));
		}
		case 3:
		{
			logIncident(id, "KICK_EXPULSION", szMessage);
			new szKickReason[64];
			formatex(szKickReason, charsmax(szKickReason), "%L", id, "ANTISPAM_KICK_REASON");
			server_cmd("kick #%d ^"%s^"", get_user_userid(id), szKickReason);
			client_print_color(0, print_team_grey, "%s%L", PREFIX_MSG, LANG_PLAYER, "ANTISPAM_ANNOUNCE_KICK", szName);
		}
		default:
		{
			logIncident(id, "TEMP_BAN", szMessage);
			new szBanReason[64];
			formatex(szBanReason, charsmax(szBanReason), "%L", id, "ANTISPAM_BAN_REASON");
			server_cmd("amx_ban %d #%d ^"%s^"", g_iBanDuration, get_user_userid(id), szBanReason);
			client_print_color(0, print_team_grey, "%s%L", PREFIX_MSG, LANG_PLAYER, "ANTISPAM_ANNOUNCE_BAN", szName, g_iBanDuration);
		}
	}

	new iRet;
	ExecuteForward(g_fwdOnSanction, iRet, id, g_iOffenseLevel[id], szMessage);
}

logIncident(id, const szSanctionType[], const szDetail[])
{
	new szName[32], szAuthId[32], szUserIP[32];
	get_user_name(id, szName, charsmax(szName));
	get_user_authid(id, szAuthId, charsmax(szAuthId));
	get_user_ip(id, szUserIP, charsmax(szUserIP), 1);

	log_to_file("antispam_incidents.log", "[INCIDENTE] Player: ^"%s^" | SteamID: %s | IP: %s | Sanction: %s | Detail: ^"%s^"",
		szName, szAuthId, szUserIP, szSanctionType, szDetail);
}

bool:is_user_admin(id)
{
	if (!is_user_connected(id) || is_user_bot(id))
		return false;

	new iFlags = get_user_flags(id);
	if (iFlags & (ADMIN_CHAT | ADMIN_BAN | ADMIN_KICK | ADMIN_IMMUNITY | ADMIN_RCON))
		return true;

	return false;
}

bool:is_game_command(const szMsg[])
{
	if (g_aWhitelistWords == Invalid_Array)
		return false;

	new szFirstWord[32];
	parse(szMsg, szFirstWord, charsmax(szFirstWord));
	trim(szFirstWord);
	strtolower(szFirstWord);

	if (!szFirstWord[0])
		return false;

	new iSize = ArraySize(g_aWhitelistWords);
	new szWord[32];

	for (new i = 0; i < iSize; i++)
	{
		ArrayGetString(g_aWhitelistWords, i, szWord, charsmax(szWord));
		if (equal(szFirstWord, szWord) || equal(szMsg, szWord))
			return true;
	}

	return false;
}

bool:is_ip_address(const szText[])
{
	new iLen = strlen(szText);
	if (iLen < 7)
		return false;

	new szDigits[4];
	new iDigitsLen = 0;
	new iOctetCount = 0;
	new bool:bValidIp = false;

	for (new i = 0; i <= iLen; i++)
	{
		new c = szText[i];

		if (c >= '0' && c <= '9')
		{
			if (iDigitsLen < 3)
			{
				szDigits[iDigitsLen++] = c;
			}
			else
			{
				bValidIp = false;
				iOctetCount = 0;
				iDigitsLen = 0;
			}
		}
		else if (c == '.' || c == ',' || c == ':' || c == ' ' || c == 0)
		{
			if (iDigitsLen > 0)
			{
				szDigits[iDigitsLen] = 0;
				new iVal = str_to_num(szDigits);
				iDigitsLen = 0;

				if (iVal >= 0 && iVal <= 255)
				{
					iOctetCount++;
					if (iOctetCount == 4)
					{
						bValidIp = true;
						break;
					}
				}
				else
				{
					bValidIp = false;
					iOctetCount = 0;
				}
			}
			else if (c == 0)
			{
				break;
			}
		}
		else
		{
			if (iOctetCount > 0 && iOctetCount < 4)
			{
				if (c != '-' && c != '_')
				{
					iOctetCount = 0;
					iDigitsLen = 0;
					bValidIp = false;
					break;
				}
			}

			if (bValidIp && iOctetCount == 4)
			{
				return true;
			}
		}
	}

	return false;
}

public cmd_ReloadConfig(id)
{
	if (id && !(get_user_flags(id) & ADMIN_RCON))
		return PLUGIN_HANDLED;

	load_config();
	console_print(id, "%s%L", CONSOLE_PREFIX, id, "ANTISPAM_RELOAD_SUCCESS", ArraySize(g_aBlockedWords), ArraySize(g_aWhitelistWords));
	return PLUGIN_HANDLED;
}

load_config()
{
	if (g_aBlockedWords == Invalid_Array)
		g_aBlockedWords = ArrayCreate(64, 1);
	else
		ArrayClear(g_aBlockedWords);

	if (g_aWhitelistWords == Invalid_Array)
		g_aWhitelistWords = ArrayCreate(32, 1);
	else
		ArrayClear(g_aWhitelistWords);

	new szConfigsDir[64];
	get_localinfo("amxx_configsdir", szConfigsDir, charsmax(szConfigsDir));

	new szFilePath[128];
	formatex(szFilePath, charsmax(szFilePath), "%s/%s", szConfigsDir, FILE_CONFIG);

	if (!file_exists(szFilePath))
	{
		log_amx("[ANTISPAM] File %s not found.", szFilePath);
		return 0;
	}

	new f = fopen(szFilePath, "rt");
	if (!f)
		return 0;

	new szLine[128], szWord[64];
	new iCurrentSection = SEC_NONE;

	while (!feof(f))
	{
		fgets(f, szLine, charsmax(szLine));
		trim(szLine);

		if (!szLine[0] || szLine[0] == ';' || szLine[0] == '#')
			continue;

		if (szLine[0] == '/' && szLine[1] == '/')
			continue;

		if (szLine[0] == '[')
		{
			if (containi(szLine, "settings") != -1)
				iCurrentSection = SEC_SETTINGS;
			else if (containi(szLine, "blacklist") != -1)
				iCurrentSection = SEC_BLACKLIST;
			else if (containi(szLine, "whitelist") != -1)
				iCurrentSection = SEC_WHITELIST;
			else
				iCurrentSection = SEC_NONE;
			continue;
		}

		switch (iCurrentSection)
		{
			case SEC_SETTINGS:
			{
				new szKey[32], szVal[32];
				strtok(szLine, szKey, charsmax(szKey), szVal, charsmax(szVal), '=');
				trim(szKey);
				trim(szVal);

				if (equali(szKey, "mute_duration"))
					g_fMuteDuration = floatstr(szVal);
				else if (equali(szKey, "ban_duration"))
					g_iBanDuration = str_to_num(szVal);
				else if (equali(szKey, "reoffense_window"))
					g_fReoffenseWindow = floatstr(szVal);
				else if (equali(szKey, "repeat_time_window"))
					g_fRepeatTimeWindow = floatstr(szVal);
				else if (equali(szKey, "rename_prefix"))
				{
					parse(szVal, g_szRenamePrefix, charsmax(g_szRenamePrefix));
					trim(g_szRenamePrefix);
					if (!g_szRenamePrefix[0])
						copy(g_szRenamePrefix, charsmax(g_szRenamePrefix), "Player");
				}
			}
			case SEC_BLACKLIST:
			{
				parse(szLine, szWord, charsmax(szWord));
				trim(szWord);
				strtolower(szWord);

				if (szWord[0])
				{
					ArrayPushString(g_aBlockedWords, szWord);
				}
			}
			case SEC_WHITELIST:
			{
				parse(szLine, szWord, charsmax(szWord));
				trim(szWord);
				strtolower(szWord);

				if (szWord[0])
				{
					ArrayPushString(g_aWhitelistWords, szWord);
				}
			}
		}
	}
	fclose(f);

	server_print("%s%L", CONSOLE_PREFIX, LANG_SERVER, "ANTISPAM_CONFIG_LOADED", FILE_CONFIG, ArraySize(g_aBlockedWords), ArraySize(g_aWhitelistWords));
	return ArraySize(g_aBlockedWords);
}

bool:has_blacklisted_word(const szText[])
{
	if (g_aBlockedWords == Invalid_Array)
		return false;

	new iSize = ArraySize(g_aBlockedWords);
	new szWord[64];

	for (new i = 0; i < iSize; i++)
	{
		ArrayGetString(g_aBlockedWords, i, szWord, charsmax(szWord));
		if (szWord[0] && containi(szText, szWord) != -1)
		{
			return true;
		}
	}
	return false;
}

public bool:_native_is_user_muted(iPlugin, iParams)
{
	new id = get_param(1);
	if (!is_user_connected(id))
		return false;

	return (g_fMuteExpireTime[id] > get_gametime());
}

public Float:_native_get_user_mute_time(iPlugin, iParams)
{
	new id = get_param(1);
	if (!is_user_connected(id))
		return 0.0;

	new Float:fGametime = get_gametime();
	if (g_fMuteExpireTime[id] <= fGametime)
		return 0.0;

	return (g_fMuteExpireTime[id] - fGametime);
}

public bool:_native_set_user_mute(iPlugin, iParams)
{
	new id = get_param(1);
	if (!is_user_connected(id))
		return false;

	new Float:fDuration = get_param_f(2);
	if (fDuration <= 0.0)
	{
		g_fMuteExpireTime[id] = 0.0;
	}
	else
	{
		g_fMuteExpireTime[id] = get_gametime() + fDuration;
	}
	return true;
}

public bool:_native_has_blacklisted_word(iPlugin, iParams)
{
	new szText[MAX_MSG_LEN];
	get_string(1, szText, charsmax(szText));
	return has_blacklisted_word(szText);
}

public bool:_native_is_ip_address(iPlugin, iParams)
{
	new szText[MAX_MSG_LEN];
	get_string(1, szText, charsmax(szText));
	return is_ip_address(szText);
}
