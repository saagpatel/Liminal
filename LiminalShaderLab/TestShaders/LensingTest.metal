// LensingTest.metal — SCNShaderModifierEntryPointFragment
// Test shader: UV warp with procedural grid, animated by time uniform.

#pragma arguments
float time;

#pragma body
float proximityNormalized = sin(time * 0.5) * 0.5 + 0.5;
float distortionAmount = proximityNormalized * 0.15;

float2 uv = _surface.diffuseTexcoord;
float2 center = float2(0.5, 0.5);
float2 toCenter = center - uv;
float dist = length(toCenter);
float2 warpedUV = uv + normalize(toCenter) * distortionAmount * smoothstep(0.0, 0.5, dist);

float gridX = smoothstep(0.48, 0.5, fract(warpedUV.x * 20.0));
float gridY = smoothstep(0.48, 0.5, fract(warpedUV.y * 20.0));
float grid = max(gridX, gridY) * 0.15;

float3 tint = mix(float3(0.6, 0.65, 0.7), float3(0.2, 0.5, 0.8), proximityNormalized);
_output.color.rgb = _output.color.rgb * tint + grid;
