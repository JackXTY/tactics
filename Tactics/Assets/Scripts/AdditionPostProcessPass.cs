using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

namespace UnityEngine.Experiemntal.Rendering.Universal
{
    public class AdditionPostProcessPass : ScriptableRenderPass
    {
        RenderTargetIdentifier src;
        RenderTargetIdentifier depthTarget;
        RenderTargetIdentifier dest;

        const string k_RenderPostProcessingTag = "Render AdditionalPostProcessing Effects";
        // const string k_RenderFinalPostProcessingTag = "Render Final AdditionalPostProcessing Pass";

        PostFog m_PostFog;
        DepthBlur m_DepthBlur;
        PostRainDrop m_PostRainDrop;
        GaussianBlur m_GaussianBlur;

        MaterialLibrary m_Materials;
        AdditionalPostProcessData m_Data;

        RenderTargetHandle gaussianBlurBuffer0;
        RenderTargetHandle gaussianBlurBuffer1;
        RenderTargetHandle tempBuffer0;
        RenderTargetHandle tempBuffer1;

        public AdditionPostProcessPass()
        {
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
            src = renderingData.cameraData.renderer.cameraColorTarget;
            dest = src; // So far, we just take it as post process render pass
            depthTarget = renderingData.cameraData.renderer.cameraDepthTarget;
            if (m_PostFog.IsActive())
            {
                RenderPostFog(cmd, ref renderingData, m_Materials.postFog);
            }
            if (m_DepthBlur.IsActive())
            {
                RenderDepthBlur(cmd, ref renderingData, m_Materials.depthBlur);
            }
            if (m_PostRainDrop.IsActive())
            {
                RenderPostRainDrop(cmd, ref renderingData, m_Materials.postRainDrop);
            }
            if (m_GaussianBlur.IsActive())
            {
                RenderGaussianBlur(cmd, ref renderingData, m_Materials.gaussianBlur);
            }
            
            context.ExecuteCommandBuffer(cmd);
            CommandBufferPool.Release(cmd);
        }

        public void RenderPostFog(CommandBuffer cmd, ref RenderingData renderingData, Material mat)
        {
            /*
            Matrix4x4 frustumCorners = Matrix4x4.identity;

			float fov = cam.fieldOfView;
			float near = cam.nearClipPlane;
			float aspect = cam.aspect;

			float halfHeight = near * Mathf.Tan(fov * 0.5f * Mathf.Deg2Rad);
			Vector3 toRight = transform.right * halfHeight * aspect;
			Vector3 toTop = transform.up * halfHeight;

			Vector3 topLeft = transform.forward * near + toTop - toRight;
			float scale = topLeft.magnitude / near;

			topLeft.Normalize();
			topLeft *= scale;

			Vector3 topRight = transform.forward * near + toRight + toTop;
			topRight.Normalize();
			topRight *= scale;

			Vector3 bottomLeft = transform.forward * near - toTop - toRight;
			bottomLeft.Normalize();
			bottomLeft *= scale;

			Vector3 bottomRight = transform.forward * near + toRight - toTop;
			bottomRight.Normalize();
			bottomRight *= scale;

			frustumCorners.SetRow(0, bottomLeft);
			frustumCorners.SetRow(1, bottomRight);
			frustumCorners.SetRow(2, topRight);
			frustumCorners.SetRow(3, topLeft);

			material.SetMatrix("_FrustumCornersRay", frustumCorners);

			material.SetFloat("_FogDensity", fogDensity);
			material.SetColor("_FogColor", fogColor);
			material.SetFloat("_FogHeightStart", fogHeightStart);
			material.SetFloat("_FogHeightEnd", fogHeightEnd);
			material.SetFloat("_FogDepthNear", fogDepthNear);
			material.SetFloat("_FogDepthFar", fogDepthFar);

			material.SetTexture("_NoiseTex", noiseTexture);
			material.SetFloat("_FogXSpeed", fogXSpeed);
			material.SetFloat("_FogYSpeed", fogYSpeed);
			material.SetFloat("_NoiseAmount", noiseAmount);

			Vector3 cloudBoxMin = fogBoxTrans.position - fogBoxTrans.localScale / 2;
			Vector3 cloudBoxMax = fogBoxTrans.position + fogBoxTrans.localScale / 2;
			material.SetVector("_CloudBoxMin", cloudBoxMin);
			material.SetVector("_CloudBoxMax", cloudBoxMax);

			if(expFog)
            {
				material.EnableKeyword("_EXP_FOG_ON");
			}
			

			Graphics.Blit(src, dest, material);
             */
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
        
        public void RenderPostRainDrop(CommandBuffer cmd, ref RenderingData renderingData, Material mat)
        {
            mat.SetFloat("_GridNum", m_PostRainDrop.gridNum.value);
            mat.SetFloat("_Distortion", m_PostRainDrop.distortion.value);
            mat.SetFloat("_Blur", m_PostRainDrop.blur.value);
            mat.SetInteger("_RainAmount", m_PostRainDrop.rainAmount.value);
            mat.SetFloat("_RainSpeed", m_PostRainDrop.rainSpeed.value);

            // RenderTexture temp = RenderTexture.GetTemporary(src.width, src.height);
            //temp.filterMode = FilterMode.Bilinear;
            // temp.useMipMap = true;
            // temp.autoGenerateMips = true;
            // Graphics.Blit(src, temp);
            // Graphics.Blit(temp, dest);
            // Graphics.Blit(temp, dest, material);

            RenderTextureDescriptor opaqueDesc = renderingData.cameraData.cameraTargetDescriptor;
            RenderTexture temp = RenderTexture.GetTemporary(opaqueDesc.width, opaqueDesc.height);
            // cmd.ReleaseTemporaryRT(tempBuffer.id);
            // cmd.GetTemporaryRT(tempBuffer.id, opaqueDesc, m_GaussianBlur.filterMode.value);
            cmd.Blit(src, temp);
            temp.useMipMap = true;
            // cmd.GenerateMips(temp);
            cmd.Blit(temp, dest, mat);
            cmd.ReleaseTemporaryRT(tempBuffer0.id);
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

            }

            cmd.Blit(gaussianBlurBuffer0.Identifier(), dest);
            cmd.GetTemporaryRT(gaussianBlurBuffer0.id, opaqueDesc, m_GaussianBlur.filterMode.value);

        }
    }
}