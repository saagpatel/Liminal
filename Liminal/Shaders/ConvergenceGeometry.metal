// ConvergenceGeometry.metal — SCNShaderModifierEntryPointGeometry
// Subtle vertex vibration from resonance component.

#pragma arguments
float vibrationAmplitude;
float vibrationFrequency;

#pragma body
float spatialPhase = dot(_geometry.position.xyz, float3(1.0, 0.7, 1.0)) * vibrationFrequency;
float displacement = sin(spatialPhase + scn_frame.time * vibrationFrequency * 2.0) * vibrationAmplitude;
_geometry.position.xyz += _geometry.normal * displacement;
