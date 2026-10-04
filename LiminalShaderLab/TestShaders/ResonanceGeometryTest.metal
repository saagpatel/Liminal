// ResonanceGeometryTest.metal — SCNShaderModifierEntryPointGeometry
// Test shader: vertex displacement along normals for vibration effect.
// This is the first geometry/vertex shader modifier in the project.

#pragma arguments
float time;

#pragma body
float amplitude = sin(time * 0.5) * 0.15 + 0.15;
float frequency = 12.0;
float spatialPhase = dot(_geometry.position.xyz, float3(1.0, 0.7, 1.0)) * frequency;
float phase = spatialPhase + time * frequency * 2.0;
float displacement = sin(phase) * amplitude;
float3 baseNormal = normalize(_geometry.normal);
_geometry.position.xyz += _geometry.normal * displacement;

// First-order model-space normal for the displaced surface, so lighting shows the ripples.
float3 gradient = cos(phase) * amplitude * frequency * float3(1.0, 0.7, 1.0);
float3 tangentGradient = gradient - baseNormal * dot(gradient, baseNormal);
_geometry.normal = normalize(baseNormal - tangentGradient);
