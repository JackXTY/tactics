Shader "Custom/PostFog"
{
	properties{
		_MainTex("Base (RGB)", 2D) = "white" {}
		_FogDensity("Fog Density", Float) = 1.0
		_FogColor("Fog Color", Color) = (1, 1, 1, 1)
		_FogHeightStart("Fog Height Start", Float) = 0.0
		_FogHeightEnd("Fog Height End", Float) = 1.0
		_FogDepthNear("Fog Depth Near", Float) = 1.0
		_FogDepthFar("Fog Depth Far", Float) = 1.0
		_NoiseTex("Noise Texture", 2D) = "white" {}
		_FogXSpeed("Fog Horizontal Speed", Float) = 0.1
		_FogYSpeed("Fog Vertical Speed", Float) = 0.1
		_NoiseAmount("Noise Amount", Float) = 1
		[Toggle] _exp_fog("Enable Exp Fog", Float) = 0
	}
	SubShader{
		CGINCLUDE

		#include "UnityCG.cginc"

		#pragma multi_compile __ _EXP_FOG_ON

		float4x4 _FrustumCornersRay;

		sampler2D _MainTex;
		half4 _MainTex_TexelSize;
		sampler2D _CameraDepthTexture;
		half _FogDensity;
		fixed4 _FogColor;
		float _FogHeightStart;
		float _FogHeightEnd;
		float _FogDepthNear;
		float _FogDepthFar;
		sampler2D _NoiseTex;
		half _FogXSpeed;
		half _FogYSpeed;
		half _NoiseAmount;
		float3 _CloudBoxMin;
		float3 _CloudBoxMax;

		struct v2f {
			float4 pos : SV_POSITION;
			float2 uv : TEXCOORD0;
			float2 uv_depth : TEXCOORD1;
			float4 interpolatedRay : TEXCOORD2;
		};

		v2f vert(appdata_img v) {
			v2f o;
			o.pos = UnityObjectToClipPos(v.vertex);

			o.uv = v.texcoord;
			o.uv_depth = v.texcoord;

			#if UNITY_UV_STARTS_AT_TOP
			if (_MainTex_TexelSize.y < 0)
				o.uv_depth.y = 1 - o.uv_depth.y;
			#endif

			int index = 0;
			if (v.texcoord.x < 0.5 && v.texcoord.y < 0.5) {
				index = 0;
			}
			else if (v.texcoord.x > 0.5 && v.texcoord.y < 0.5) {
				index = 1;
			}
			else if (v.texcoord.x > 0.5 && v.texcoord.y > 0.5) {
				index = 2;
			}
			else {
				index = 3;
			}
			#if UNITY_UV_STARTS_AT_TOP
			if (_MainTex_TexelSize.y < 0)
				index = 3 - index;
			#endif

			o.interpolatedRay = _FrustumCornersRay[index];

			return o;
		}

		float2 rayBoxDst(float3 invRaydir)
		{
			float3 t0 = (_CloudBoxMin - _WorldSpaceCameraPos.xyz) * invRaydir;
			float3 t1 = (_CloudBoxMax - _WorldSpaceCameraPos.xyz) * invRaydir;
			float3 tmin = min(t0, t1);
			float3 tmax = max(t0, t1);

			float dstA = max(max(tmin.x, tmin.y), tmin.z);
			float dstB = min(tmax.x, min(tmax.y, tmax.z));

			float dstToBox = max(0, dstA);
			float dstInsideBox = max(0, dstB - dstToBox);
			return float2(dstToBox, dstInsideBox);
		}

		fixed4 frag(v2f i) : SV_Target {
			float linearDepth = LinearEyeDepth(SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, i.uv_depth));

			float2 rayBoxVec = rayBoxDst(1 / i.interpolatedRay.xyz);
			float worldPosDepth = linearDepth;
			if (rayBoxVec.x + rayBoxVec.y < linearDepth)
			{
				worldPosDepth = rayBoxVec.x + rayBoxVec.y;
			}
			float3 worldPos = _WorldSpaceCameraPos + worldPosDepth * i.interpolatedRay.xyz;

			/*return fixed4(linearDepth, linearDepth, linearDepth, 1);
			return fixed4(normalize(worldPos) * 0.5f + fixed3(0.5, 0.5, 0.5), 1);*/

			float2 speed = _Time.y * float2(_FogXSpeed, _FogYSpeed);
			float noise = (tex2D(_NoiseTex, i.uv + speed).r - 0.5) * _NoiseAmount;

			float fogHeightDensity = saturate((_FogHeightEnd - worldPos.y) / (_FogHeightEnd - _FogHeightStart));
			float fogDepthDensity = saturate((linearDepth - _FogDepthNear) / (_FogDepthFar - _FogDepthNear));
#ifdef _EXP_FOG_ON
			fogHeightDensity = exp2(fogHeightDensity) - 1;
			fogDepthDensity = exp2(fogDepthDensity) - 1;
			// fogDensity = 1;
#endif
			float fogDensity = fogHeightDensity * fogDepthDensity;
			fogDensity = saturate(fogDensity * _FogDensity * (1 + noise));

			fixed4 finalColor = tex2D(_MainTex, i.uv);
			finalColor.rgb = lerp(finalColor.rgb, _FogColor.rgb, fogDensity);

			return finalColor;
		}

		ENDCG

		Pass {
			CGPROGRAM

			#pragma vertex vert  
			#pragma fragment frag  

			ENDCG
		}
	}
	FallBack Off
}
