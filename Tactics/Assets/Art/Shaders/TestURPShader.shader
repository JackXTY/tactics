Shader "Universal Render Pipeline/TestURPShader"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _HorizonThreshold("Horizon Threshold", Range(0, 1)) = 0.02
        _OffsetHorizon("Offset Horizon", Range(-1, 1)) = 0
        _GroundColor("Ground Color", Color) = (94, 89, 87, 128)
        _TimeRatio("Time Ratio", Range(0, 1)) = 0.5
        [HideInInspector] _SunDirection("Sun Direction", Vector) = (0, 1, 0, 0)

        [Space]

        [Header(Scattering)]
        [Space]
        _SkyTint("Sky Tint", Color) = (128, 128, 128, 128)
        _AtmosphereThickness("Atmosphere Thickness", Range(0, 5)) = 1
        _Exposure("Exposure", Range(0, 8)) = 1.3
        _kSunBrightness("Sun Brightness", Range(0, 50)) = 20
        _kMoonBrightness("Moon Brightness", Range(0, 5)) = 1

        [Header(Cloudy)]
        [Space]
        [Toggle(_CLOUDY)]_Cloudy("Cloudy", Float) = 0
        _CloudySunFactor("Cloudy Factor", Range(0, 1)) = 0.75
        _MinCloudyRatio("Min Cloudy Ratio", Range(0, 1)) = 0.3
        _CloudyTopColor("Cloudy Top Color", Color) = (32, 32, 32, 128)
        _CloudyBottomColor("Cloudy Bottom Color", Color) = (64, 64, 64, 128)
            // [Toggle(_TEXTURE_CLOUD_ON)]_TextureCloud_On("Texture Cloud On/Off", Float) = 0
            _CloudTexture("Cloud Texture", 2D) = "black" {}
            _CloudSpeed("Cloud Speed", Range(0, 10)) = 1
            _CloudAlpha("Cloud Alpha", Range(0, 1)) = 0.5


            [Space]

            [Header(Sun Disk)]
            [Space]
            _SunSize("Sun Size", Range(0, 1)) = 0.04
            _SunSizeConvergence("Sun Size Convergence", Range(1, 10)) = 5

            [Space]

            [Header(Moon Disk)]
            [Space]
            _MoonSize("Moon Size", Range(0, 1)) = 0.04
            _MoonSizeConvergence("Moon Size Convergence", Range(1, 10)) = 5
            _MoonColor("Moon Color", Color) = (200, 200, 200, 128)
            _MoonRatio("Moon Ratio", Range(-2, 2)) = 0

            [Space]

            [Header(Night)]
            [Space]
            _StarNoiseTex("Star Noise Texture", 2D) = "black" {}
            _StarIntensity("Star Intensity", Range(0, 1)) = 0.4
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" "Queue" = "Geometry"  "RenderPipeline" = "UniversalPipeline"  }
        LOD 100

        HLSLINCLUDE
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
                #pragma multi_compile_local _ _CLOUDY
        ENDHLSL

        Pass
        {
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            // #pragma multi_compile_fog

            

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                // float fogCoord : TEXCOORD1;
                float4 vertex : SV_POSITION;
            };

            // sampler2D _MainTex;
            TEXTURE2D(_MainTex); SAMPLER(sampler_MainTex);
            float4 _MainTex_ST;

            v2f vert(appdata v)
            {
                v2f o;
                o.vertex = TransformObjectToHClip(v.vertex.xyz);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                // UNITY_TRANSFER_FOG(o,o.vertex);
               //  o.fogCoord = ComputeFogFactor(o.vertex.z);
                return o;
            }

            half4 frag(v2f i) : SV_Target
            {

                half4 col = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv);
                // col = MixFog(color，i.fogCoord);
                return col;
            }
            ENDHLSL
        }
    }
}
