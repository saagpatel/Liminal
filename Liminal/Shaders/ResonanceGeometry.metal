// ResonanceGeometry.metal — SCNShaderModifierEntryPointGeometry
// Vertex displacement along normals for vibration effect.
// First geometry/vertex shader modifier in the project.

#pragma arguments
float vibrationAmplitude;
float vibrationFrequency;

#pragma body
float spatialPhase = dot(_geometry.position.xyz, float3(1.0, 0.7, 1.0)) * vibrationFrequency;
float phase = spatialPhase + scn_frame.time * vibrationFrequency * 2.0;
float displacement = sin(phase) * vibrationAmplitude;
float3 baseNormal = normalize(_geometry.normal);
_geometry.position.xyz += _geometry.normal * displacement;

// First-order model-space normal for the displaced surface, so lighting shows the ripples.
float3 gradient = cos(phase) * vibrationAmplitude * vibrationFrequency * float3(1.0, 0.7, 1.0);
float3 tangentGradient = gradient - baseNormal * dot(gradient, baseNormal);
_geometry.normal = normalize(baseNormal - tangentGradient);
