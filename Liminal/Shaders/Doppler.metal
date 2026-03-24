// Doppler.metal — SCNShaderModifierEntryPointFragment
// Color temperature shift via velocity uniform (blueshift at speed).

#pragma arguments
float velocityNormalized;
float colorShiftAmount;
float transitionSpeed;
float nudgeIntensity;

#pragma body
float shift = velocityNormalized * colorShiftAmount;
_output.color.r = max(0.0, _output.color.r - shift * 0.35);
_output.color.g = max(0.0, _output.color.g - shift * 0.12);
_output.color.b = min(1.0, _output.color.b + shift * 0.55);

// Nudge: warm amplitude flare
_output.color.rgb = mix(_output.color.rgb, float3(1.0, 0.8, 0.5), nudgeIntensity * 0.3);
