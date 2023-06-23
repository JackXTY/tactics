Shader "Custom/PostRaindrop"
{
    // Reference from https://zhuanlan.zhihu.com/p/298606553
    Properties
    {
        _MainTex("Base (RGB)", 2D) = "white" {}
        _BlurSize("Blur Size", Float) = 1.0
        _GridNum("Grid Number", Integer) = 20
        _Distortion("Distortion", Float) = 10
        _Blur("Blur", Float) = 1
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            int _GridNum;
            float _Distortion;
            float _Blur;

            v2f vert (appdata_img v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
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
                float t = fmod(_Time.y, 7200);
                float2 gridNum = float2(_GridNum, _GridNum * _ScreenParams.y / _ScreenParams.x);
                float2 uv = float2(iuv.x * gridNum.x, iuv.y * gridNum.y * 0.8f);
                uv.y += 0.25 * t;
                float2 id = floor(uv);
                uv = uv - id - float2(0.5, 0.5); // -0.5 ~ 0.5

                half noise = random(id);
                t += noise * 6.2831;

                half w = iuv.y * 4;
                float dropX = (noise - 0.5) * 0.8;; // -0.4 - 0.4
                dropX += (0.4 - abs(dropX)) * sin(3 * w) * pow(sin(w), 6) * 0.45;// 0.4- abs(x). force the drop only move inside the grid

                float dropY = -sin(t + sin(t + sin(t) * 0.5)) * 0.45;
                dropY -= (uv.x - dropX) * (uv.x - dropX) * 5;
                float2 dropDir = uv - float2(dropX, dropY);
                fixed drop = smoothstep(0.07, 0.04, length(dropDir));
                // draw a circle, interpolate length(uv) from 0.05 to 0.03, [0.05, 0.03] => [0, 1]

                float2 trailDir = float2(uv.x - dropX, (frac(8 * (uv.y + 0.15 * t)) - 0.5) / 8);
                fixed trail = smoothstep(0.04, 0.01, length(trailDir));
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

            fixed4 frag(v2f i) : SV_Target
            {
                float fogTrailTotal = 0;
                float fogTrail;
                half2 offset = rainEffect(i.uv * 0.87 - 0.24, fogTrail);
                fogTrailTotal += fogTrail;
                offset += rainEffect(i.uv * 1.35 + 0.4, fogTrail);
                fogTrailTotal += fogTrail;
                offset += rainEffect(i.uv * 1.18 + 0.12, fogTrail);
                fogTrailTotal += fogTrail;
                
                half blur = _Blur * 7 * fogTrailTotal;
                // fixed4 col = tex2D(_MainTex, i.uv + offset * _Distortion);
                fixed4 col = tex2Dlod(_MainTex, half4(i.uv + offset * _Distortion, 0, blur));
                
                return col;
            }
            ENDCG
        }
    }
    FallBack "Diffuse"
}
