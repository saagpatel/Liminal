// ResonanceTest.metal — SCNShaderModifierEntryPointFragment
// Test shader: resonance color tint cycling with time.

#pragma arguments
float time;

#pragma body
float resonance = sin(time * 0.5) * 0.5 + 0.5;

float3 neutralColor = float3(0.5, 0.55, 0.6);
float3 resonantColor = float3(1.0, 0.6, 0.2);
_output.color.rgb = mix(_output.color.rgb * neutralColor, resonantColor, resonance * 0.7);
