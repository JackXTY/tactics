
#ifndef CUSTOM_UNIVERSAL_TERRAIN_LIT_PASSES_INCLUDED
#define CUSTOM_UNIVERSAL_TERRAIN_LIT_PASSES_INCLUDED

#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/UnityGBuffer.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DBuffer.hlsl"
#include "Packages/com.unity.render-pipelines.universal/Shaders/Terrain/TerrainLitPasses.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareDepthTexture.hlsl"
#include "Assets/Art/Shaders/TerrainHelper.hlsl"

struct CustomVaryings
{
    float4 uvMainAndLM              : TEXCOORD0; // xy: control, zw: lightmap
#ifndef TERRAIN_SPLAT_BASEPASS
    float4 uvSplat01                : TEXCOORD1; // xy: splat0, zw: splat1
    float4 uvSplat23                : TEXCOORD2; // xy: splat2, zw: splat3
#endif

#if defined(_NORMALMAP) && !defined(ENABLE_TERRAIN_PERPIXEL_NORMAL)
    half4 normal                    : TEXCOORD3;    // xyz: normal, w: viewDir.x
    half4 tangent                   : TEXCOORD4;    // xyz: tangent, w: viewDir.y
    half4 bitangent                 : TEXCOORD5;    // xyz: bitangent, w: viewDir.z
#else
    half3 normal                    : TEXCOORD3;
    half3 vertexSH                  : TEXCOORD4; // SH
#endif

#ifdef _ADDITIONAL_LIGHTS_VERTEX
    half4 fogFactorAndVertexLight   : TEXCOORD6; // x: fogFactor, yzw: vertex light
#else
    half  fogFactor                 : TEXCOORD6;
#endif

    float3 positionWS               : TEXCOORD7;

#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
    float4 shadowCoord              : TEXCOORD8;
#endif

#if defined(DYNAMICLIGHTMAP_ON)
    float2 dynamicLightmapUV        : TEXCOORD9;
#endif

#ifdef _RAIN_EFFECT
    float2 uvRainTex                : TEXCOORD10;
#endif

    float4 clipPos                  : SV_POSITION;
    UNITY_VERTEX_OUTPUT_STEREO
};



// Used in Standard Terrain shader
CustomVaryings CustomSplatmapVert(Attributes v)
{
    CustomVaryings o = (CustomVaryings)0;

    UNITY_SETUP_INSTANCE_ID(v);
    UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
    TerrainInstancing(v.positionOS, v.normalOS, v.texcoord);

    VertexPositionInputs Attributes = GetVertexPositionInputs(v.positionOS.xyz);

    o.uvMainAndLM.xy = v.texcoord;
    o.uvMainAndLM.zw = v.texcoord * unity_LightmapST.xy + unity_LightmapST.zw;

#ifndef TERRAIN_SPLAT_BASEPASS
    o.uvSplat01.xy = TRANSFORM_TEX(v.texcoord, _Splat0);
    o.uvSplat01.zw = TRANSFORM_TEX(v.texcoord, _Splat1);
    o.uvSplat23.xy = TRANSFORM_TEX(v.texcoord, _Splat2);
    o.uvSplat23.zw = TRANSFORM_TEX(v.texcoord, _Splat3);
#endif

#if defined(DYNAMICLIGHTMAP_ON)
    o.dynamicLightmapUV = v.texcoord * unity_DynamicLightmapST.xy + unity_DynamicLightmapST.zw;
#endif

#if defined(_NORMALMAP) && !defined(ENABLE_TERRAIN_PERPIXEL_NORMAL)
    half3 viewDirWS = GetWorldSpaceNormalizeViewDir(Attributes.positionWS);
    float4 vertexTangent = float4(cross(float3(0, 0, 1), v.normalOS), 1.0);
    VertexNormalInputs normalInput = GetVertexNormalInputs(v.normalOS, vertexTangent);

    o.normal = half4(normalInput.normalWS, viewDirWS.x);
    o.tangent = half4(normalInput.tangentWS, viewDirWS.y);
    o.bitangent = half4(normalInput.bitangentWS, viewDirWS.z);
#else
    o.normal = TransformObjectToWorldNormal(v.normalOS);
    o.vertexSH = SampleSH(o.normal);
#endif

    half fogFactor = 0;
#if !defined(_FOG_FRAGMENT)
    fogFactor = ComputeFogFactor(Attributes.positionCS.z);
#endif

#ifdef _ADDITIONAL_LIGHTS_VERTEX
    o.fogFactorAndVertexLight.x = fogFactor;
    o.fogFactorAndVertexLight.yzw = VertexLighting(Attributes.positionWS, o.normal.xyz);
#else
    o.fogFactor = fogFactor;
#endif

    o.positionWS = Attributes.positionWS;
    o.clipPos = Attributes.positionCS;

#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
    o.shadowCoord = GetShadowCoord(Attributes);
#endif


#ifdef _RAIN_EFFECT
    o.uvRainTex = TRANSFORM_TEX(v.texcoord, _GroundRainNormalTex);
#endif

    return o;
}

void CustomInitializeInputData(CustomVaryings IN, half3 normalTS, out InputData inputData)
{
    inputData = (InputData)0;

    inputData.positionWS = IN.positionWS;
    inputData.positionCS = IN.clipPos;

#if defined(_NORMALMAP) && !defined(ENABLE_TERRAIN_PERPIXEL_NORMAL)
    half3 viewDirWS = half3(IN.normal.w, IN.tangent.w, IN.bitangent.w);
    inputData.tangentToWorld = half3x3(-IN.tangent.xyz, IN.bitangent.xyz, IN.normal.xyz);
    inputData.normalWS = TransformTangentToWorld(normalTS, inputData.tangentToWorld);
    // no need for vertex SH when _NORMALMAP is defined as we will evaluate SH per pixel
    half3 SH = 0;
#elif defined(ENABLE_TERRAIN_PERPIXEL_NORMAL)
    half3 viewDirWS = GetWorldSpaceNormalizeViewDir(IN.positionWS);
    float2 sampleCoords = (IN.uvMainAndLM.xy / _TerrainHeightmapRecipSize.zw + 0.5f) * _TerrainHeightmapRecipSize.xy;
    half3 normalWS = TransformObjectToWorldNormal(normalize(SAMPLE_TEXTURE2D(_TerrainNormalmapTexture, sampler_TerrainNormalmapTexture, sampleCoords).rgb * 2 - 1));
    half3 tangentWS = cross(GetObjectToWorldMatrix()._13_23_33, normalWS);
    inputData.normalWS = TransformTangentToWorld(normalTS, half3x3(-tangentWS, cross(normalWS, tangentWS), normalWS));
    half3 SH = IN.vertexSH;
#else
    half3 viewDirWS = GetWorldSpaceNormalizeViewDir(IN.positionWS);
    inputData.normalWS = IN.normal;
    half3 SH = IN.vertexSH;
#endif

    inputData.normalWS = NormalizeNormalPerPixel(inputData.normalWS);
    inputData.viewDirectionWS = viewDirWS;

#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
    inputData.shadowCoord = IN.shadowCoord;
#elif defined(MAIN_LIGHT_CALCULATE_SHADOWS)
    inputData.shadowCoord = TransformWorldToShadowCoord(inputData.positionWS);
#else
    inputData.shadowCoord = float4(0, 0, 0, 0);
#endif

#ifdef _ADDITIONAL_LIGHTS_VERTEX
    inputData.fogCoord = InitializeInputDataFog(float4(IN.positionWS, 1.0), IN.fogFactorAndVertexLight.x);
    inputData.vertexLighting = IN.fogFactorAndVertexLight.yzw;
#else
    inputData.fogCoord = InitializeInputDataFog(float4(IN.positionWS, 1.0), IN.fogFactor);
#endif

#if defined(DYNAMICLIGHTMAP_ON)
    inputData.bakedGI = SAMPLE_GI(IN.uvMainAndLM.zw, IN.dynamicLightmapUV, SH, inputData.normalWS);
#else
    inputData.bakedGI = SAMPLE_GI(IN.uvMainAndLM.zw, SH, inputData.normalWS);
#endif
    inputData.normalizedScreenSpaceUV = GetNormalizedScreenSpaceUV(IN.clipPos);
    inputData.shadowMask = SAMPLE_SHADOWMASK(IN.uvMainAndLM.zw)

#if defined(DEBUG_DISPLAY)
#if defined(DYNAMICLIGHTMAP_ON)
        inputData.dynamicLightmapUV = IN.dynamicLightmapUV;
#endif
#if defined(LIGHTMAP_ON)
    inputData.staticLightmapUV = IN.uvMainAndLM.zw;
#else
    inputData.vertexSH = SH;
#endif
#endif
}

void CustomComputeMasks(out half4 masks[4], half4 hasMask, CustomVaryings IN)
{
    masks[0] = 0.5h;
    masks[1] = 0.5h;
    masks[2] = 0.5h;
    masks[3] = 0.5h;

#ifdef _MASKMAP
    masks[0] = lerp(masks[0], SAMPLE_TEXTURE2D(_Mask0, sampler_Mask0, IN.uvSplat01.xy), hasMask.x);
    masks[1] = lerp(masks[1], SAMPLE_TEXTURE2D(_Mask1, sampler_Mask0, IN.uvSplat01.zw), hasMask.y);
    masks[2] = lerp(masks[2], SAMPLE_TEXTURE2D(_Mask2, sampler_Mask0, IN.uvSplat23.xy), hasMask.z);
    masks[3] = lerp(masks[3], SAMPLE_TEXTURE2D(_Mask3, sampler_Mask0, IN.uvSplat23.zw), hasMask.w);
#endif

    masks[0] *= _MaskMapRemapScale0.rgba;
    masks[0] += _MaskMapRemapOffset0.rgba;
    masks[1] *= _MaskMapRemapScale1.rgba;
    masks[1] += _MaskMapRemapOffset1.rgba;
    masks[2] *= _MaskMapRemapScale2.rgba;
    masks[2] += _MaskMapRemapOffset2.rgba;
    masks[3] *= _MaskMapRemapScale3.rgba;
    masks[3] += _MaskMapRemapOffset3.rgba;
}

// Used in Standard Terrain shader
#ifdef TERRAIN_GBUFFER
FragmentOutput CustomSplatmapFragment(CustomVaryings IN)
#else
half4 CustomSplatmapFragment(CustomVaryings IN) : SV_TARGET
#endif
{
    UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(IN);
#ifdef _ALPHATEST_ON
    ClipHoles(IN.uvMainAndLM.xy);
#endif

    half3 normalTS = half3(0.0h, 0.0h, 1.0h);
#ifdef TERRAIN_SPLAT_BASEPASS
    half3 albedo = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, IN.uvMainAndLM.xy).rgb;
    half smoothness = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, IN.uvMainAndLM.xy).a;
    half metallic = SAMPLE_TEXTURE2D(_MetallicTex, sampler_MetallicTex, IN.uvMainAndLM.xy).r;
    half alpha = 1;
    half occlusion = 1;
#else

    half4 hasMask = half4(_LayerHasMask0, _LayerHasMask1, _LayerHasMask2, _LayerHasMask3);
    half4 masks[4];
    CustomComputeMasks(masks, hasMask, IN);

    float2 splatUV = (IN.uvMainAndLM.xy * (_Control_TexelSize.zw - 1.0f) + 0.5f) * _Control_TexelSize.xy;
    half4 splatControl = SAMPLE_TEXTURE2D(_Control, sampler_Control, splatUV);

    half alpha = dot(splatControl, 1.0h);
#ifdef _TERRAIN_BLEND_HEIGHT
    // disable Height Based blend when there are more than 4 layers (multi-pass breaks the normalization)
    if (_NumLayersCount <= 4)
        HeightBasedSplatModify(splatControl, masks);
#endif

    half weight;
    half4 mixedDiffuse;
    half4 defaultSmoothness;
    SplatmapMix(IN.uvMainAndLM, IN.uvSplat01, IN.uvSplat23, splatControl, weight, mixedDiffuse, defaultSmoothness, normalTS);
    half3 albedo = mixedDiffuse.rgb;

    half4 defaultMetallic = half4(_Metallic0, _Metallic1, _Metallic2, _Metallic3);
    half4 defaultOcclusion = half4(_MaskMapRemapScale0.g, _MaskMapRemapScale1.g, _MaskMapRemapScale2.g, _MaskMapRemapScale3.g) +
                            half4(_MaskMapRemapOffset0.g, _MaskMapRemapOffset1.g, _MaskMapRemapOffset2.g, _MaskMapRemapOffset3.g);

    half4 maskSmoothness = half4(masks[0].a, masks[1].a, masks[2].a, masks[3].a);
    defaultSmoothness = lerp(defaultSmoothness, maskSmoothness, hasMask);
    half smoothness = dot(splatControl, defaultSmoothness);

    half4 maskMetallic = half4(masks[0].r, masks[1].r, masks[2].r, masks[3].r);
    defaultMetallic = lerp(defaultMetallic, maskMetallic, hasMask);
    half metallic = dot(splatControl, defaultMetallic);

    half4 maskOcclusion = half4(masks[0].g, masks[1].g, masks[2].g, masks[3].g);
    defaultOcclusion = lerp(defaultOcclusion, maskOcclusion, hasMask);
    half occlusion = dot(splatControl, defaultOcclusion);
#endif

/*
    With _RAIN_EFFECT defined, the the raindrop effect 
*/
#ifdef _RAIN_EFFECT
    // sample rain ground normal, draw ripple on ground
    half3 rainNormalTS = normalize(UnpackNormal(SAMPLE_TEXTURE2D(_GroundRainNormalTex, sampler_GroundRainNormalTex, IN.uvRainTex)));
    half3 bitangentTS = cross(normalTS, half3(1, 0, 0));
    half3 tangentTS = cross(bitangentTS, normalTS);
    normalTS = normalize(half3(
        dot(half3(tangentTS.x, bitangentTS.x, normalTS.x), rainNormalTS),
        dot(half3(tangentTS.y, bitangentTS.y, normalTS.y), rainNormalTS),
        dot(half3(tangentTS.z, bitangentTS.z, normalTS.z), rainNormalTS)));



    float3 camToPointDirWS = normalize(IN.positionWS.xyz - _WorldSpaceCameraPos);
    float3 reflDir = reflect(camToPointDirWS, IN.normal.xyz);

    bool find = false;

    // test for intersection
    float2 tempUV = float2(-1.0f, -1.0f);
    float smallStepSize = 1.0f;
    // float testDepthDiff = CheckDepthDiff(IN.positionWS.xyz, tempUV);
    // In TerrainHelper.hlsl, return true when (pixel_depth < eyeDistance)
    float depthDiff = CheckDepthDiff(IN.positionWS.xyz + reflDir * smallStepSize, tempUV);
    if (depthDiff < 0.0f) {
        // return float4(abs(depthDiff), 0.0f, 0.0f, 1.0f);

        // search within 1.0f, since objects too close to ground
        /*
        UNITY_LOOP
        for (float step = 1.0f; step < 2.0f; step += small_step_size) {
            float3 reflPosWS = groundPos + reflDir * step;

            // In TerrainHelper.hlsl, return true when (pixel_depth < eyeDistance)
            float2 tempUV;
            if (CheckIntersection(reflPosWS, tempUV) < 0.0f) {
                albedo = SAMPLE_TEXTURE2D(_CameraOpaqueTexture, sampler_CameraOpaqueTexture, tempUV);
                find = true;
                break;
            }
        }
        */
    }
    else {
        UNITY_LOOP
        for (float step = 1.0f; step < 100.0f; step += 5.0f) {
            float3 reflPosWS = IN.positionWS.xyz + reflDir * step;
            
            if (CheckDepthDiff(reflPosWS, tempUV) < 0.0f) {
                break;
            }
        }
    }
    
    if (tempUV.x >= 0.0f) {
        albedo = SAMPLE_TEXTURE2D(_CameraOpaqueTexture, sampler_CameraOpaqueTexture, tempUV);
    }
    
    
    // smoothness = 1.0f;
#endif

    InputData inputData;
    CustomInitializeInputData(IN, normalTS, inputData);
    SETUP_DEBUG_TEXTURE_DATA(inputData, IN.uvMainAndLM.xy, _BaseMap);

#if defined(_DBUFFER)
    half3 specular = half3(0.0h, 0.0h, 0.0h);
    ApplyDecal(IN.clipPos,
        albedo,
        specular,
        inputData.normalWS,
        metallic,
        occlusion,
        smoothness);
#endif

#ifdef TERRAIN_GBUFFER

    BRDFData brdfData;
    InitializeBRDFData(albedo, metallic, /* specular */ half3(0.0h, 0.0h, 0.0h), smoothness, alpha, brdfData);

    // Baked lighting.
    half4 color;
    Light mainLight = GetMainLight(inputData.shadowCoord, inputData.positionWS, inputData.shadowMask);
    MixRealtimeAndBakedGI(mainLight, inputData.normalWS, inputData.bakedGI, inputData.shadowMask);
    color.rgb = GlobalIllumination(brdfData, inputData.bakedGI, occlusion, inputData.positionWS, inputData.normalWS, inputData.viewDirectionWS);
    color.a = alpha;
    SplatmapFinalColor(color, inputData.fogCoord);

    // Dynamic lighting: emulate SplatmapFinalColor() by scaling gbuffer material properties. This will not give the same results
    // as forward renderer because we apply blending pre-lighting instead of post-lighting.
    // Blending of smoothness and normals is also not correct but close enough?
    brdfData.albedo.rgb *= alpha;
    brdfData.diffuse.rgb *= alpha;
    brdfData.specular.rgb *= alpha;
    brdfData.reflectivity *= alpha;
    inputData.normalWS = inputData.normalWS * alpha;
    smoothness *= alpha;

    return BRDFDataToGbuffer(brdfData, inputData, smoothness, color.rgb, occlusion);

#else

    half4 color = UniversalFragmentPBR(inputData, albedo, metallic, /* specular */ half3(0.0h, 0.0h, 0.0h), smoothness, occlusion, /* emission */ half3(0, 0, 0), alpha);

    SplatmapFinalColor(color, inputData.fogCoord);

    return half4(color.rgb, 1.0h);
#endif
}

#endif