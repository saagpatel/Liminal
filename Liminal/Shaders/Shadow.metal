// Shadow.metal — SCNShaderModifierEntryPointFragment
// Faux player-relative shadow: darkens floor fragments based on direction
// from player position, making shadow track the player instead of the light.

#pragma arguments
float playerPositionX;
float playerPositionY;
float playerPositionZ;
float shadowIntensity;
float nudgeIntensity;

#pragma body
float3 playerPos = float3(playerPositionX, playerPositionY, playerPositionZ);
float3 toFrag = _surface.position - playerPos;

// Shadow strength: distance falloff × floor alignment
float dist = length(float2(toFrag.x, toFrag.z));
float falloff = 1.0 / (1.0 + dist * 0.1);
float alignment = max(0.0, -dot(_surface.normal, float3(0, 1, 0)));

float shadow = falloff * alignment * shadowIntensity;
_output.color.rgb *= (1.0 - shadow * 0.6);

// Nudge: intensify shadow reveal
_output.color.rgb *= (1.0 - nudgeIntensity * shadow * 0.3);
