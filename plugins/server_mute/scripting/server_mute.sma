#include <amxmodx>
#include <amxmisc>
#include <fakemeta>
#include <nvault>

#include <server_mute>

#define PLUGIN 		"Player Mute & Admin Gag System"
#define VERSION 	"1.0"
#define AUTHOR 		"ggv (modificado por [F]rancisc0001)"

#define ADMIN_GAG_ACCESS (ADMIN_KICK | ADMIN_BAN | ADMIN_RCON)

#define GAG_CHAT    (1 << 0)
#define GAG_VOICE   (1 << 1)
#define GAG_ALL     (GAG_CHAT | GAG_VOICE)

new const g_szRadioCommands[][] = {
	"radio1", "radio2", "radio3", "radio",
	"coverme", "takepoint", "holdpos",
	"regroup", "followme", "takingfire",
	"go", "fallback", "sticktog",
	"getinpos", "stormfront", "report",
	"roger", "enemyspot", "needbackup",
	"sectorclear", "inposition", "reportingin",
	"getout", "negative", "enemydown"
};

// Player-to-player mute masks
new g_Muted[MAX_PLAYERS + 1];
new g_iMenuPage[MAX_PLAYERS + 1];

// Admin Gag global states
new g_iGagFlags[MAX_PLAYERS + 1];
new g_iGagExpire[MAX_PLAYERS + 1];
new g_szGagAdmin[MAX_PLAYERS + 1][32];

// Admin Menu selections
new g_iAdminSelectedTarget[MAX_PLAYERS + 1];
new g_iAdminSelectedType[MAX_PLAYERS + 1];     // 0: Chat+Voice, 1: Chat Only, 2: Voice Only
new g_iAdminSelectedTimeIdx[MAX_PLAYERS + 1];  // Index in g_iGagDurations

new const g_iGagDurations[] = { 5, 10, 30, 45, 60 };

new g_hVault = INVALID_HANDLE;

new Trie:g_tValidCommands = Invalid_Trie;

new g_szConfigFile[128];
new g_fwdOnGagged;
new g_fwdOnUngagged;


public plugin_init() {
	register_plugin(PLUGIN, VERSION, AUTHOR);

	InitValidCommands();

	register_message(get_user_msgid("TextMsg"), "TextMsg_Handler");
	register_message(get_user_msgid("SendAudio"), "SendAudio_Handler");
	register_message(get_user_msgid("SayText"), "Msg_SayText");

	// Player-to-player commands
	register_chat_cmd("mute", "cmdMuteMenu");
	register_chat_cmd("muteall", "cmdMuteAll");
	register_chat_cmd("unmuteall", "cmdUnmuteAll");

	// Admin Gag commands
	register_concmd("amx_gag", "cmdAdminGag", ADMIN_GAG_ACCESS, "<name/#userid/authid> [minutes] [flags: a/c/v] - Silenciar globalmente a un jugador");
	register_concmd("amx_ungag", "cmdAdminUngag", ADMIN_GAG_ACCESS, "<name/#userid/authid> - Des-silenciar globalmente a un jugador");
	register_clcmd("amx_gagmenu", "cmdAdminGagMenu", ADMIN_GAG_ACCESS, "- Menu de Administrador para silenciar jugadores");
	register_chat_cmd("gag", "cmdAdminGagMenu");
	register_chat_cmd("gagmenu", "cmdAdminGagMenu");
	register_chat_cmd("adminmute", "cmdAdminGagMenu");

	// Chat hooks for gag blocking
	register_clcmd("say", "HandleSay");
	register_clcmd("say_team", "HandleSayTeam");

	// Bloquear permanentemente todos los comandos y menus de radio en el servidor
	for (new i = 0; i < sizeof(g_szRadioCommands); ++i) {
		register_clcmd(g_szRadioCommands[i], "cmdBlockRadio");
	}

	register_forward(FM_Voice_SetClientListening, "fw_SetVoice");

	register_dictionary("server_mute.txt");
	register_dictionary("common.txt");

	g_hVault = nvault_open("admin_gags");

	set_task(1.0, "Task_CheckGags", _, _, _, "b");
	g_fwdOnGagged = CreateMultiForward("server_on_player_gagged", ET_IGNORE, FP_CELL, FP_CELL, FP_CELL, FP_CELL);
	g_fwdOnUngagged = CreateMultiForward("server_on_player_ungagged", ET_IGNORE, FP_CELL, FP_CELL);

}

public plugin_end() {
	if (g_hVault != INVALID_HANDLE) {
		nvault_close(g_hVault);
		g_hVault = INVALID_HANDLE;
	}

	if (g_tValidCommands != Invalid_Trie) {
		TrieDestroy(g_tValidCommands);
		g_tValidCommands = Invalid_Trie;
	}
}

CreateDefaultConfig() {
	new File = fopen(g_szConfigFile, "wt");
	if(File) {
		fprintf(File, "; ==============================================================================^n");
		fprintf(File, "; Configuracion de Comandos Permitidos Durante Gag (server_mute.ini)^n");
		fprintf(File, "; ==============================================================================^n");
		fprintf(File, "; Los jugadores con sancion de gag no pueden enviar mensajes publicos,^n");
		fprintf(File, "; pero si pueden ejecutar comandos utiles del servidor listados aqui.^n^n");
		fprintf(File, "[allowed_commands]^n");
		fprintf(File, "timeleft^n");
		fprintf(File, "thetime^n");
		fprintf(File, "nextmap^n");
		fprintf(File, "currentmap^n");
		fprintf(File, "rtv^n");
		fprintf(File, "nominate^n");
		fprintf(File, "nom^n");
		fprintf(File, "help^n");
		fprintf(File, "ayuda^n");
		fprintf(File, "rules^n");
		fprintf(File, "reglas^n");
		fprintf(File, "menu^n");
		fprintf(File, "rank^n");
		fprintf(File, "top15^n");
		fprintf(File, "stats^n");
		fprintf(File, "mute^n");
		fprintf(File, "unmute^n");
		fclose(File);
	}
}

InitValidCommands() {
	g_tValidCommands = TrieCreate();

	new szConfigDir[64];
	get_configsdir(szConfigDir, charsmax(szConfigDir));
	formatex(g_szConfigFile, charsmax(g_szConfigFile), "%s/server_mute.ini", szConfigDir);

	if(!file_exists(g_szConfigFile)) {
		CreateDefaultConfig();
	}

	new File = fopen(g_szConfigFile, "rt");
	if(!File) {
		TrieSetCell(g_tValidCommands, "timeleft", 1);
		TrieSetCell(g_tValidCommands, "thetime", 1);
		TrieSetCell(g_tValidCommands, "nextmap", 1);
		TrieSetCell(g_tValidCommands, "currentmap", 1);
		TrieSetCell(g_tValidCommands, "rtv", 1);
		TrieSetCell(g_tValidCommands, "nominate", 1);
		TrieSetCell(g_tValidCommands, "nom", 1);
		TrieSetCell(g_tValidCommands, "help", 1);
		TrieSetCell(g_tValidCommands, "ayuda", 1);
		TrieSetCell(g_tValidCommands, "rules", 1);
		TrieSetCell(g_tValidCommands, "reglas", 1);
		TrieSetCell(g_tValidCommands, "menu", 1);
		TrieSetCell(g_tValidCommands, "rank", 1);
		TrieSetCell(g_tValidCommands, "top15", 1);
		TrieSetCell(g_tValidCommands, "stats", 1);
		TrieSetCell(g_tValidCommands, "mute", 1);
		TrieSetCell(g_tValidCommands, "unmute", 1);
		return;
	}

	new szLine[64];
	new bool:bInCommands = false;
	while(!feof(File)) {
		fgets(File, szLine, charsmax(szLine));
		trim(szLine);

		if(!szLine[0] || szLine[0] == ';' || szLine[0] == '#')
			continue;

		if(szLine[0] == '[') {
			bInCommands = bool:equali(szLine, "[allowed_commands]");
			continue;
		}

		if(bInCommands) {
			strtolower(szLine);
			TrieSetCell(g_tValidCommands, szLine, 1);
		}
	}
	fclose(File);
}

public client_authorized(id) {
	g_Muted[id] = 0;
	g_iMenuPage[id] = 0;
	g_iGagFlags[id] = 0;
	g_iGagExpire[id] = 0;
	g_szGagAdmin[id][0] = 0;
	g_iAdminSelectedTarget[id] = 0;
	g_iAdminSelectedType[id] = 0;
	g_iAdminSelectedTimeIdx[id] = 0;

	LoadGag(id);
}

public client_disconnected(id) {
	// Limpiar el bit de este jugador en las mascaras de todos los demas para evitar herencias en el slot
	new maxpl = get_maxplayers();
	for (new i = 1; i <= maxpl; ++i) {
		g_Muted[i] &= ~(1 << id);
	}

	g_Muted[id] = 0;
	g_iMenuPage[id] = 0;
	g_iGagFlags[id] = 0;
	g_iGagExpire[id] = 0;
	g_szGagAdmin[id][0] = 0;
	g_iAdminSelectedTarget[id] = 0;
}

public cmdBlockRadio(id) {
	return PLUGIN_HANDLED;
}

public SendAudio_Handler(iMsgId, msg_dest, msg_entity) {
	new szMsg[128];
	get_msg_arg_string(2, szMsg, charsmax(szMsg));

	if (equal(szMsg, "%!MRAD_", 7)) {
		set_msg_arg_string(2, "");
		return PLUGIN_HANDLED;
	}

	return PLUGIN_CONTINUE;
}

public TextMsg_Handler(iMsgId, msg_dest, msg_entity) {
	new iType = get_msg_arg_int(1);

	if (iType != 5)
		return PLUGIN_CONTINUE;

	new szMsg[128];
	get_msg_arg_string(3, szMsg, charsmax(szMsg));

	if (equal(szMsg, "#Game_radio")) {
		set_msg_arg_string(3, "");
		return PLUGIN_HANDLED;
	}

	return PLUGIN_CONTINUE;
}

public Msg_SayText(iMsgId, msg_dest, msg_entity) {
	new iSender = get_msg_arg_int(1);

	if (iSender <= 0 || iSender > 32 || !is_user_connected(iSender))
		return PLUGIN_CONTINUE;

	if (!is_user_connected(msg_entity))
		return PLUGIN_CONTINUE;

	if (msg_entity == iSender)
		return PLUGIN_CONTINUE;

	// Si el receptor tiene silenciado al emisor (mute cliente a cliente), bloquear el mensaje
	if (g_Muted[msg_entity] & (1 << iSender)) {
		return PLUGIN_HANDLED;
	}

	return PLUGIN_CONTINUE;
}

// ============================================================
// CHAT HOOKS (Admin Gag Chat Block)
// ============================================================
public HandleSay(id) {
	return CheckChatGag(id);
}

public HandleSayTeam(id) {
	return CheckChatGag(id);
}

stock CheckChatGag(id) {
	if (!is_user_connected(id)) return PLUGIN_CONTINUE;

	if (g_iGagFlags[id] & GAG_CHAT) {
		new iNow = get_systime();
		if (iNow < g_iGagExpire[id]) {
			new szArgs[192];
			read_args(szArgs, charsmax(szArgs));
			remove_quotes(szArgs);
			trim(szArgs);

			// Verificar si inicia con prefijo de comando ('/', '!', o '.')
			if (szArgs[0] == '/' || szArgs[0] == '!' || szArgs[0] == '.') {
				// Extraer el nombre del comando sin prefijo ni argumentos
				new szCmd[32];
				copy(szCmd, charsmax(szCmd), szArgs[1]);
				trim(szCmd);
				strtolower(szCmd);

				new iSpace = contain(szCmd, " ");
				if (iSpace > 0) {
					szCmd[iSpace] = 0;
				}

				// Si es un comando valido del servidor, permitir que se ejecute
				if (szCmd[0] && g_tValidCommands != Invalid_Trie && TrieKeyExists(g_tValidCommands, szCmd)) {
					return PLUGIN_CONTINUE;
				}
			}

			// Si es texto de conversacion o un comando falso/no reconocido, bloquear el mensaje y avisar
			new iRemaining = g_iGagExpire[id] - iNow;
			new iMins = iRemaining / 60;
			new iSecs = iRemaining % 60;
			client_print_color(id, print_team_default, "%L", id, "GAG_BLOCKED_CHAT", iMins, iSecs);
			return PLUGIN_HANDLED;
		} else {
			RemoveGag(id, 0);
		}
	}

	return PLUGIN_CONTINUE;
}

// ============================================================
// VOICE FORWARD (Admin Gag Voice Block & Client Mute)
// ============================================================
public fw_SetVoice(iReceiver, iSender, bool:bIsListen) {
	if (iReceiver == iSender || !is_user_connected(iReceiver) || !is_user_connected(iSender))
		return FMRES_IGNORED;

	// 1. Check Global Admin Gag Voice
	if (g_iGagFlags[iSender] & GAG_VOICE) {
		new iNow = get_systime();
		if (iNow < g_iGagExpire[iSender]) {
			engfunc(EngFunc_SetClientListening, iReceiver, iSender, false);
			return FMRES_SUPERCEDE;
		} else {
			RemoveGag(iSender, 0);
		}
	}

	// 2. Check Player-to-Player Mute
	if (g_Muted[iReceiver] & (1 << iSender)) {
		engfunc(EngFunc_SetClientListening, iReceiver, iSender, false);
		return FMRES_SUPERCEDE;
	}

	engfunc(EngFunc_SetClientListening, iReceiver, iSender, true);
	return FMRES_SUPERCEDE;
}

// ============================================================
// PERIODIC GAG EXPIRATION CHECK
// ============================================================
public Task_CheckGags() {
	new iNow = get_systime();
	new maxpl = get_maxplayers();

	for (new i = 1; i <= maxpl; ++i) {
		if (is_user_connected(i) && g_iGagFlags[i] > 0) {
			if (iNow >= g_iGagExpire[i]) {
				RemoveGag(i, 0);
			}
		}
	}
}

// ============================================================
// PERSISTENCE (nVault)
// ============================================================
stock LoadGag(id) {
	if (is_user_bot(id) || is_user_hltv(id) || g_hVault == INVALID_HANDLE)
		return;

	new szAuth[36];
	get_user_authid(id, szAuth, charsmax(szAuth));
	if (!szAuth[0] || equal(szAuth, "BOT") || equal(szAuth, "STEAM_ID_PENDING") || equal(szAuth, "VALVE_ID_PENDING"))
		return;

	new szData[128];
	if (nvault_get(g_hVault, szAuth, szData, charsmax(szData))) {
		new szExpire[16], szFlags[8], szAdmin[32];
		parse(szData, szExpire, charsmax(szExpire), szFlags, charsmax(szFlags), szAdmin, charsmax(szAdmin));

		new iExpire = str_to_num(szExpire);
		new iNow = get_systime();

		if (iNow < iExpire) {
			g_iGagExpire[id] = iExpire;
			g_iGagFlags[id] = str_to_num(szFlags);
			copy(g_szGagAdmin[id], charsmax(g_szGagAdmin[]), szAdmin);
		} else {
			nvault_remove(g_hVault, szAuth);
		}
	}
}

stock SaveGag(id) {
	if (is_user_bot(id) || is_user_hltv(id) || g_hVault == INVALID_HANDLE)
		return;

	new szAuth[36];
	get_user_authid(id, szAuth, charsmax(szAuth));
	if (!szAuth[0] || equal(szAuth, "BOT") || equal(szAuth, "STEAM_ID_PENDING") || equal(szAuth, "VALVE_ID_PENDING"))
		return;

	if (g_iGagFlags[id] > 0 && g_iGagExpire[id] > get_systime()) {
		new szData[128];
		formatex(szData, charsmax(szData), "%d %d ^"%s^"", g_iGagExpire[id], g_iGagFlags[id], g_szGagAdmin[id]);
		nvault_set(g_hVault, szAuth, szData);
	} else {
		nvault_remove(g_hVault, szAuth);
	}
}

// ============================================================
// APPLY & REMOVE GAG CORE FUNCTIONS
// ============================================================
stock ApplyGag(iAdmin, iTarget, iMinutes, iFlags) {
	if (!is_user_connected(iTarget)) return;

	new iDuration = iMinutes * 60;
	g_iGagExpire[iTarget] = get_systime() + iDuration;
	g_iGagFlags[iTarget] = iFlags;

	new szAdminName[32], szTargetName[32];
	if (iAdmin > 0 && is_user_connected(iAdmin)) {
		get_user_name(iAdmin, szAdminName, charsmax(szAdminName));
	} else {
		copy(szAdminName, charsmax(szAdminName), "Server/Console");
	}
	get_user_name(iTarget, szTargetName, charsmax(szTargetName));
	copy(g_szGagAdmin[iTarget], charsmax(g_szGagAdmin[]), szAdminName);

	SaveGag(iTarget);

	new szTypeKey[32];
	if (iFlags == GAG_ALL) copy(szTypeKey, charsmax(szTypeKey), "GAG_TYPE_ALL");
	else if (iFlags == GAG_CHAT) copy(szTypeKey, charsmax(szTypeKey), "GAG_TYPE_CHAT");
	else copy(szTypeKey, charsmax(szTypeKey), "GAG_TYPE_VOICE");

	// Anuncio publico a todos los jugadores en su idioma respectivo
	new sPlayers[32], iNum, iPlayer;
	get_players(sPlayers, iNum, "ch");

	for (new i = 0; i < iNum; ++i) {
		iPlayer = sPlayers[i];
		new szTypeName[32];
		formatex(szTypeName, charsmax(szTypeName), "%L", iPlayer, szTypeKey);
		client_print_color(iPlayer, print_team_default, "%L", iPlayer, "GAG_APPLIED", szAdminName, szTargetName, iMinutes, szTypeName);
	}

	new iRet;
	ExecuteForward(g_fwdOnGagged, iRet, iTarget, iAdmin, iMinutes, iFlags);
}

stock RemoveGag(iTarget, iAdmin = 0) {
	if (!is_user_connected(iTarget) || g_iGagFlags[iTarget] == 0) return;

	g_iGagFlags[iTarget] = 0;
	g_iGagExpire[iTarget] = 0;
	g_szGagAdmin[iTarget][0] = 0;
	SaveGag(iTarget);

	new szTargetName[32];
	get_user_name(iTarget, szTargetName, charsmax(szTargetName));

	if (iAdmin > 0 && is_user_connected(iAdmin)) {
		new szAdminName[32];
		get_user_name(iAdmin, szAdminName, charsmax(szAdminName));

		new sPlayers[32], iNum, iPlayer;
		get_players(sPlayers, iNum, "ch");
		for (new i = 0; i < iNum; ++i) {
			iPlayer = sPlayers[i];
			client_print_color(iPlayer, print_team_default, "%L", iPlayer, "GAG_REMOVED", szAdminName, szTargetName);
		}
	} else {
		client_print_color(iTarget, print_team_default, "%L", iTarget, "GAG_EXPIRED");
	}

	new iRet;
	ExecuteForward(g_fwdOnUngagged, iRet, iTarget, iAdmin);
}

// ============================================================
// CONSOLE / CLCMD ADMIN GAG COMMANDS
// ============================================================
public cmdAdminGag(id, level, cid) {
	if (!cmd_access(id, level, cid, 2))
		return PLUGIN_HANDLED;

	new szArg1[32], szArg2[10], szArg3[10];
	read_argv(1, szArg1, charsmax(szArg1));
	read_argv(2, szArg2, charsmax(szArg2));
	read_argv(3, szArg3, charsmax(szArg3));

	new iTarget = cmd_target(id, szArg1, CMDTARGET_ALLOW_SELF);
	if (!iTarget)
		return PLUGIN_HANDLED;

	if (iTarget == id) {
		client_print_color(id, print_team_default, "%L", id, "GAG_CANNOT_SELF");
		return PLUGIN_HANDLED;
	}

	// Comprobacion de inmunidad
	if ((get_user_flags(iTarget) & ADMIN_IMMUNITY) && !(get_user_flags(id) & ADMIN_RCON)) {
		client_print_color(id, print_team_default, "%L", id, "GAG_IMMUNITY");
		return PLUGIN_HANDLED;
	}

	new iMinutes = str_to_num(szArg2);
	if (iMinutes <= 0)
		iMinutes = 10;

	new iFlags = GAG_ALL;
	if (containi(szArg3, "c") != -1 && containi(szArg3, "v") == -1)
		iFlags = GAG_CHAT;
	else if (containi(szArg3, "v") != -1 && containi(szArg3, "c") == -1)
		iFlags = GAG_VOICE;

	ApplyGag(id, iTarget, iMinutes, iFlags);
	return PLUGIN_HANDLED;
}

public cmdAdminUngag(id, level, cid) {
	if (!cmd_access(id, level, cid, 2))
		return PLUGIN_HANDLED;

	new szArg1[32];
	read_argv(1, szArg1, charsmax(szArg1));

	new iTarget = cmd_target(id, szArg1, CMDTARGET_ALLOW_SELF);
	if (!iTarget)
		return PLUGIN_HANDLED;

	if (g_iGagFlags[iTarget] == 0) {
		client_print_color(id, print_team_default, "%L", id, "GAG_NOT_GAGGED");
		return PLUGIN_HANDLED;
	}

	RemoveGag(iTarget, id);
	return PLUGIN_HANDLED;
}

// ============================================================
// ADMIN GAG INTERACTIVE MENU
// ============================================================
public cmdAdminGagMenu(id) {
	if (!is_user_connected(id)) return PLUGIN_HANDLED;

	if (!(get_user_flags(id) & ADMIN_GAG_ACCESS)) {
		client_print_color(id, print_team_default, "%L", id, "ADMINMENU_NO_ACCESS");
		return PLUGIN_HANDLED;
	}

	ShowAdminGagPlayerList(id, 0);
	return PLUGIN_HANDLED;
}

stock ShowAdminGagPlayerList(id, iPage = 0) {
	if (!is_user_connected(id)) return;

	new sPlayers[32], iNum, iPlayer;
	get_players(sPlayers, iNum, "ch");

	new szTitle[128];
	formatex(szTitle, charsmax(szTitle), "^n^n^n^n^n\r[Admin] \y%L\w^n", id, "ADMINMENU_GAG");
	new iMenu = menu_create(szTitle, "AdminGagList_Handler");

	new szItemText[128], szItemData[8], szName[32];
	new iNow = get_systime();

	for (new i = 0; i < iNum; ++i) {
		iPlayer = sPlayers[i];
		if (iPlayer == id) continue; // No listarse a si mismo

		get_user_name(iPlayer, szName, charsmax(szName));
		num_to_str(iPlayer, szItemData, charsmax(szItemData));

		if (g_iGagFlags[iPlayer] > 0 && iNow < g_iGagExpire[iPlayer]) {
			new iRemMins = (g_iGagExpire[iPlayer] - iNow) / 60;
			if (iRemMins <= 0) iRemMins = 1;

			new szTypeShort[16];
			if (g_iGagFlags[iPlayer] == GAG_ALL) formatex(szTypeShort, charsmax(szTypeShort), "Chat+Voz");
			else if (g_iGagFlags[iPlayer] == GAG_CHAT) formatex(szTypeShort, charsmax(szTypeShort), "Chat");
			else formatex(szTypeShort, charsmax(szTypeShort), "Voz");

			formatex(szItemText, charsmax(szItemText), "\w%s \d- \r[Gag: %dm (%s)]", szName, iRemMins, szTypeShort);
		} else {
			formatex(szItemText, charsmax(szItemText), "\w%s \d- \y[Limpio]", szName);
		}

		menu_additem(iMenu, szItemText, szItemData, 0);
	}

	new szExit[32], szNext[32], szBack[32];
	formatex(szExit, charsmax(szExit), "%L", id, "EXIT");
	formatex(szNext, charsmax(szNext), "%L", id, "MORE");
	formatex(szBack, charsmax(szBack), "%L", id, "BACK");

	menu_setprop(iMenu, MPROP_EXITNAME, szExit);
	menu_setprop(iMenu, MPROP_NEXTNAME, szNext);
	menu_setprop(iMenu, MPROP_BACKNAME, szBack);

	menu_display(id, iMenu, iPage);
}

public AdminGagList_Handler(id, menu, item) {
	if (item == MENU_EXIT) {
		menu_destroy(menu);
		return PLUGIN_HANDLED;
	}

	new szData[8], szName[64], iAccess, iCallback;
	menu_item_getinfo(menu, item, iAccess, szData, charsmax(szData), szName, charsmax(szName), iCallback);
	menu_destroy(menu);

	new iTarget = str_to_num(szData);
	if (!is_user_connected(iTarget)) {
		ShowAdminGagPlayerList(id, 0);
		return PLUGIN_HANDLED;
	}

	g_iAdminSelectedTarget[id] = iTarget;
	ShowAdminGagActionMenu(id);
	return PLUGIN_HANDLED;
}

stock ShowAdminGagActionMenu(id) {
	if (!is_user_connected(id)) return;

	new iTarget = g_iAdminSelectedTarget[id];
	if (!is_user_connected(iTarget)) {
		ShowAdminGagPlayerList(id, 0);
		return;
	}

	new szTargetName[32];
	get_user_name(iTarget, szTargetName, charsmax(szTargetName));

	new szTitle[256];
	new iNow = get_systime();

	if (g_iGagFlags[iTarget] > 0 && iNow < g_iGagExpire[iTarget]) {
		new iRemMins = (g_iGagExpire[iTarget] - iNow) / 60;
		new iRemSecs = (g_iGagExpire[iTarget] - iNow) % 60;
		formatex(szTitle, charsmax(szTitle), "^n^n^n^n^n\r[Admin] \yGag / Silenciar^n\wJugador: \y%s^n\wEstado: \rSilenciado (%dm %02ds restantes)^n", szTargetName, iRemMins, iRemSecs);
	} else {
		formatex(szTitle, charsmax(szTitle), "^n^n^n^n^n\r[Admin] \yGag / Silenciar^n\wJugador: \y%s^n\wEstado: \ySin Silenciar (Limpio)^n", szTargetName);
	}

	new iMenu = menu_create(szTitle, "AdminGagAction_Handler");
	new szItem[128];

	// 1. Tipo de Silencio
	new szTypeStr[32];
	switch (g_iAdminSelectedType[id]) {
		case 0: formatex(szTypeStr, charsmax(szTypeStr), "%L", id, "GAG_TYPE_ALL");
		case 1: formatex(szTypeStr, charsmax(szTypeStr), "%L", id, "GAG_TYPE_CHAT");
		case 2: formatex(szTypeStr, charsmax(szTypeStr), "%L", id, "GAG_TYPE_VOICE");
	}
	formatex(szItem, charsmax(szItem), "Tipo: \y[%s]", szTypeStr);
	menu_additem(iMenu, szItem, "type");

	// 2. Duracion
	new iDur = g_iGagDurations[g_iAdminSelectedTimeIdx[id]];
	formatex(szItem, charsmax(szItem), "Tiempo: \y[%d Minutos]", iDur);
	menu_additem(iMenu, szItem, "time");

	// 3. Aplicar
	formatex(szItem, charsmax(szItem), "\r[ APLICAR SILENCIO / GAG ]");
	menu_additem(iMenu, szItem, "apply");

	// 4. Des-silenciar
	if (g_iGagFlags[iTarget] > 0) {
		formatex(szItem, charsmax(szItem), "\y[ DES-SILENCIAR / UNGAG ]");
		menu_additem(iMenu, szItem, "ungag");
	} else {
		formatex(szItem, charsmax(szItem), "\d[ DES-SILENCIAR (No aplica) ]");
		menu_additem(iMenu, szItem, "ungag_no");
	}

	// 9. Volver
	formatex(szItem, charsmax(szItem), "%L", id, "BACK");
	menu_additem(iMenu, szItem, "back");

	new szExit[32];
	formatex(szExit, charsmax(szExit), "%L", id, "EXIT");
	menu_setprop(iMenu, MPROP_EXITNAME, szExit);

	menu_display(id, iMenu, 0);
}

public AdminGagAction_Handler(id, menu, item) {
	if (item == MENU_EXIT) {
		menu_destroy(menu);
		return PLUGIN_HANDLED;
	}

	new szData[16], szName[64], iAccess, iCallback;
	menu_item_getinfo(menu, item, iAccess, szData, charsmax(szData), szName, charsmax(szName), iCallback);
	menu_destroy(menu);

	new iTarget = g_iAdminSelectedTarget[id];
	if (!is_user_connected(iTarget)) {
		ShowAdminGagPlayerList(id, 0);
		return PLUGIN_HANDLED;
	}

	if (equal(szData, "type")) {
		g_iAdminSelectedType[id] = (g_iAdminSelectedType[id] + 1) % 3;
		ShowAdminGagActionMenu(id);
	}
	else if (equal(szData, "time")) {
		g_iAdminSelectedTimeIdx[id] = (g_iAdminSelectedTimeIdx[id] + 1) % sizeof(g_iGagDurations);
		ShowAdminGagActionMenu(id);
	}
	else if (equal(szData, "apply")) {
		// Inmunidad check
		if ((get_user_flags(iTarget) & ADMIN_IMMUNITY) && !(get_user_flags(id) & ADMIN_RCON)) {
			client_print_color(id, print_team_default, "%L", id, "GAG_IMMUNITY");
			ShowAdminGagActionMenu(id);
			return PLUGIN_HANDLED;
		}

		new iFlags = GAG_ALL;
		if (g_iAdminSelectedType[id] == 1) iFlags = GAG_CHAT;
		else if (g_iAdminSelectedType[id] == 2) iFlags = GAG_VOICE;

		new iMinutes = g_iGagDurations[g_iAdminSelectedTimeIdx[id]];
		ApplyGag(id, iTarget, iMinutes, iFlags);
		ShowAdminGagActionMenu(id);
	}
	else if (equal(szData, "ungag")) {
		RemoveGag(iTarget, id);
		ShowAdminGagActionMenu(id);
	}
	else if (equal(szData, "ungag_no")) {
		ShowAdminGagActionMenu(id);
	}
	else if (equal(szData, "back")) {
		ShowAdminGagPlayerList(id, 0);
	}

	return PLUGIN_HANDLED;
}

// ============================================================
// PLAYER-TO-PLAYER CLIENT MUTE MENU
// ============================================================
public cmdMuteAll(id) {
	if (!is_user_connected(id)) return PLUGIN_HANDLED;

	new sPlayers[32], iNum, iPlayer;
	get_players(sPlayers, iNum, "ch");

	new iCount = 0;
	for (new i = 0; i < iNum; ++i) {
		iPlayer = sPlayers[i];
		if (iPlayer != id) {
			g_Muted[id] |= (1 << iPlayer);
			iCount++;
		}
	}

	if (iCount == 0) {
		client_print_color(id, print_team_default, "%L", id, "MUTE_NO_PLAYERS");
	} else {
		client_print_color(id, print_team_default, "%L", id, "MUTE_ALL_MUTED");
	}

	return PLUGIN_HANDLED;
}

public cmdUnmuteAll(id) {
	if (!is_user_connected(id)) return PLUGIN_HANDLED;

	g_Muted[id] = 0;
	client_print_color(id, print_team_default, "%L", id, "MUTE_ALL_UNMUTED");

	return PLUGIN_HANDLED;
}

public cmdMuteMenu(id) {
	ShowMuteMenu(id, g_iMenuPage[id]);
	return PLUGIN_HANDLED;
}

stock ShowMuteMenu(id, iPage = 0) {
	if (!is_user_connected(id)) return;

	new sPlayers[32], iNum, iPlayer;
	get_players(sPlayers, iNum, "ch");

	new iOtherCount = 0;
	new iMutedCount = 0;
	for (new i = 0; i < iNum; ++i) {
		iPlayer = sPlayers[i];
		if (iPlayer != id) {
			iOtherCount++;
			if (g_Muted[id] & (1 << iPlayer)) {
				iMutedCount++;
			}
		}
	}

	if (iOtherCount == 0) {
		client_print_color(id, print_team_default, "%L", id, "MUTE_NO_PLAYERS");
		return;
	}

	new szTitle[128];
	formatex(szTitle, charsmax(szTitle), "\y%L \d(%d/%d)\w", id, "MAINMENU_MUTE", iMutedCount, iOtherCount);
	new i_Menu = menu_create(szTitle, "MuteMenu_Handler");

	new szMsg[128], szName[32], szItem[6];

	// Opcion 1: Silenciar a todos
	new bool:bAllMuted = (iOtherCount > 0 && iMutedCount == iOtherCount);
	if (bAllMuted)
		formatex(szMsg, charsmax(szMsg), "%L: \r[%L]", id, "MUTE_ALL_OPTION", id, "YES");
	else
		formatex(szMsg, charsmax(szMsg), "%L: \d[%L]", id, "MUTE_ALL_OPTION", id, "NO");

	menu_additem(i_Menu, szMsg, "all", 0);

	// Lista de jugadores
	for (new i = 0; i < iNum; ++i) {
		iPlayer = sPlayers[i];

		if (id == iPlayer)
			continue;

		get_user_name(iPlayer, szName, charsmax(szName));
		num_to_str(iPlayer, szItem, charsmax(szItem));

		if (g_Muted[id] & (1 << iPlayer))
			formatex(szMsg, charsmax(szMsg), "%s \d- \r[%L]", szName, id, "MUTE_STATUS_MUTED");
		else
			formatex(szMsg, charsmax(szMsg), "%s \d- \y[%L]", szName, id, "MUTE_STATUS_LISTENING");

		menu_additem(i_Menu, szMsg, szItem, 0);
	}

	new szExit[32]; formatex(szExit, charsmax(szExit), "%L", id, "EXIT"); menu_setprop(i_Menu, MPROP_EXITNAME, szExit);
	new szNext[32]; formatex(szNext, charsmax(szNext), "%L", id, "MORE"); menu_setprop(i_Menu, MPROP_NEXTNAME, szNext);
	new szBack[32]; formatex(szBack, charsmax(szBack), "%L", id, "BACK"); menu_setprop(i_Menu, MPROP_BACKNAME, szBack);

	g_iMenuPage[id] = iPage;
	menu_display(id, i_Menu, iPage);
}

public MuteMenu_Handler(id, menu, item) {
	if (item == MENU_EXIT) {
		menu_destroy(menu);
		return PLUGIN_HANDLED;
	}
	
	new s_Data[6], s_Name[64], i_Access, i_Callback;
	menu_item_getinfo(menu, item, i_Access, s_Data, charsmax(s_Data), s_Name, charsmax(s_Name), i_Callback);

	// Calcular la pagina actual del menu en base al item presionado (7 items por pagina)
	new iCurrentPage = item / 7;
	g_iMenuPage[id] = iCurrentPage;

	if (equal(s_Data, "all")) {
		new sPlayers[32], iNum, iPlayer;
		get_players(sPlayers, iNum, "ch");

		new iOtherCount = 0, iMutedCount = 0;
		for (new i = 0; i < iNum; ++i) {
			iPlayer = sPlayers[i];
			if (iPlayer != id) {
				iOtherCount++;
				if (g_Muted[id] & (1 << iPlayer))
					iMutedCount++;
			}
		}

		if (iMutedCount == iOtherCount) {
			g_Muted[id] = 0;
			client_print_color(id, print_team_default, "%L", id, "MUTE_ALL_UNMUTED");
		} else {
			for (new i = 0; i < iNum; ++i) {
				iPlayer = sPlayers[i];
				if (iPlayer != id) {
					g_Muted[id] |= (1 << iPlayer);
				}
			}
			client_print_color(id, print_team_default, "%L", id, "MUTE_ALL_MUTED");
		}
	} else {
		new iTarget = str_to_num(s_Data);

		if (g_Muted[id] & (1 << iTarget))
			g_Muted[id] &= ~(1 << iTarget);
		else
			g_Muted[id] |= (1 << iTarget);
	}

	menu_destroy(menu);
	ShowMuteMenu(id, g_iMenuPage[id]);

	return PLUGIN_HANDLED;
}

stock register_chat_cmd(const szCmd[], const szHandler[])
{
	new szBuffer[64];
	formatex(szBuffer, charsmax(szBuffer), "say /%s", szCmd);
	register_clcmd(szBuffer, szHandler);
	formatex(szBuffer, charsmax(szBuffer), "say !%s", szCmd);
	register_clcmd(szBuffer, szHandler);
	formatex(szBuffer, charsmax(szBuffer), "say .%s", szCmd);
	register_clcmd(szBuffer, szHandler);
	register_clcmd(szCmd, szHandler);
}

public plugin_natives() {
	register_library("server_mute");
	register_native("server_is_user_gagged", "_native_is_user_gagged");
	register_native("server_get_user_gag_flags", "_native_get_user_gag_flags");
	register_native("server_get_user_gag_remaining", "_native_get_user_gag_remaining");
	register_native("server_gag_user", "_native_gag_user");
	register_native("server_ungag_user", "_native_ungag_user");
	register_native("server_is_player_muted_by", "_native_is_player_muted_by");
}

public bool:_native_is_user_gagged(iPlugin, iParams) {
	new id = get_param(1);
	if (!is_user_connected(id)) return false;
	return bool:(g_iGagFlags[id] > 0 && g_iGagExpire[id] > get_systime());
}

public _native_get_user_gag_flags(iPlugin, iParams) {
	new id = get_param(1);
	if (!is_user_connected(id) || g_iGagExpire[id] <= get_systime()) return 0;
	return g_iGagFlags[id];
}

public _native_get_user_gag_remaining(iPlugin, iParams) {
	new id = get_param(1);
	if (!is_user_connected(id)) return 0;
	new iNow = get_systime();
	if (g_iGagExpire[id] <= iNow) return 0;
	return (g_iGagExpire[id] - iNow);
}

public bool:_native_gag_user(iPlugin, iParams) {
	new id = get_param(1);
	if (!is_user_connected(id)) return false;
	new iMinutes = get_param(2);
	new iFlags = get_param(3);
	ApplyGag(0, id, iMinutes, iFlags);
	return true;
}

public bool:_native_ungag_user(iPlugin, iParams) {
	new id = get_param(1);
	if (!is_user_connected(id) || g_iGagFlags[id] == 0) return false;
	RemoveGag(id, 0);
	return true;
}

public bool:_native_is_player_muted_by(iPlugin, iParams) {
	new id = get_param(1);
	new iTarget = get_param(2);
	if (!is_user_connected(id) || !is_user_connected(iTarget)) return false;
	return bool:(g_Muted[id] & (1 << iTarget));
}
