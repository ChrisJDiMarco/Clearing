#include <metal_stdlib>
#include <RealityKit/RealityKit.h>

using namespace metal;

// A controlled approximation of crystal optics: clear faces let the inner
// amber mesh show through, while grazing faces catch icy reflections.
[[visible]] void clearingCrystalSurface(realitykit::surface_parameters params) {
    const float4 controls = params.uniforms().custom_parameter();
    const float progress = clamp(controls.x, 0.0, 1.0);
    const bool isCore = controls.y > 0.5;
    const bool support = controls.z > 0.5;
    const float3 normal = normalize(params.geometry().normal());
    const float3 view = normalize(params.geometry().view_direction());
    const float3 position = params.geometry().model_position();
    const float fresnel = pow(1.0 - abs(dot(normal, view)), 2.4);
    const float key = clamp(dot(normal, normalize(float3(-0.72, 0.45, 0.52))) * 0.5 + 0.5, 0.0, 1.0);
    const float facet = pow(key, 2.0);
    const float iceTravel = smoothstep(-0.64, 0.80, normal.x + position.y * 1.2 + progress * 0.25);
    const float3 amber = float3(0.43, 0.20, 0.06);
    const float3 ice = support ? float3(0.58, 0.72, 0.88) : float3(0.55, 0.67, 0.69);
    float3 color = isCore
        ? mix(float3(0.86, 0.37, 0.075), float3(1.0, 0.62, 0.23), progress)
        : mix(amber, ice, iceTravel);
    if (!isCore) color *= mix(0.66, 1.35, facet);

    params.surface().set_base_color(half3(color));
    params.surface().set_roughness(isCore ? 0.11 : 0.025);
    params.surface().set_metallic(0.0);
    params.surface().set_specular(1.0);
    params.surface().set_clearcoat(isCore ? 0.35 : 1.0);
    params.surface().set_clearcoat_roughness(0.02);
    const float glow = 1.0 - smoothstep(-0.10, 0.07, position.y);
    params.surface().set_emissive_color(half3(isCore
        ? color * (0.16 + glow * 0.54)
        : float3(0.55, 0.35, 0.15) * glow * 0.04));
    params.surface().set_opacity(isCore ? 0.67 : mix(0.42, 0.90, fresnel));
}
