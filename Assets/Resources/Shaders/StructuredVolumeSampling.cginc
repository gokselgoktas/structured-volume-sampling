#ifndef __SVS__
#define __SVS__

#include "UnityCG.cginc"

struct Input
{
    float4 vertex : POSITION;

    float3 a : TEXCOORD0;
    float3 b : TEXCOORD1;
    float3 c : TEXCOORD2;

    float3 weights : COLOR;
};

struct Varyings
{
    float4 vertex : SV_POSITION;
    float4 uv : TEXCOORD0;

    float3 a : TEXCOORD1;
    float3 b : TEXCOORD2;
    float3 c : TEXCOORD3;

    float3 weights : COLOR;
};

sampler2D _LookupTexture;

float4x4 _ViewMatrix;
float4x4 _ProjectionMatrix;

int _MaximumIterationCount;

float _Range;

float3 decode(in float2 uv)
{
    float2 k = 4. * uv - 2;
    float magnitude = dot(k, k);

    return float3(k * sqrt(1. - magnitude * .25), 1. - magnitude * .5);
}

Varyings vertex(Input input)
{
    Varyings output;

    float4 vertex = float4(_Range * input.vertex.xyz, input.vertex.w);
    vertex.xyz += _WorldSpaceCameraPos;
    vertex = UnityObjectToClipPos(vertex.xyz);

    output.vertex = vertex;
    output.uv = ComputeScreenPos(vertex);

    output.a = input.a;
    output.b = input.b;
    output.c = input.c;

    output.weights = input.weights;

    return output;
}

float generateValueNoise(in float4 seed)
{
    float4 integer = floor(seed);
    float4 fractional = frac(seed);

    fractional = 1. - fractional * fractional;
    fractional = 1. - fractional * fractional;

    float2 uv = (integer.xy + integer.z * float2(37., 17.) + integer.w * float2(59., 83.)) + fractional.xy;

    float4 rgba = tex2Dlod(_LookupTexture, float4((uv + .5) * .00390625, 0., 0.));
    return lerp(lerp(rgba.x, rgba.y, fractional.z), lerp(rgba.z, rgba.w, fractional.z), fractional.w);
}

float generateFractalNoise(in float4 seed)
{
    float result = .5 * generateValueNoise(seed);
    seed *= 2.01;

    result += .25 * generateValueNoise(seed);
    seed *= 2.02;

    result += .125 * generateValueNoise(seed);
    seed *= 2.03;

    return result + .0625 * generateValueNoise(seed);
}

float query(in float3 position)
{
    float plane = .5 - position.y;
    plane += 3. * generateFractalNoise(float4(position * .25, 2. * _Time.x));

    return saturate(plane);
}

float getDensity(in float3 position)
{
    return .1 * query(position);
}

float3 getDirection(float2 uv)
{
    return normalize(float3(
        _ViewMatrix[0].xyz * uv.x +
        _ViewMatrix[1].xyz * uv.y -
        _ViewMatrix[2].xyz * abs(_ProjectionMatrix[1][1])));
}

float4 fragment(in Varyings input) : SV_Target
{
    float2 uv = input.uv.xy / input.uv.w;

    float2 coordinates = 2. * uv - 1.;
    coordinates.y *= _ScreenParams.y / _ScreenParams.x;

    float3 origin = _WorldSpaceCameraPos;
    float3 direction = getDirection(coordinates);

    float3 density = 0.;

    float3 offset = float3(rcp(dot(direction, input.a)), 0., 0.);
    float3 delta = float3(abs(offset.x), 0., 0.);

    offset.x *= -fmod(dot(origin, input.a), 1.);

#if SVS_RAY_COUNT > 1
    offset.y = rcp(dot(direction, input.b));

    delta.y = abs(offset.y);
    offset.y *= -fmod(dot(origin, input.b), 1.);
#endif

#if SVS_RAY_COUNT > 2
    offset.z = rcp(dot(direction, input.c));

    delta.z = abs(offset.z);
    offset.z *= -fmod(dot(origin, input.c), 1.);
#endif

#if SVS_RAY_COUNT == 1
    offset.x += step(offset.x, 0.) * delta.x;

    float3 fade = float3(offset.x / delta.x, 0., 0.);
#elif SVS_RAY_COUNT == 2
    offset.xy += step(offset.xy, 0.) * delta.xy;

    float3 fade = float3(offset.xy / delta.xy, 0.);
#else
    offset += step(offset, 0.) * delta;

    float3 fade = offset / delta;
#endif

    density.x += step(density.x, .99) * fade.x * delta.x * getDensity(origin + offset.x * direction) * (1. - density.x);

#if SVS_RAY_COUNT > 1
    density.y += step(density.y, .99) * fade.y * delta.y * getDensity(origin + offset.y * direction) * (1. - density.y);
#endif

#if SVS_RAY_COUNT > 2
    density.z += step(density.z, .99) * fade.z * delta.z * getDensity(origin + offset.z * direction) * (1. - density.z);
#endif

    offset += delta;

    for (int i = 1; i < _MaximumIterationCount - 1; ++i)
    {
        density.x += step(density.x, .99) * delta.x * getDensity(origin + offset.x * direction) * (1. - density.x);

#if SVS_RAY_COUNT > 1
        density.y += step(density.y, .99) * delta.y * getDensity(origin + offset.y * direction) * (1. - density.y);
#endif

#if SVS_RAY_COUNT > 2
        density.z += step(density.z, .99) * delta.z * getDensity(origin + offset.z * direction) * (1. - density.z);
#endif

        offset += delta;
    }

    fade = 1. - fade;

    density.x += step(density.x, .99) * fade.x * delta.x * getDensity(origin + offset.x * direction) * (1. - density.x);

#if SVS_RAY_COUNT > 1
    density.y += step(density.y, .99) * fade.y * delta.y * getDensity(origin + offset.y * direction) * (1. - density.y);
#endif

#if SVS_RAY_COUNT > 2
    density.z += step(density.z, .99) * fade.z * delta.z * getDensity(origin + offset.z * direction) * (1. - density.z);
#endif

    density.x *= input.weights.x;

#if SVS_RAY_COUNT > 1
    density.x += input.weights.y * density.y;
#endif

#if SVS_RAY_COUNT > 2
    density.x += input.weights.z * density.z;
#endif

    return saturate(density.x);
}

#endif
