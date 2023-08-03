Shader "Custom/DepthBlur"
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
        Tags { "RenderType"="Opaque" }
        LOD 100

        CGINCLUDE
        #include "UnityCG.cginc"


        struct v2f
        {
            float2 uv : TEXCOORD0;
            float4 vertex : SV_POSITION;
        };

        sampler2D _MainTex;
        float4 _MainTex_ST;
        sampler2D _CameraDepthTexture;
        float _FocusDis;
        float _FocusRange;
        sampler2D _CocTex;
        sampler2D _BlurTex;
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

        v2f vert(appdata_img v)
        {
            v2f o;
            o.vertex = UnityObjectToClipPos(v.vertex);
            o.uv = v.texcoord;
            return o;
        }

        fixed4 fragCoc(v2f i) : SV_Target
        {
            float depth = LinearEyeDepth(tex2D(_CameraDepthTexture, i.uv).r);
            float coc = (depth - _FocusDis) / _FocusRange;
            coc = clamp(coc, -1, 1) * 0.5f + 0.5f;

            //fixed4 col = tex2D(_MainTex, i.uv);
            return fixed4(coc, 0, 0, 1);
        }

        fixed4 fragSampleDisk(v2f i) : SV_Target
        {
            fixed3 fcol = tex2D(_MainTex, i.uv).rgb;
            fixed3 bcol = fcol;
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
                fixed3 col = tex2D(_MainTex, i.uv + uvOffset).rgb;
                
                float coc = 2 * tex2D(_CocTex, i.uv).r - 1.0f;
                float radius = length(uvOffset);
                float w = saturate((abs(coc) - _CocEdge) / (1 - _CocEdge)) * (1 + radius);
                
                fcol += col * w * step(coc, 0);
                fw += w * step(coc, 0);

                bcol += col * w * step(-coc, 0);
                bw += w * step(0, coc);
            }

            bcol /= bw;
            fcol /= fw;

            // return fixed4(lerp(bcol, fcol, fb), fb);

            float fb = _ForegroundScale * fw / (fw + bw);

            return fixed4(lerp(bcol, fcol, fb), fb);

        }

        fixed4 fragSimpleBlur(v2f i) : SV_Target
        {
            // [1, 2, 1]
            // [2, 4, 2]
            // [1, 2, 1]
            fixed4 col = tex2D(_MainTex, i.uv) * 0.25f;
            float4 off = _MainTex_ST.xyxy * float2(-0.5, 0.5).xxyy * 0.001f * _SimpleBlurRange;
            col += 0.125f * (tex2D(_MainTex, i.uv + float2(0, off.y)) + tex2D(_MainTex, i.uv + float2(0, off.w)) + tex2D(_MainTex, i.uv + float2(off.x, 0)) + tex2D(_MainTex, i.uv + float2(off.z, 0)));
            col += 0.0625f * (tex2D(_MainTex, i.uv + off.zy) + tex2D(_MainTex, i.uv + off.zy) + tex2D(_MainTex, i.uv + off.xw) + tex2D(_MainTex, i.uv + off.zw));
            return col;
        }

        fixed4 fragFinal(v2f i) : SV_Target
        {
            half4 src = tex2D(_MainTex, i.uv);
            half coc = tex2D(_CocTex, i.uv).r;
            half4 blur = tex2D(_BlurTex, i.uv);

            half fg = blur.a;
            coc = smoothstep(_CocEdge, 1, abs(2 * coc - 1.0f));
            // coc = abs(2 * coc - 1.0f);
            half3 color = lerp(src.rgb, blur.rgb, coc + fg - coc * fg);
            return half4(color, src.a);
        }
        ENDCG

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment fragCoc
            
            ENDCG
        }

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment fragSampleDisk

            ENDCG
        }

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment fragSimpleBlur

            ENDCG
        }

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment fragFinal

            ENDCG
        }
    }
}
