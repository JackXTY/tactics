// Unity built-in shader source. Copyright (c) 2016 Unity Technologies. MIT license (see license.txt)
Shader "Custom/TerrainShader"{
    Properties{
        // used in fallback on old cards & base map
        [HideInInspector] _MainTex("BaseMap (RGB)", 2D) = "white" {}
        [HideInInspector] _Color("Main Color", Color) = (1,1,1,1)
        [HideInInspector] _TerrainHolesTexture("Holes Map (RGB)", 2D) = "white" {}
        _RainNormalMap("NormalMap", 2D) = "white" {}
        [Toggle(_USE_RAIN_NORMAL_MAP)]_UseRainNormalMap("Use Rain Normal Map", Float) = 0
        _MinDiffuseLight("Min Diffuse Light", Range(0, 1)) = 0.2
    }

    SubShader{
        Tags {
            "Queue" = "Geometry-100"
            "RenderType" = "Opaque"
            "TerrainCompatible" = "True"
        }

        CGPROGRAM
        #pragma surface surf Standard vertex:SplatmapVert finalcolor:SplatmapFinalColor finalgbuffer:SplatmapFinalGBuffer addshadow fullforwardshadows
        // #pragma surface surf CustomTerrain vertex:SplatmapVert finalcolor:SplatmapFinalColor finalgbuffer:SplatmapFinalGBuffer addshadow fullforwardshadows
        // #pragma surface surf Standard  addshadow fullforwardshadows
        #pragma instancing_options assumeuniformscaling nomatrices nolightprobe nolightmap forwardadd
        #pragma multi_compile_fog // needed because finalcolor oppresses fog code generation.
        #pragma target 3.0
        #include "UnityPBSLighting.cginc"
        #include "Lighting.cginc"
        #include "AutoLight.cginc"

        #pragma multi_compile_local __ _ALPHATEST_ON
        #pragma multi_compile_local __ _NORMALMAP
        #pragma shader_feature_local _USE_RAIN_NORMAL_MAP

        #define TERRAIN_STANDARD_SHADER
        #define TERRAIN_INSTANCED_PERPIXEL_NORMAL
        #define TERRAIN_SURFACE_OUTPUT SurfaceOutputStandard
        #include "MyTerrainSplatmapCommon.cginc"

        half _Metallic0;
        half _Metallic1;
        half _Metallic2;
        half _Metallic3;

        half _Smoothness0;
        half _Smoothness1;
        half _Smoothness2;
        half _Smoothness3;

        sampler2D _RainNormalMap;

        float _MinDiffuseLight;

        void surf(Input IN, inout SurfaceOutputStandard o) {
            half4 splat_control;
            half weight;
            fixed4 mixedDiffuse;
            half4 defaultSmoothness = half4(_Smoothness0, _Smoothness1, _Smoothness2, _Smoothness3);

            // half3 worldLightDir = normalize(UnityWorldSpaceLightDir(IN.worldPos));
            // o.Normal *= 1 - 2 * step(worldLightDir.y, 0);
            // o.Normal *= -1;

            SplatmapMix(IN, defaultSmoothness, splat_control, weight, mixedDiffuse, o.Normal);
            
            
        #ifdef _USE_RAIN_NORMAL_MAP
            half3 bitangent = cross(o.Normal, half3(1, 0, 0));
            half3 tangent = cross(bitangent, o.Normal);
            half3 rainNormal = UnpackNormal(tex2D(_RainNormalMap, IN.uv_RainNormalMap));
            o.Normal = normalize(half3(
                dot(half3(tangent.x, bitangent.x, o.Normal.x), rainNormal),
                dot(half3(tangent.y, bitangent.y, o.Normal.y), rainNormal),
                dot(half3(tangent.z, bitangent.z, o.Normal.z), rainNormal)));
            
        #endif

            o.Albedo = mixedDiffuse.rgb;
            o.Alpha = weight;
            o.Smoothness = mixedDiffuse.a;
            o.Metallic = dot(splat_control, half4(_Metallic0, _Metallic1, _Metallic2, _Metallic3));
        }

        inline float4 LightingCustomTerrain(SurfaceOutputStandard s, fixed3 lightDir, fixed3 viewDir, half atten)
        {
            // half3 worldLightDir = normalize(UnityWorldSpaceLightDir(i.worldPos));
            // lightDir *= 1 - 2 * step(lightDir.y, 0);
            // float r = lightDir.y;

            half3 worldLightDir = normalize(_WorldSpaceLightPos0);

            half NdotL = saturate(abs(dot(lightDir, normalize(s.Normal))));
            // UNITY_LIGHT_ATTENUATION(atten, i, i.worldPos);
            half diffuse = _MinDiffuseLight + NdotL * atten * (1.0f - _MinDiffuseLight);

            // half specular = _SpecularIntensity * pow(saturate(dot(normalize(viewDir + lightDir), s.Normal)), _SpecularShiness);

            return float4(2 * diffuse * s.Albedo, 1);
        }


        ENDCG

        UsePass "Hidden/Nature/Terrain/Utilities/PICKING"
        UsePass "Hidden/Nature/Terrain/Utilities/SELECTION"
    }

    Dependency "AddPassShader" = "Hidden/TerrainEngine/Splatmap/Standard-AddPass"
    Dependency "BaseMapShader" = "Hidden/TerrainEngine/Splatmap/Standard-Base"
    Dependency "BaseMapGenShader" = "Hidden/TerrainEngine/Splatmap/Standard-BaseGen"

    Fallback "Nature/Terrain/Diffuse"
}