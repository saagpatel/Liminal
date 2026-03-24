// ChromaticDecayTest.metal — SCNShaderModifierEntryPointFragment
// Test shader: desaturation cycling driven by time uniform.

#pragma arguments
float time;

#pragma body
float desaturation = sin(time * 0.4) * 0.5 + 0.5;

float luminance = dot(_output.color.rgb, float3(0.2126, 0.7152, 0.0722));
float3 grayscale = float3(luminance);

_output.color.rgb = mix(_output.color.rgb, grayscale, desaturation);
