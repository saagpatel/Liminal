// Convergence.metal — SCNShaderModifierEntryPointFragment
// All 6 prior shader effects blended at low intensity.

#pragma arguments
// Doppler
float velocityNormalized;
float colorShiftAmount;
// Lensing
float proximityNormalized;
float distortionAmount;
// Shadow
float playerPositionX;
float playerPositionY;
float playerPositionZ;
float shadowIntensity;
// Interference
float cancellationFactor;
float sourceAX; float sourceAY; float sourceAZ;
float sourceBX; float sourceBY; float sourceBZ;
float waveFrequency;
// ChromaticDecay
float desaturation;
// Resonance
float resonance;
// Nudge
float nudgeIntensity;

#pragma body
// 1. Doppler blueshift
float shift = velocityNormalized * colorShiftAmount;
_output.color.r = max(0.0, _output.color.r - shift * 0.35);
_output.color.g = max(0.0, _output.color.g - shift * 0.12);
_output.color.b = min(1.0, _output.color.b + shift * 0.55);

// 2. Lensing UV warp (subtle grid)
float2 uv = _surface.diffuseTexcoord;
float2 center = float2(0.5, 0.5);
float2 toCenter = center - uv;
float dist = length(toCenter);
float2 warpedUV = uv + normalize(toCenter) * distortionAmount * smoothstep(0.0, 0.5, dist);
float gridX = smoothstep(0.48, 0.5, fract(warpedUV.x * 20.0));
float gridY = smoothstep(0.48, 0.5, fract(warpedUV.y * 20.0));
float grid = max(gridX, gridY) * 0.08;
_output.color.rgb += grid;

// 3. Shadow darkening
float3 playerPos = float3(playerPositionX, playerPositionY, playerPositionZ);
float3 toFrag = _surface.position - playerPos;
float shadowDist = length(float2(toFrag.x, toFrag.z));
float falloff = 1.0 / (1.0 + shadowDist * 0.1);
float alignment = max(0.0, -dot(_surface.normal, float3(0, 1, 0)));
float shadow = falloff * alignment * shadowIntensity;
_output.color.rgb *= (1.0 - shadow * 0.3);

// 4. Interference wave pattern
float3 srcA = float3(sourceAX, sourceAY, sourceAZ);
float3 srcB = float3(sourceBX, sourceBY, sourceBZ);
float distA = length(_surface.position - srcA);
float distB = length(_surface.position - srcB);
float waveA = sin(distA * waveFrequency) * 0.5 + 0.5;
float waveB = sin(distB * waveFrequency) * 0.5 + 0.5;
float interference = (waveA + waveB) * 0.5;
_output.color.rgb = mix(_output.color.rgb, float3(0.3, 0.7, 0.9), interference * cancellationFactor * 0.15);

// 5. Chromatic decay (desaturation)
float luminance = dot(_output.color.rgb, float3(0.2126, 0.7152, 0.0722));
_output.color.rgb = mix(_output.color.rgb, float3(luminance), desaturation);

// 6. Resonance tint
float3 resonantColor = float3(1.0, 0.6, 0.2);
_output.color.rgb = mix(_output.color.rgb, resonantColor, resonance * 0.15);

// Nudge
_output.color.rgb = mix(_output.color.rgb, float3(0.8, 0.8, 1.0), nudgeIntensity * 0.2);
