Shader "Universal Render Pipeline/Post Effect/DepthBlur"
{
    Properties
    {
        _MainTex("Base (RGB)", 2D) = "white" {}
        _FocusDis("Focus Distance", Float) = 10.0
        _FocusRange("Focus Range", Float) = 5.0
        _RadiusSparse("Radius Sparse", Float) = 1.0
        _SimpleBlurRange("Simple Blur Range", Float) = 1.0
        _CocEdge("Coc Edge", Range(0, 1)) = 0.1
        _ForegroundScale("Foreground Blur Scale", Range(0, 1)) = 1.0
    }

    SubShader
    {
        Tags { "RenderType"="Opaque" "RenderPipeline" = "UniversalPipeline"  }
        LOD 100

        HLSLINCLUDE

        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareDepthTexture.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Common.hlsl"

        

        TEXTURE2D(_MainTex); SAMPLER(sampler_MainTex);
        // sampler2D _MainTex;
        float4 _MainTex_ST;
        // sampler2D _CameraDepthTexture;
        float _FocusDis;
        float _FocusRange;
        TEXTURE2D(_CocTex); SAMPLER(sampler_CocTex);
        TEXTURE2D(_BlurTex); SAMPLER(sampler_BlurTex);
        // sampler2D _CocTex;
        // sampler2D _BlurTex;
        float _RadiusSparse;
        float _SimpleBlurRange;
        float _CocEdge;
        float _ForegroundScale;

        //static const int kernelCount = 17;
        //static const float2 kernel[kernelCount] = {
        //    float2(0, 0),
        //    float2(0.5, 0), float2(-0.5, 0), float2(0.25, 0.433), float2(0.25, -0.433), float2(-0.25, 0.433), float2(-0.25, -0.433),
        //    float2(1, 0), float2(-1, -0), float2(0.809, 0.588), float2(0.309, 0.951), float2(-0.309, 0.951), float2(-0.809, 0.588),
        //    float2(-0.809, -0.588), float2(-0.309, -0.951), float2(0.309, -0.951), float2(0.809, -0.588),
        //};

        static const int kernelCount = 15;
        static const float2 kernel[kernelCount] = {
            float2(0.54545456, 0),
            float2(0.16855472, 0.5187581),
            float2(-0.44128203, 0.3206101),
            float2(-0.44128197, -0.3206102),
            float2(0.1685548, -0.5187581),
            float2(1, 0),
            float2(0.809017, 0.58778524),
            float2(0.30901697, 0.95105654),
            float2(-0.30901703, 0.9510565),
            float2(-0.80901706, 0.5877852),
            float2(-1, 0),
            float2(-0.80901694, -0.58778536),
            float2(-0.30901664, -0.9510566),
            float2(0.30901712, -0.9510565),
            float2(0.80901694, -0.5877853),
        };

        struct appdata_img {
            float4 vertex: POSITION;
            float2 texcoord : TEXCOORD0;
        };

        struct v2f
        {
            float2 uv : TEXCOORD0;
            float2 uv_depth : TEXCOORD1;
            float4 vertex : SV_POSITION;
        };

        v2f vert(appdata_img v)
        {
            v2f o;
            o.vertex = TransformObjectToHClip(v.vertex.xyz);
            o.uv = v.texcoord;
            o.uv_depth = v.texcoord;
#if UNITY_UV_STARTS_AT_TOP
            if (_MainTex_ST.y < 0)
                o.uv_depth.y = 1 - o.uv_depth.y;
#endif
            return o;
        }

        half4 fragCoc(v2f i) : SV_Target
        {
            // float depth = LinearEyeDepth(tex2D(_CameraDepthTexture, i.uv).r);
            float depth = LinearEyeDepth(SampleSceneDepth(i.uv_depth), _ZBufferParams);
            float coc = (depth - _FocusDis) / _FocusRange;
            coc = clamp(coc, -1, 1) * 0.5f + 0.5f;

            //half4 col = tex2D(_MainTex, i.uv);
            return half4(coc, 0, 0, 1);
        }

        half4 fragSampleDisk(v2f i) : SV_Target
        {
            half3 fcol = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv).rgb;
            half3 bcol = fcol;
            float fw = 1.0f, bw = 1.0f;

            //float coc = 2 * tex2D(_CocTex, i.uv).r - 1.0f;
            //float weight = saturate((abs(coc) - _CocEdge) / (1 - _CocEdge));
            //float4 ori = tex2D(_MainTex, i.uv);
            //// weight *= weight;
            //if (weight < 0.001f)
            //{
            //    return ori;
            //}

            for (int k = 0; k < kernelCount; k++)
            {
                float2 uvOffset = kernel[k] * _RadiusSparse * _MainTex_ST.xy * 0.001f;
                half3 col = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv + uvOffset).rgb;
                
                float coc = 2 * SAMPLE_TEXTURE2D(_CocTex, sampler_CocTex, i.uv).r - 1.0f;
                float radius = length(uvOffset);
                float w = saturate((abs(coc) - _CocEdge) / (1 - _CocEdge)) * (1 + radius);
                
                fcol += col * w * step(coc, 0);
                fw += w * step(coc, 0);

                bcol += col * w * step(-coc, 0);
                bw += w * step(0, coc);
            }

            bcol /= bw;
            fcol /= fw;

            // return half4(lerp(bcol, fcol, fb), fb);

            float fb = _ForegroundScale * fw / (fw + bw);

            return half4(lerp(bcol, fcol, fb), fb);

        }

        half4 fragSimpleBlur(v2f i) : SV_Target
        {
            // [1, 2, 1]
            // [2, 4, 2]
            // [1, 2, 1]
            half4 col = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv) * 0.25f;
            float4 off = _MainTex_ST.xyxy * float2(-0.5, 0.5).xxyy * 0.001f * _SimpleBlurRange;
            col += 0.125f * (SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv + float2(0, off.y)) 
                + SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv + float2(0, off.w))
                + SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv + float2(off.x, 0))
                + SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv + float2(off.z, 0)));
            col += 0.0625f * (SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv + off.zy)
                + SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv + off.zy)
                + SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv + off.xw)
                + SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv + off.zw));
            return col;
        }

        half4 fragFinal(v2f i) : SV_Target
        {
            half4 src = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv);
            half coc = SAMPLE_TEXTURE2D(_CocTex, sampler_CocTex, i.uv).r;
            half4 blur = SAMPLE_TEXTURE2D(_BlurTex, sampler_BlurTex, i.uv);

            half fg = blur.a;
            coc = smoothstep(_CocEdge, 1, abs(2 * coc - 1.0f));
            // coc = abs(2 * coc - 1.0f);
            half3 color = lerp(src.rgb, blur.rgb, coc + fg - coc * fg);
            return half4(color, src.a);
        }
        ENDHLSL

        Pass
        {
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment fragCoc
            
            ENDHLSL
        }

        Pass
        {
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment fragSampleDisk

            ENDHLSL
        }

        Pass
        {
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment fragSimpleBlur

            ENDHLSL
        }

        Pass
        {
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment fragFinal

            ENDHLSL
        }
    }
}
