// Resonance.metal — SCNShaderModifierEntryPointFragment
// Color tint based on resonance proximity. Warms at resonance, neutral off-resonance.

#pragma arguments
float resonance;
float nudgeIntensity;

#pragma body
float3 neutralColor = float3(0.5, 0.55, 0.6);
float3 resonantColor = float3(1.0, 0.6, 0.2);
_output.color.rgb = mix(_output.color.rgb * neutralColor, resonantColor, resonance * 0.7);

// Nudge: resonance pulse hint
_output.color.rgb = mix(_output.color.rgb, float3(0.9, 0.5, 0.2), nudgeIntensity * 0.3);
