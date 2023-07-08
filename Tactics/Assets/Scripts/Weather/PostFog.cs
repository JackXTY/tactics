using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteInEditMode]
public class PostFog : MonoBehaviour
{
	public Shader fogShader;
	private Material fogMaterial = null;
	private Camera cam
    {
        get
        {
			return GetComponent<Camera>();
		}
    }
	public Material material
	{
		get
		{
            if (fogShader && !fogMaterial)
            {
				fogMaterial = new Material(fogShader);
			}
			return fogMaterial;
		}
	}

	[Range(0.1f, 3.0f)]
	public float fogDensity = 1.0f;

	public Color fogColor = Color.white;

	public float fogHeightStart = 0.0f;
	public float fogHeightEnd = 10.0f;
	public float fogDepthNear = 0.0f;
	public float fogDepthFar = 100.0f;

	public Texture noiseTexture;

	[Range(-0.5f, 0.5f)]
	public float fogXSpeed = 0.1f;

	[Range(-0.5f, 0.5f)]
	public float fogYSpeed = 0.1f;

	[Range(0.0f, 3.0f)]
	public float noiseAmount = 1.0f;

	public Transform fogBoxTrans;

	public bool expFog = false;

	void OnEnable()
	{
		GetComponent<Camera>().depthTextureMode |= DepthTextureMode.Depth;
	}


	void OnRenderImage(RenderTexture src, RenderTexture dest)
	{
		if (material != null)
		{
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
		}
		else
		{
			Graphics.Blit(src, dest);
		}
	}
}
