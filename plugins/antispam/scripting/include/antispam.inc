#if defined _antispam_included
	#endinput
#endif
#define _antispam_included

#pragma reqlib antispam
#if !defined AMXMODX_NOAUTOLOAD
	#pragma loadlib antispam
#endif

/**
 * Checks if a player is currently auto-muted by Anti-Spam.
 *
 * @param id        Player index (1..32)
 *
 * @return          true if muted, false otherwise
 */
native bool:antispam_is_user_muted(id);

/**
 * Gets the remaining auto-mute time in seconds for a player.
 *
 * @param id        Player index (1..32)
 *
 * @return          Float seconds remaining, or 0.0 if not muted
 */
native Float:antispam_get_user_mute_time(id);

/**
 * Sets or removes an auto-mute on a player.
 *
 * @param id        Player index (1..32)
 * @param fDuration Duration in seconds (0.0 or negative to unmute)
 *
 * @return          true on success, false if invalid player index
 */
native bool:antispam_set_user_mute(id, Float:fDuration);

/**
 * Checks if a string contains any word, link, or domain from antispam.ini [blacklist].
 *
 * @param szText    String to evaluate
 *
 * @return          true if blacklisted word is found, false otherwise
 */
native bool:antispam_has_blacklisted_word(const szText[]);

/**
 * Checks if a string contains a valid IPv4 address.
 *
 * @param szText    String to evaluate
 *
 * @return          true if IPv4 address is found, false otherwise
 */
native bool:antispam_is_ip_address(const szText[]);

/**
 * Forward called whenever a player receives an anti-spam sanction.
 *
 * @param id        Player index
 * @param iLevel    Sanction level (1=Warn, 2=Auto-Mute, 3=Kick, 4=Temp-Ban)
 * @param szReason  Offending message or incident detail
 */
forward antispam_on_sanction(id, iLevel, const szReason[]);
