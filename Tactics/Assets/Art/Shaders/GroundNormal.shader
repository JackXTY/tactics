Shader "Custom/GroundNormal"
{
    SubShader
    {
        Tags { "RenderType" = "Opaque" }

        ZWrite Off
        ZTest Always
        Cull Off
        //Blend srcFactor dstFactor
        Blend oneMinusSrcAlpha srcAlpha
        
        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_instancing
            #include "UnityCG.cginc"
            #pragma target 5.0
            #define MAXCOUNT 1024
            StructuredBuffer<float2> timeSliceBuffer;
            struct appdata
            {
                float4 vertex : POSITION;
                float4 uv : TEXCOORD0;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
                float timeSlice : TEXCOORD0;
                float2 uv : TEXCOORD1;
            };

            float scale;

            v2f vert(appdata v, uint instanceID : SV_InstanceID)
            {
                v2f o;
                UNITY_SETUP_INSTANCE_ID(v);
                o.vertex = mul(unity_ObjectToWorld, v.vertex); // just shift quad in xy plane, according to matrix passed from DrawMeshInstanced()
                o.timeSlice = timeSliceBuffer[instanceID].x;
                o.uv = v.uv;
                return o;
            }

            #define PI 18.84955592153876
            float4 frag(v2f i) : SV_Target
            {
                float4 c = 1;
                // the center is the rain drop point, where i.uv = (0, 0) originally
                float2 dir = i.uv - 0.5;
                float len = length(dir);
                bool ignore = len > 0.5;
                dir /= max(len, 1e-5);
                c.xy = (dir * sin(-i.timeSlice * PI + len * 20 * scale * 50)) * 0.5 + 0.5; // remap from (-1, 1) to (0, 1)
                // c.xy = dir * 0.5 + 0.5; // remap from (-1, 1) to (0, 1)
                c.a = ignore ? 1 : i.timeSlice; // when len too long, the a is 1, and it would be ignored in alpha blend (with oneMinusSrcAlpha)
                return c;
            }
            ENDCG
        }
    }
}