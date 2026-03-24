// ConvergenceTest.metal — SCNShaderModifierEntryPointFragment
// Test shader: cycles through all 6 visual effects blended.

#pragma arguments
float time;

#pragma body
float t = time * 0.3;

// Doppler blueshift cycle
float shift = sin(t) * 0.08;
_output.color.r = max(0.0, _output.color.r - shift * 0.35);
_output.color.b = min(1.0, _output.color.b + shift * 0.55);

// Lensing grid (subtle)
float2 uv = _surface.diffuseTexcoord;
float gridX = smoothstep(0.48, 0.5, fract(uv.x * 20.0));
float gridY = smoothstep(0.48, 0.5, fract(uv.y * 20.0));
_output.color.rgb += max(gridX, gridY) * 0.05;

// Desaturation cycle
float desat = sin(t * 1.3) * 0.1 + 0.1;
float lum = dot(_output.color.rgb, float3(0.2126, 0.7152, 0.0722));
_output.color.rgb = mix(_output.color.rgb, float3(lum), desat);

// Resonance tint cycle
float res = sin(t * 0.7) * 0.1 + 0.1;
_output.color.rgb = mix(_output.color.rgb, float3(1.0, 0.6, 0.2), res);
