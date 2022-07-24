#ifndef Structures_h
#define Structures_h

struct Uniforms {
    float3 col;
    float2 window_size;
    float time;
    float rotation;
};

struct vertex_in {
    packed_float3 _vertex;
};

struct vertex_out {
    float4 fragp [[position]];
    float4 col;
    float2 uv;
    float time;
};

#endif /* Structures_h */