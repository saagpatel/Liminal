// ResonanceGeometryTest.metal — SCNShaderModifierEntryPointGeometry
// Test shader: vertex displacement along normals for vibration effect.
// This is the first geometry/vertex shader modifier in the project.

#pragma arguments
float time;

#pragma body
float amplitude = sin(time * 0.5) * 0.15 + 0.15;
float frequency = 12.0;
float spatialPhase = dot(_geometry.position.xyz, float3(1.0, 0.7, 1.0)) * frequency;
float displacement = sin(spatialPhase + time * frequency * 2.0) * amplitude;
_geometry.position.xyz += _geometry.normal * displacement;
