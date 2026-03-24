// Interference.metal — SCNShaderModifierEntryPointFragment
// Wave interference pattern from two audio source positions.
// Visualizes constructive/destructive interference on lattice geometry.

#pragma arguments
float cancellationFactor;
float sourceAX;
float sourceAY;
float sourceAZ;
float sourceBX;
float sourceBY;
float sourceBZ;
float waveFrequency;
float playerPositionX;
float playerPositionZ;
float nudgeIntensity;

#pragma body
float3 srcA = float3(sourceAX, sourceAY, sourceAZ);
float3 srcB = float3(sourceBX, sourceBY, sourceBZ);
float3 fragPos = _surface.position;

float distA = length(fragPos - srcA);
float distB = length(fragPos - srcB);

float waveA = sin(distA * waveFrequency) * 0.5 + 0.5;
float waveB = sin(distB * waveFrequency) * 0.5 + 0.5;
float interference = (waveA + waveB) * 0.5;

float3 baseColor = float3(0.15, 0.35, 0.45);
float3 waveColor = float3(0.3, 0.7, 0.9);

_output.color.rgb = mix(baseColor, waveColor, interference * 0.6);
_output.color.rgb *= (1.0 - cancellationFactor * 0.7);

// Nudge: flash interference pattern
_output.color.rgb = mix(_output.color.rgb, float3(0.6, 0.9, 1.0), nudgeIntensity * 0.3);
