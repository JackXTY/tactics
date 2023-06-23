using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteInEditMode]
public class PostRaindrop : MonoBehaviour
{
    public Shader postRaindropShader;
    Material material = null;
	public int gridNum = 15;
	public float distortion = 10.0f;
	public float blur = 1.0f;

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
			material.SetInteger("_GridNum", gridNum);
			material.SetFloat("_Distortion", distortion);
			material.SetFloat("_Blur", blur);

			RenderTexture temp = RenderTexture.GetTemporary(src.width, src.height);
			//temp.filterMode = FilterMode.Bilinear;
			temp.useMipMap = true;
			temp.autoGenerateMips = true;
			Graphics.Blit(src, temp);
			Graphics.Blit(temp, dest, material);
		}
		else
		{
			Graphics.Blit(src, dest);
		}
	}
}
