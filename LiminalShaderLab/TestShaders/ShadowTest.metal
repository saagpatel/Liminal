// ShadowTest.metal — SCNShaderModifierEntryPointFragment
// Test shader: faux player-relative shadow, animated by time uniform.

#pragma arguments
float time;

#pragma body
float3 playerPos = float3(sin(time * 0.7) * 3.0, 1.7, cos(time * 0.5) * 3.0);
float shadowIntensity = 0.7;

float3 toFrag = _surface.position - playerPos;
float dist = length(float2(toFrag.x, toFrag.z));
float falloff = 1.0 / (1.0 + dist * 0.1);
float alignment = max(0.0, -dot(_surface.normal, float3(0, 1, 0)));

float shadow = falloff * alignment * shadowIntensity;
_output.color.rgb *= (1.0 - shadow * 0.6);
