#if defined _server_mute_included
	#endinput
#endif
#define _server_mute_included

#pragma reqlib server_mute
#if !defined AMXMODX_NOAUTOLOAD
	#pragma loadlib server_mute
#endif

#define GAG_CHAT    (1 << 0)
#define GAG_VOICE   (1 << 1)
#define GAG_ALL     (GAG_CHAT | GAG_VOICE)

/**
 * Checks if a player is globally gagged by an administrator.
 *
 * @param id        Player index (1..32)
 *
 * @return          true if gagged, false otherwise
 */
native bool:server_is_user_gagged(id);

/**
 * Gets the gag flags for a player.
 *
 * @param id        Player index (1..32)
 *
 * @return          Bitflag (GAG_CHAT, GAG_VOICE, or GAG_ALL), or 0 if not gagged
 */
native server_get_user_gag_flags(id);

/**
 * Gets the remaining gag duration in seconds for a player.
 *
 * @param id        Player index (1..32)
 *
 * @return          Remaining seconds, or 0 if not gagged
 */
native server_get_user_gag_remaining(id);

/**
 * Applies an admin gag to a player.
 *
 * @param id        Player index (1..32)
 * @param iMinutes  Duration in minutes
 * @param iFlags    Gag flags (GAG_CHAT, GAG_VOICE, GAG_ALL)
 * @param szAdmin   Name of the admin applying the gag
 *
 * @return          true on success, false otherwise
 */
native bool:server_gag_user(id, iMinutes, iFlags, const szAdmin[] = "");

/**
 * Removes an admin gag from a player.
 *
 * @param id        Player index (1..32)
 * @param szAdmin   Name of the admin removing the gag
 *
 * @return          true on success, false if not gagged
 */
native bool:server_ungag_user(id, const szAdmin[] = "");

/**
 * Checks if a player has muted another player (player-to-player mute).
 *
 * @param id        Listener player index (1..32)
 * @param iTarget   Target player index (1..32)
 *
 * @return          true if muted, false otherwise
 */
native bool:server_is_player_muted_by(id, iTarget);

/**
 * Forward called when a player is gagged by an admin.
 *
 * @param id        Player index
 * @param iAdmin    Admin player index (0 for console)
 * @param iMinutes  Duration in minutes
 * @param iFlags    Gag flags
 */
forward server_on_player_gagged(id, iAdmin, iMinutes, iFlags);

/**
 * Forward called when a player's gag is removed or expires.
 *
 * @param id        Player index
 * @param iAdmin    Admin player index (0 if expired automatically)
 */
forward server_on_player_ungagged(id, iAdmin);
