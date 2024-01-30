using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class ReflectionCameraController : MonoBehaviour
{
    public GameObject currentCamera;
    public RenderTexture target;
    public int targetScale = 2;
    public Transform refTrans; // ground reference point
    public Material terrainMat;

    void Update()
    {
        if(target.width != Screen.width / targetScale)
        {
            target.width = Screen.width / targetScale;
        }
        if (target.height != Screen.height / targetScale)
        {
            target.height = Screen.height / targetScale;
        }

        Vector3 planeNormal = refTrans.up;
        Vector3 diff = currentCamera.transform.position - refTrans.position;
        diff -= planeNormal * (2.0f * Vector3.Dot(planeNormal, diff));
        transform.position = refTrans.position + diff;
        terrainMat.SetVector("_GroundRef", refTrans.position);
        terrainMat.SetVector("_PlaneNormal", planeNormal);
        // terrainMat.SetVector("_PlaneForward", refTrans.forward);

        Vector3 currCamUp = currentCamera.transform.up;
        Vector3 currCamForward = currentCamera.transform.forward;
        Vector3 reflCamForward = currCamForward - 2 * planeNormal * Vector3.Dot(currCamForward, planeNormal);
        Vector3 reflCamUp = -currCamUp - 2 * planeNormal * Vector3.Dot(-currCamUp, planeNormal);
        transform.rotation = Quaternion.LookRotation(reflCamForward, reflCamUp) ;
    }
}
