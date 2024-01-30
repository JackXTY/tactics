using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

/*
 * If you know nothing about URP, please check:
 * https://zhuanlan.zhihu.com/p/360566324
 * https://zhuanlan.zhihu.com/p/604880712
 * 
 * If you are confused with how URP interact with post-effect, please take a look at:
 * https://www.zhihu.com/tardis/zm/art/161658349?source_id=1005
 * https://www.jianshu.com/p/b9cd6bb4c4aa
 * 
 */

/*
 * AdditionPostProcessPass is a render pass specifically for rendering post effect
 * needed for various weather effect, like fog, raindrop etc.
 * Original post effect is URP is still supported, but for quality reason,
 * implement our own version here may be better.
 */

namespace UnityEngine.Experiemntal.Rendering.Universal
{
    public class AdditionPostProcessPass : ScriptableRenderPass
    {
        RenderTargetIdentifier src;
        RenderTargetIdentifier dest;
        RenderTargetIdentifier depthTarget;
        RenderTargetIdentifier colorTarget;

        const string k_RenderPostProcessingTag = "Render AdditionalPostProcessing Effects";
        // const string k_RenderFinalPostProcessingTag = "Render Final AdditionalPostProcessing Pass";

        PostFog m_PostFog;
        DepthBlur m_DepthBlur;
        PostRainDrop m_PostRainDrop;
        GaussianBlur m_GaussianBlur;

        MaterialLibrary m_Materials;
        AdditionalPostProcessData m_Data;

        RenderTargetHandle destBuffer;
        RenderTargetHandle gaussianBlurBuffer0;
        RenderTargetHandle gaussianBlurBuffer1;
        RenderTargetHandle tempBuffer0;
        RenderTargetHandle tempBuffer1;

        public AdditionPostProcessPass()
        {
            destBuffer.Init("_destBuffer");
            gaussianBlurBuffer0.Init("_gaussianBlurBuffer0");
            gaussianBlurBuffer1.Init("_gaussianBlurBuffer1");
            tempBuffer0.Init("_tempBuffer0");
            tempBuffer1.Init("_tempBuffer1");
        }

        // called in AdditionPostProcessRendererFeature, to set AdditionalPostProcess up
        public void Setup(RenderPassEvent @event, AdditionalPostProcessData data)
        {
            m_Data = data;
            renderPassEvent = @event;
            m_Materials = new MaterialLibrary(data);
        }

        public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
        {
            // Debug.Log("AdditionPostProcessPass.Execute()");
            var stack = VolumeManager.instance.stack;
            m_PostFog = stack.GetComponent<PostFog>();
            m_DepthBlur = stack.GetComponent<DepthBlur>();
            m_PostRainDrop = stack.GetComponent<PostRainDrop>();
            m_GaussianBlur = stack.GetComponent<GaussianBlur>();

            if (renderingData.cameraData.isSceneViewCamera ||
                !(m_GaussianBlur.IsActive() || m_DepthBlur.IsActive() || m_PostFog.IsActive() || m_PostRainDrop.IsActive()))
            {
                // Debug.Log("renderingData.cameraData.isSceneViewCamera: " + renderingData.cameraData.isSceneViewCamera.ToString());
                // Debug.Log("AdditionPostProcessPass Quit");
                return;
            }

            var cmd = CommandBufferPool.Get(k_RenderPostProcessingTag);
            RenderTextureDescriptor desc = renderingData.cameraData.cameraTargetDescriptor;
            colorTarget = renderingData.cameraData.renderer.cameraColorTarget;
            depthTarget = renderingData.cameraData.renderer.cameraDepthTarget;
            src = colorTarget;
            dest = src;

            // Since we must copy the render result for single-pass post-effect,
            // to reduce times of cmd.Blit(), we use a buffer to avoid copy multiple times for each single-pass post-effect.
            Action SwitchForSinglePassPostEffect = () =>{
                if (src == colorTarget){
                    cmd.GetTemporaryRT(destBuffer.id, desc);
                    dest = destBuffer.Identifier();
                }else{
                    dest = colorTarget;
                }
            };

            if (m_PostFog.IsActive())
            {
                SwitchForSinglePassPostEffect();
                RenderPostFog(cmd, ref renderingData, m_Materials.postFog);
                src = dest;
                dest = colorTarget;
            }
            if (m_DepthBlur.IsActive())
            {
                RenderDepthBlur(cmd, ref renderingData, m_Materials.depthBlur);
                src = dest;
            }
            if (m_PostRainDrop.IsActive())
            {
                SwitchForSinglePassPostEffect();
                RenderPostRainDrop(cmd, ref renderingData, m_Materials.postRainDrop, m_Materials.gaussianBlur);
                src = dest;
                dest = colorTarget;
            }
            if (m_GaussianBlur.IsActive())
            {
                RenderGaussianBlur(cmd, ref renderingData, m_Materials.gaussianBlur);
                src = dest;
            }

            if (src != colorTarget)
            {
                cmd.Blit(src, colorTarget);
                cmd.ReleaseTemporaryRT(destBuffer.id);
            }

            context.ExecuteCommandBuffer(cmd);
            CommandBufferPool.Release(cmd);
        }

        public void RenderPostFog(CommandBuffer cmd, ref RenderingData renderingData, Material mat)
        {
            
            Matrix4x4 frustumCorners = Matrix4x4.identity;

			float fov = Camera.main.fieldOfView;
			float near = Camera.main.nearClipPlane;
			float aspect = Camera.main.aspect;

			float halfHeight = near * Mathf.Tan(fov * 0.5f * Mathf.Deg2Rad);
			Vector3 toRight = Camera.main.transform.right * halfHeight * aspect;
			Vector3 toTop = Camera.main.transform.up * halfHeight;

			Vector3 topLeft = Camera.main.transform.forward * near + toTop - toRight;
			float scale = topLeft.magnitude / near;

			topLeft.Normalize();
			topLeft *= scale;

			Vector3 topRight = Camera.main.transform.forward * near + toRight + toTop;
			topRight.Normalize();
			topRight *= scale;

			Vector3 bottomLeft = Camera.main.transform.forward * near - toTop - toRight;
			bottomLeft.Normalize();
			bottomLeft *= scale;

			Vector3 bottomRight = Camera.main.transform.forward * near + toRight - toTop;
			bottomRight.Normalize();
			bottomRight *= scale;

			frustumCorners.SetRow(0, bottomLeft);
			frustumCorners.SetRow(1, bottomRight);
			frustumCorners.SetRow(2, topRight);
			frustumCorners.SetRow(3, topLeft);

            mat.SetMatrix("_FrustumCornersRay", frustumCorners);

            mat.SetFloat("_FogDensity", m_PostFog.fogDensity.value);
            mat.SetColor("_FogColor", m_PostFog.fogColor.value);
            mat.SetFloat("_FogHeightStart", m_PostFog.fogHeightStart.value);
            mat.SetFloat("_FogHeightEnd", m_PostFog.fogHeightEnd.value);
            mat.SetFloat("_FogDepthNear", m_PostFog.fogDepthNear.value);
            mat.SetFloat("_FogDepthFar", m_PostFog.fogDepthFar.value);

            mat.SetTexture("_NoiseTex", m_PostFog.noiseTexture.value);
            mat.SetFloat("_FogXSpeed", m_PostFog.fogXSpeed.value);
            mat.SetFloat("_FogYSpeed", m_PostFog.fogYSpeed.value);
            mat.SetFloat("_NoiseAmount", m_PostFog.noiseAmount.value);

			// Vector3 cloudBoxMin = fogBoxTrans.position - fogBoxTrans.localScale / 2;
			// Vector3 cloudBoxMax = fogBoxTrans.position + fogBoxTrans.localScale / 2;
            // mat.SetVector("_CloudBoxMin", m_PostFog.minCorner.value);
            // mat.SetVector("_CloudBoxMax", m_PostFog.maxCorner.value);

			if(m_PostFog.expFog.value)
            {
                mat.EnableKeyword("_EXP_FOG_ON");
			}

            cmd.Blit(src, dest, mat);
        }

        public void RenderDepthBlur(CommandBuffer cmd, ref RenderingData renderingData, Material mat)
        {
            mat.SetFloat("_FocusDis", m_DepthBlur.focusDistance.value);
            mat.SetFloat("_FocusRange", m_DepthBlur.focusRange.value);
            mat.SetFloat("_RadiusSparse", m_DepthBlur.radiusSparse.value);
            mat.SetFloat("_SimpleBlurRange", m_DepthBlur.simpleBlurRange.value);
            mat.SetFloat("_CocEdge", m_DepthBlur.cocEdge.value);
            mat.SetFloat("_ForegroundScale", m_DepthBlur.foregroundScale.value);

            RenderTextureDescriptor desc = renderingData.cameraData.cameraTargetDescriptor;
            
            // RenderTexture cocTex = RenderTexture.GetTemporary(desc.width, desc.height, 0);
            // RenderTexture blurTex = RenderTexture.GetTemporary(desc.width, desc.height, 0);
            RenderTexture cocTex = RenderTexture.GetTemporary(desc.width, desc.height, 0);
            RenderTexture blurTex = RenderTexture.GetTemporary(desc.width, desc.height, 0);

            cmd.Blit(src, cocTex, mat, 0);
            mat.SetTexture("_CocTex", cocTex);

            cmd.GetTemporaryRT(tempBuffer0.id, desc);
            cmd.Blit(src, tempBuffer0.Identifier(), mat, 1);
            cmd.Blit(tempBuffer0.Identifier(), blurTex, mat, 2);
            cmd.ReleaseTemporaryRT(tempBuffer0.id);

            mat.SetTexture("_BlurTex", blurTex);
            cmd.GetTemporaryRT(tempBuffer1.id, desc);
            cmd.Blit(src, tempBuffer1.Identifier(), mat, 3);

            cmd.Blit(tempBuffer1.Identifier(), dest);

            cocTex.Release();
            blurTex.Release();
            
            cmd.ReleaseTemporaryRT(tempBuffer1.id);
        }
        
        public void RenderPostRainDrop(CommandBuffer cmd, ref RenderingData renderingData, Material rainDropMat, Material blurMat)
        {
            RenderTextureDescriptor opaqueDesc = renderingData.cameraData.cameraTargetDescriptor;

            opaqueDesc.width = opaqueDesc.width / m_PostRainDrop.downSample.value;
            opaqueDesc.height = opaqueDesc.height / m_PostRainDrop.downSample.value;
            opaqueDesc.depthBufferBits = 0;

            cmd.GetTemporaryRT(gaussianBlurBuffer0.id, opaqueDesc, m_GaussianBlur.filterMode.value);
            RenderTexture tmpBlurTex = RenderTexture.GetTemporary(opaqueDesc.width, opaqueDesc.height, 0);
            tmpBlurTex.filterMode = m_GaussianBlur.filterMode.value;

            blurMat.SetFloat("_BlurSize", m_PostRainDrop.blur.value);

            // Render blur pass
            cmd.Blit(src, gaussianBlurBuffer0.id, blurMat, 0);
            cmd.Blit(gaussianBlurBuffer0.id, tmpBlurTex, blurMat, 1);

            // TODO: (maybe)
            // Combine blur pass in depth of field and this to the same one
                
            rainDropMat.SetTexture("_BlurTex", tmpBlurTex);
            rainDropMat.SetFloat("_GridNum", m_PostRainDrop.gridNum.value);
            rainDropMat.SetFloat("_Distortion", m_PostRainDrop.distortion.value);
            // rainDropMat.SetFloat("_Blur", m_PostRainDrop.blur.value);
            rainDropMat.SetInteger("_RainAmount", m_PostRainDrop.rainAmount.value);
            rainDropMat.SetFloat("_RainSpeed", m_PostRainDrop.rainSpeed.value);

            if (m_PostRainDrop.fogScreen.value)
            {
                rainDropMat.EnableKeyword("_FOG_SCREEN");
            }
            else
            {
                rainDropMat.DisableKeyword("_FOG_SCREEN");
            }

            cmd.Blit(src, dest, rainDropMat);

            RenderTexture.ReleaseTemporary(tmpBlurTex);
            cmd.ReleaseTemporaryRT(gaussianBlurBuffer0.id);
        }

        public void RenderGaussianBlur(CommandBuffer cmd, ref RenderingData renderingData, Material mat)
        {
            RenderTextureDescriptor opaqueDesc = renderingData.cameraData.cameraTargetDescriptor;
            
            opaqueDesc.width = opaqueDesc.width / m_GaussianBlur.downSample.value;
            opaqueDesc.height = opaqueDesc.height / m_GaussianBlur.downSample.value;
            opaqueDesc.depthBufferBits = 0;
            cmd.GetTemporaryRT(gaussianBlurBuffer0.id, opaqueDesc, m_GaussianBlur.filterMode.value);

            cmd.Blit(src, gaussianBlurBuffer0.Identifier());
            for (int i = 0; i < m_GaussianBlur.iterations.value; i++)
            {
                mat.SetFloat("_BlurSize", 1.0f + i * m_GaussianBlur.blurSpread.value);
                cmd.GetTemporaryRT(gaussianBlurBuffer1.id, opaqueDesc, m_GaussianBlur.filterMode.value);

                // Render the vertical pass
                cmd.Blit(gaussianBlurBuffer0.Identifier(), gaussianBlurBuffer1.Identifier(), mat, 0);

                cmd.ReleaseTemporaryRT(gaussianBlurBuffer0.id);
                cmd.GetTemporaryRT(gaussianBlurBuffer0.id, opaqueDesc, m_GaussianBlur.filterMode.value);
  
                cmd.Blit(gaussianBlurBuffer1.Identifier(), gaussianBlurBuffer0.Identifier(), mat, 1);
                cmd.ReleaseTemporaryRT(gaussianBlurBuffer1.id);
            }

            cmd.Blit(gaussianBlurBuffer0.Identifier(), dest);
            // cmd.GetTemporaryRT(gaussianBlurBuffer0.id, opaqueDesc, m_GaussianBlur.filterMode.value);
            cmd.ReleaseTemporaryRT(gaussianBlurBuffer0.id);

        }
    }
}