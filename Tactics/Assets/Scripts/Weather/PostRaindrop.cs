using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteInEditMode]
public class PostRaindrop : MonoBehaviour
{
    public Shader postRaindropShader;
    Material material = null;
	public float gridNum = 16.0f;
	public float distortion = 10.0f;
	public float blur = 1.0f;
	[Range(1, 7)]
	public int rainAmount = 3;
	[Range(0, 3)]
	public float rainSpeed = 0.25f;

	private void Start()
	{
		if (postRaindropShader)
		{
			material = new Material(postRaindropShader);
			material.hideFlags = HideFlags.DontSave;
		}
	}

	void OnRenderImage(RenderTexture src, RenderTexture dest)
	{
		
		if (material != null)
		{
			material.SetFloat("_GridNum", gridNum);
			material.SetFloat("_Distortion", distortion);
			material.SetFloat("_Blur", blur);
			material.SetInteger("_RainAmount", rainAmount);
			material.SetFloat("_RainSpeed", rainSpeed);

			RenderTexture temp = RenderTexture.GetTemporary(src.width, src.height);
			//temp.filterMode = FilterMode.Bilinear;
			temp.useMipMap = true;
			temp.autoGenerateMips = true;
			Graphics.Blit(src, temp);
			// Graphics.Blit(temp, dest);
			Graphics.Blit(temp, dest, material);
		}
		else
		{
			Graphics.Blit(src, dest);
		}
	}
}
