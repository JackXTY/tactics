using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class CameraMoveSimple : MonoBehaviour
{
    public float rotateSpeed = 5.0f;
    public float moveSpeed = 1.0f;
    // Update is called once per frame

    Vector3 prevMousePos;

    private void Start()
    {
        prevMousePos = Input.mousePosition;
    }

    void Update()
    {
        Vector3 move = Vector3.zero;
        if(Input.GetKey("w")) { move.z = 1.0f; }
        else if(Input.GetKey("s")) { move.z = -1.0f; }
        if (Input.GetKey("a")) { move.x = -1.0f; }
        else if (Input.GetKey("d")) { move.x = 1.0f; }
        if (Input.GetKey("z")) { move.y = -1.0f; }
        else if (Input.GetKey("x")) { move.y = 1.0f; }

        Vector3 rot = Vector3.zero;
        if(Input.GetMouseButton(0))
        {
            rot = Input.mousePosition - prevMousePos;
        }
        
        prevMousePos = Input.mousePosition;

        transform.Translate(move * moveSpeed * Time.deltaTime, Space.Self);
        transform.Rotate(new Vector3(-rot.y, rot.x, 0) * rotateSpeed * Time.deltaTime, Space.Self);
    }
}
