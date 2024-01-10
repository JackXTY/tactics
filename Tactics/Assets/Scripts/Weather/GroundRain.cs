using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;

// Reference from https://zhuanlan.zhihu.com/p/37796757


public class GroundRain : MonoBehaviour
{
    private Mesh m_mesh;
    public Mesh fullScreenMesh
    {
        get
        {
            if (m_mesh != null)
                return m_mesh;
            m_mesh = new Mesh();
            m_mesh.vertices = new Vector3[]
            {
                new Vector3(-1,-1,0),
                new Vector3(-1,1,0),
                new Vector3(1,1,0),
                new Vector3(1,-1,0)
            };
            m_mesh.uv = new Vector2[]
            {
                new Vector3(0,1),
                new Vector3(0,0),
                new Vector3(1,0),
                new Vector3(1,1)
            };

            m_mesh.SetIndices(new int[] { 0, 1, 2, 3 }, MeshTopology.Quads, 0);
            return m_mesh;
        }
    }

    public ComputeShader groundRainCS;
    public RenderTexture targetTexture;
    public Material groundNormalMat;
    public Material gausBlurMat;
    public float timeSpeed = 1.25f;
    public float blurSize = 1.0f;

    [HideInInspector]
    public int raindropCount = 512; // Let RenderSystem Control This
    private int _count;
    public int count
    {
        get
        {
            return _count;
        }
        set
        {
            _count = value;
            groundRainCS.SetInt("_Count", count);
            kernel = groundRainCS.FindKernel("CSHigh");
            /*
            if (count > 512)
                kernel = groundRainCS.FindKernel("CSHigh");
            else if (count > 128)
                kernel = groundRainCS.FindKernel("CSMiddle");
            else
                kernel = groundRainCS.FindKernel("CSLow");
            */
        }
    }

    public float raindropScale = 0.02f;
    private float _scale;

    public float scale
    {
        get
        {
            return _scale;
        }
        set
        {
            //Debug.Log("try update ground rain matrix");
            if (matrix != null)
            {
                _scale = value;
                //Debug.Log("update ground rain matrix");
                for (int i = 0; i < count; i++)
                {
                    matrix[i].m00 = scale;
                    matrix[i].m11 = scale;
                    matrix[i].m22 = scale;
                }
                matrixBuffers.SetData(matrix);
                groundRainCS.SetBuffer(kernel, "matrixBuffer", matrixBuffers);
                groundNormalMat.SetFloat("scale", _scale);
            }
        }
    }

    private CommandBuffer commandBuffer;
    private Matrix4x4[] matrix;
    private Vector2[] times;
    private int kernel;
    private ComputeBuffer matrixBuffers;
    private ComputeBuffer timeSliceBuffers;
    private int blurMainTexID;

    void Awake()
    {
        count = raindropCount;

        commandBuffer = new CommandBuffer();
        matrix = new Matrix4x4[1023];
        times = new Vector2[1023];
        for (int i = 0; i < count; i++)
        {
            times[i] = new Vector2(Random.Range(-1f, 1f), Random.Range(0.8f, 1.2f));
            matrix[i] = Matrix4x4.identity;
            matrix[i].m00 = scale;
            matrix[i].m11 = scale;
            matrix[i].m22 = scale;
            matrix[i].m03 = Random.Range(-1f, 1f);
            matrix[i].m13 = Random.Range(-1f, 1f);
        }
        matrixBuffers = new ComputeBuffer(1023, 64);
        matrixBuffers.SetData(matrix);
        timeSliceBuffers = new ComputeBuffer(1023, 8);
        timeSliceBuffers.SetData(times);

        
        groundRainCS.SetBuffer(kernel, "matrixBuffer", matrixBuffers);
        groundRainCS.SetBuffer(kernel, "timeSliceBuffer", timeSliceBuffers);
        groundNormalMat.SetBuffer("timeSliceBuffers", timeSliceBuffers);

        blurMainTexID = Shader.PropertyToID("_MainTex");
        gausBlurMat.SetFloat("_BlurSize", blurSize);
    }

    // Update is called once per frame
    void Update()
    {
        if(scale != raindropScale)
        {
            scale = raindropScale;
        }
        if(count != raindropCount)
        {
            count = raindropCount;
        }
        groundRainCS.SetFloat("_DeltaFlashSpeed", Time.deltaTime * timeSpeed);
        groundRainCS.Dispatch(kernel, count, 1, 1);
        matrixBuffers.GetData(matrix);

        // timeSliceBuffers.GetData(times);
        // Debug.Log(times[0].ToString());
        groundNormalMat.SetBuffer("timeSliceBuffer", timeSliceBuffers);

        commandBuffer.Clear();
        commandBuffer.SetRenderTarget(targetTexture);
        commandBuffer.ClearRenderTarget(true, true, new Color(0.5f, 0.5f, 1, 1));

        commandBuffer.DrawMeshInstanced(fullScreenMesh, 0, groundNormalMat, 0, matrix);
        commandBuffer.GetTemporaryRT(blurMainTexID, targetTexture.descriptor);
        commandBuffer.Blit(targetTexture, blurMainTexID, gausBlurMat, 0);
        commandBuffer.Blit(blurMainTexID, targetTexture, gausBlurMat, 1);
        Graphics.ExecuteCommandBuffer(commandBuffer);
    }

    private void OnDestroy()
    {
        commandBuffer.Release();
    }
}
