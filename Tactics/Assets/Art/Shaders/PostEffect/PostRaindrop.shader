Shader "Universal Render Pipeline/Post Effect/PostRaindrop"
{
    // Reference from https://zhuanlan.zhihu.com/p/298606553
    Properties
    {
        _MainTex("Base (RGB)", 2D) = "white" {}
        _BlurSize("Blur Size", Float) = 1.0
        _GridNum("Grid Number", Range(1, 50)) = 15
        _Distortion("Distortion", Float) = 10
        _Blur("Blur", Float) = 1
        _RainAmount("Rain Amount", Integer) = 3
        _RainSpeed("Rain Speed", Range(0.2, 3)) = 0.25
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" "RenderPipeline" = "UniversalPipeline"}
        LOD 100

        HLSLINCLUDE

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            struct appdata_img {
                float4 vertex: POSITION;
                float2 texcoord : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
            };

            TEXTURE2D(_MainTex); SAMPLER(sampler_MainTex);
            float4 _MainTex_ST;
            float _GridNum;
            float _Distortion;
            float _Blur;
            int _RainAmount;
            float _RainSpeed;

            static const half uvScale[7] = { 0.87, 1.35, 1.18, 0.92, 1.07, 0.84, 1.23 };
            static const half uvShift[7] = { -0.24, 0.4, 0.12, -0.35, 0.05, -0.09, 0 };


            v2f vert(appdata_img v)
            {
                v2f o;
                o.vertex = TransformObjectToHClip(v.vertex);
                o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);
                return o;
            }

            half random(half2 p) {
                p = frac(p * half2(123.34, 345.45));
                p += dot(p, p + 34.345);
                return frac(p.x + p.y);
            }

            half2 rainEffect(float2 iuv, out float fogTrail)
            {
                half t = fmod(_Time.y, 7200);
                half2 gridNum = float2(_GridNum, _GridNum * _ScreenParams.y / _ScreenParams.x);
                half2 uv = float2(iuv.x * gridNum.x, iuv.y * gridNum.y * 0.8f);
                uv.y += _RainSpeed * t;
                half2 id = floor(uv);
                uv = uv - id - float2(0.5, 0.5); // -0.5 ~ 0.5

                half noise = random(id);
                t += noise * 6.2831;

                half w = iuv.y * 4;
                half dropX = (noise - 0.5) * 0.8;; // -0.4 - 0.4
                dropX += (0.4 - abs(dropX)) * sin(3 * w) * pow(sin(w), 6) * 0.45;// 0.4- abs(x). force the drop only move inside the grid

                half dropY = -sin(t + sin(t + sin(t) * 0.5)) * 0.45;
                dropY -= (uv.x - dropX) * (uv.x - dropX) * 5;
                half2 dropDir = uv - float2(dropX, dropY);
                half drop = smoothstep(0.07, 0.04, length(dropDir));
                // draw a circle, interpolate length(uv) from 0.05 to 0.03, [0.05, 0.03] => [0, 1]

                half2 trailDir = float2(uv.x - dropX, (frac(8 * (uv.y + 0.15 * t)) - 0.5) / 8);
                half trail = smoothstep(0.04, 0.01, length(trailDir));
                trail *= smoothstep(0.5, dropY, uv.y); // trail fade
                trail *= smoothstep(0.05, -0.05, dropY - uv.y); // clear trail under the drop

                fogTrail = smoothstep(-0.05, 0.05, dropDir.y);
                fogTrail *= smoothstep(0.5, dropY, uv.y);
                fogTrail *= smoothstep(0.05, 0.04, abs(dropDir.x));
                trail *= fogTrail;

                // fixed4 col = fixed4(0, 0, 0, 1);
                // col += drop;
                // col += trail;
                // col += fogTrail * 0.5;
                // if (abs(uv.x) > 0.49 || abs(uv.y) > 0.49) col = fixed4(1.0, 0, 0, 1.0); // test line to show grid

                return drop * dropDir + trail * trailDir;
            }


            half4 frag(v2f i) : SV_Target
            {
                // return SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv);

                half fogTrailTotal = 0;
                half fogTrail = 0;
                half2 offset = half2(0, 0);
                /*offset += rainEffect(i.uv * uvScale[0] + uvShift[0], fogTrail);
                fogTrailTotal += fogTrail;*/
                float2 uv = i.uv;
                for (int i = 0; i < _RainAmount; i++) {
                    offset += rainEffect(uv * uvScale[i] + uvShift[i], fogTrail);
                    fogTrailTotal += fogTrail;
                }

                half blur = _Blur * fogTrailTotal;
                uv += offset * _Distortion;
                half4 col = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, uv);
                if (blur > 0.5) {
                    half del = 0.002;
                    col += 0.5f * (SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, uv + blur * half2(del, 0)) +
                        SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, uv + blur * half2(0, del)) +
                        SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, uv + blur * half2(-del, 0)) +
                        SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, uv + blur * half2(0, -del)));
                    col += 0.25f * (SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, uv + blur * half2(del, del)) +
                        SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, uv + blur * half2(del, -del)) +
                        SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, uv + blur * half2(-del, del)) +
                        SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, uv + blur * half2(-del, -del)));
                    col /= 4;
                }
                // fixed4 col = tex2Dlod(_MainTex, half4(uv + offset * _Distortion, 0, blur));

                return col;
            }
        ENDHLSL

        Pass
        {
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            ENDHLSL
        }
    }
    FallBack "Hidden/Universal Render Pipeline/Terrain/Unlit"
}
