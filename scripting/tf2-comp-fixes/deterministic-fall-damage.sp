// Credit to https://github.com/stephanieLGBT/tf2-FallDamageFixer

#if defined _TF2_COMP_FIXES_DETERMINISTIC_FALL_DAMAGE
#endinput
#endif
#define _TF2_COMP_FIXES_DETERMINISTIC_FALL_DAMAGE

#include "common.sp"
#include <dhooks>
#include <sdktools>

static Handle g_detour_CTFGameRules_FlPlayerFallDamage;

void DeterministicFallDamage_Setup(Handle game_config) {
    g_detour_CTFGameRules_FlPlayerFallDamage =
        CheckedDHookCreateFromConf(game_config, "CTFGameRules::FlPlayerFallDamage");

    CreateBoolConVar("sm_deterministic_fall_damage", OnConVarChange);
}

static void OnConVarChange(ConVar cvar, const char[] before, const char[] after) {
    if (cvar.BoolValue == TruthyConVar(before)) {
        return;
    }

    if (!DHookToggleDetour(g_detour_CTFGameRules_FlPlayerFallDamage, HOOK_PRE,
                           Detour_CTFGameRules_FlPlayerFallDamage, cvar.BoolValue)) {
        SetFailState("Failed to toggle detour on CTFGameRules::FlPlayerFallDamage");
    }
}

static MRESReturn Detour_CTFGameRules_FlPlayerFallDamage(Address self, Handle ret, Handle params) {
    int   player        = DHookGetParam(params, 1);
    float fall_velocity = GetEntPropFloat(player, Prop_Send, "m_flFallVelocity");
    float fall_damage;

    if (fall_velocity > 650.0) {
        int max_health =
            GetEntProp(GetPlayerResourceEntity(), Prop_Send, "m_iMaxHealth", _, player);

        // 5 * (fall_velocity / 300) * (max_health / 100)
        fall_damage = fall_velocity * float(max_health) / 6000.0;
    } else {
        fall_damage = 0.0;
    }

    DHookSetReturn(ret, fall_damage);

    return MRES_Override;
}
