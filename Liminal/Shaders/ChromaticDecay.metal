// ChromaticDecay.metal — SCNShaderModifierEntryPointFragment
// Desaturation driven by idle time. Converts to luminance via Rec. 709 weights.

#pragma arguments
float desaturation;
float nudgeIntensity;

#pragma body
float luminance = dot(_output.color.rgb, float3(0.2126, 0.7152, 0.0722));
float3 grayscale = float3(luminance);

_output.color.rgb = mix(_output.color.rgb, grayscale, desaturation);

// Nudge: warm color pulse to hint at movement
_output.color.rgb = mix(_output.color.rgb, float3(1.0, 0.85, 0.6), nudgeIntensity * 0.25);
