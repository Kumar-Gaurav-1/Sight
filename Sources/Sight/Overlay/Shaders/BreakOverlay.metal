#include <metal_stdlib>
using namespace metal;

// MARK: - Vertex Data

struct VertexIn {
    float2 position [[attribute(0)]];
    float2 texCoord [[attribute(1)]];
};

struct VertexOut {
    float4 position [[position]];
    float2 texCoord;
};

// MARK: - Uniforms

struct Uniforms {
    float time;           // Animation time in seconds
    float blurRadius;     // Blur intensity (0-1)
    float vignetteRadius; // Vignette inner radius (0-1)
    float vignetteSoft;   // Vignette softness
    float breathePhase;   // Breathing animation phase (0-2π)
    float breatheScale;   // Breathing scale factor
    float2 resolution;    // Screen resolution
    float2 center;        // Breathing center point (normalized)
};

// MARK: - Vertex Shader

vertex VertexOut vertexShader(VertexIn in [[stage_in]]) {
    VertexOut out;
    out.position = float4(in.position, 0.0, 1.0);
    out.texCoord = in.texCoord;
    return out;
}

// MARK: - Radial Blur

// Soft radial blur using weighted box samples
// Optimized for performance with configurable sample count
float4 radialBlur(texture2d<float> texture,
                  sampler texSampler,
                  float2 uv,
                  float2 center,
                  float radius,
                  int samples) {
    float4 color = float4(0.0);
    float totalWeight = 0.0;
    
    // Direction from center
    float2 dir = uv - center;
    float dist = length(dir);
    
    // Blur intensity increases with distance from center
    float blurAmount = radius * smoothstep(0.0, 0.5, dist);
    
    for (int i = 0; i < samples; i++) {
        float t = float(i) / float(samples - 1);
        float2 offset = dir * blurAmount * (t - 0.5) * 0.1;
        
        // Gaussian-like weight
        float weight = exp(-4.0 * (t - 0.5) * (t - 0.5));
        color += texture.sample(texSampler, uv + offset) * weight;
        totalWeight += weight;
    }
    
    return color / totalWeight;
}

// MARK: - Vignette Effect

float vignette(float2 uv, float radius, float softness) {
    float2 centered = uv - 0.5;
    float dist = length(centered);
    return 1.0 - smoothstep(radius, radius + softness, dist);
}

// MARK: - Breathing Animation

// Creates a pulsing circle effect
float breathingCircle(float2 uv, float2 center, float phase, float scale) {
    float2 centered = uv - center;
    float dist = length(centered);
    
    // Breathing radius oscillates
    float radius = 0.15 + 0.05 * sin(phase) * scale;
    float softness = 0.1 + 0.02 * sin(phase * 0.5);
    
    // Soft circle
    float circle = 1.0 - smoothstep(radius - softness, radius + softness, dist);
    
    // Add subtle glow
    float glow = exp(-dist * 3.0) * 0.3 * (1.0 + 0.2 * sin(phase));
    
    return circle + glow;
}

// MARK: - Fragment Shader

fragment float4 fragmentShader(VertexOut in [[stage_in]],
                               texture2d<float> screenTexture [[texture(0)]],
                               constant Uniforms& uniforms [[buffer(0)]]) {
    
    constexpr sampler texSampler(mag_filter::linear,
                                  min_filter::linear,
                                  address::clamp_to_edge);
    
    float2 uv = in.texCoord;
    
    // Sample count based on quality (can be adjusted via uniforms)
    int sampleCount = 9; // Good balance of quality and performance
    
    // Apply radial blur
    float4 blurred = radialBlur(screenTexture,
                                 texSampler,
                                 uv,
                                 float2(0.5, 0.5),
                                 uniforms.blurRadius,
                                 sampleCount);
    
    // Apply vignette
    float vig = vignette(uv, uniforms.vignetteRadius, uniforms.vignetteSoft);
    
    // Darken edges
    float4 color = blurred * (0.3 + 0.7 * vig);
    
    // Add a subtle blue tint for calm effect
    color.rgb = mix(color.rgb, float3(0.1, 0.15, 0.25), 0.15 * (1.0 - vig));
    
    // Breathing circle overlay
    float breath = breathingCircle(uv,
                                    uniforms.center,
                                    uniforms.breathePhase,
                                    uniforms.breatheScale);
    
    // Add breathing glow
    float3 breathColor = float3(0.4, 0.6, 0.8); // Calm blue
    color.rgb = mix(color.rgb, breathColor, breath * 0.4);
    
    // Ensure alpha is set for overlay
    color.a = 0.95;
    
    return color;
}

// MARK: - Simple Passthrough (for low-power mode)

fragment float4 passthroughFragment(VertexOut in [[stage_in]],
                                     texture2d<float> texture [[texture(0)]],
                                     constant Uniforms& uniforms [[buffer(0)]]) {
    constexpr sampler texSampler(mag_filter::linear, min_filter::linear);
    
    float4 color = texture.sample(texSampler, in.texCoord);
    
    // Simple vignette only
    float vig = vignette(in.texCoord, uniforms.vignetteRadius, uniforms.vignetteSoft);
    color.rgb *= (0.4 + 0.6 * vig);
    color.a = 0.9;
    
    return color;
}
