// Lensing.metal — SCNShaderModifierEntryPointFragment
// UV coordinate distortion via proximity to hidden mass point.
// Procedural grid pattern warps visually as player approaches.

#pragma arguments
float proximityNormalized;
float distortionAmount;
float nudgeIntensity;

#pragma body
float2 uv = _surface.diffuseTexcoord;
float2 center = float2(0.5, 0.5);
float2 toCenter = center - uv;
float dist = length(toCenter);
float2 warpedUV = uv + normalize(toCenter) * distortionAmount * smoothstep(0.0, 0.5, dist);

// Procedural grid on warped UVs
float gridX = smoothstep(0.48, 0.5, fract(warpedUV.x * 20.0));
float gridY = smoothstep(0.48, 0.5, fract(warpedUV.y * 20.0));
float grid = max(gridX, gridY) * 0.15;

// Tint toward deep blue-green based on proximity
float3 baseTint = float3(0.6, 0.65, 0.7);
float3 proxTint = float3(0.2, 0.5, 0.8);
float3 tint = mix(baseTint, proxTint, proximityNormalized);

_output.color.rgb = _output.color.rgb * tint + grid;

// Nudge: color pulse
_output.color.rgb = mix(_output.color.rgb, float3(0.5, 0.8, 1.0), nudgeIntensity * 0.3);
