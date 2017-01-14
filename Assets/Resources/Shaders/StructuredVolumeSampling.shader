
Shader "Hidden/Structured Volume Sampling"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
    }

    SubShader
    {
        Cull Off ZWrite Off ZTest Always

        Pass
        {
            CGPROGRAM
            #pragma target 5.0
            #define SVS_RAY_COUNT 1
            #pragma vertex vertex
            #pragma fragment fragment

            #include "StructuredVolumeSampling.cginc"
            ENDCG
        }

        Pass
        {
            CGPROGRAM
            #pragma target 5.0
            #define SVS_RAY_COUNT 2
            #pragma vertex vertex
            #pragma fragment fragment

            #include "StructuredVolumeSampling.cginc"
            ENDCG
        }

        Pass
        {
            CGPROGRAM
            #pragma target 5.0
            #define SVS_RAY_COUNT 3
            #pragma vertex vertex
            #pragma fragment fragment

            #include "StructuredVolumeSampling.cginc"
            ENDCG
        }
    }
}
