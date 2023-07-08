using System.Collections;
using System.Collections.Generic;
using UnityEngine;

// Reference: https://zhuanlan.zhihu.com/p/565511249

[ExecuteInEditMode]
public class DepthBlur : MonoBehaviour
{
	public Shader blurShader;
	private Material blurMaterial = null;
	public Material material
	{
		get
		{
			if(blurShader && !blurMaterial)
            {
				blurMaterial = new Material(blurShader);
			}
			return blurMaterial;
		}
	}

	[Range(0, 20)]
	public float focusDistance = 10.0f;
	[Range(0, 20)]
	public float focusRange = 5.0f;
	[Range(0, 20)]
	public float radiusSparse = 4.0f;
	[Range(0, 20)]
	public float simpleBlurRange = 1.0f;
	[Range(0, 1)]
	public float cocEdge = 0.1f;
	[Range(0, 1)]
	public float foregroundScale = 1.0f;


	private void OnEnable()
    {
        Camera.main.depthTextureMode |= DepthTextureMode.Depth;
	}

    void OnRenderImage(RenderTexture src, RenderTexture dest)
	{
		if (material != null)
		{
			material.SetFloat("_FocusDis", focusDistance);
			material.SetFloat("_FocusRange", focusRange);
			material.SetFloat("_RadiusSparse", radiusSparse);
			material.SetFloat("_SimpleBlurRange", simpleBlurRange);
			material.SetFloat("_CocEdge", cocEdge);
			material.SetFloat("_ForegroundScale", foregroundScale);

			RenderTexture coc = RenderTexture.GetTemporary(src.width, src.height, 0);

			Graphics.Blit(src, coc, material, 0);
			material.SetTexture("_CocTex", coc);

			// Graphics.Blit(src, dest, material, 1);

			RenderTexture blur0 = RenderTexture.GetTemporary(src.width, src.height, 0);
			Graphics.Blit(src, blur0, material, 1);


			RenderTexture blur1 = RenderTexture.GetTemporary(src.width, src.height, 0);
			Graphics.Blit(blur0, blur1, material, 2);
			material.SetTexture("_BlurTex", blur1);

			// material.SetTexture("_BlurTex", blur0);
			// Graphics.Blit(blur0, dest);

			Graphics.Blit(src, dest, material, 3);
			coc.Release();
			blur0.Release();
			blur1.Release();
		}
		else
		{
			Graphics.Blit(src, dest);

		}
	}
}
