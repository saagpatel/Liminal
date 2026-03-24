// DopplerTest.metal — SCNShaderModifierEntryPointFragment
// Test shader: cycles cube color warm→cool based on sin(time).
// Validates that uniform passing and fragment modification work end-to-end.

#pragma arguments
float time;

#pragma body
float t = sin(time * 3.14159) * 0.5 + 0.5;
float3 warm = float3(1.0, 0.3, 0.1);
float3 cool = float3(0.1, 0.3, 1.0);
_output.color.rgb = mix(warm, cool, t);
