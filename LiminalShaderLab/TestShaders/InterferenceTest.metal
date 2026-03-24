// InterferenceTest.metal — SCNShaderModifierEntryPointFragment
// Test shader: wave interference pattern from two animated source positions.

#pragma arguments
float time;

#pragma body
float3 srcA = float3(-3.0, 0.0, 0.0);
float3 srcB = float3(3.0, 0.0, 0.0);
float waveFreq = 8.0;
float3 fragPos = _surface.position;

float distA = length(fragPos - srcA);
float distB = length(fragPos - srcB);

float waveA = sin(distA * waveFreq + time * 2.0) * 0.5 + 0.5;
float waveB = sin(distB * waveFreq + time * 2.0) * 0.5 + 0.5;
float interference = (waveA + waveB) * 0.5;

// Cancellation factor cycles with time for demo
float cancellation = sin(time * 0.3) * 0.5 + 0.5;

float3 baseColor = float3(0.15, 0.35, 0.45);
float3 waveColor = float3(0.3, 0.7, 0.9);
_output.color.rgb = mix(baseColor, waveColor, interference * 0.6);
_output.color.rgb *= (1.0 - cancellation * 0.7);
