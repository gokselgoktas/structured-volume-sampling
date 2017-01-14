using System.Collections;
using System.Collections.Generic;

using UnityEngine;

public class StructuredVolumeSampling : MonoBehaviour
{
    private Shader m_Shader;
    private Shader shader
    {
        get
        {
            if (m_Shader == null)
                m_Shader = Shader.Find("Hidden/Structured Volume Sampling");

            return m_Shader;
        }
    }

    private Material m_Material;
    private Material material
    {
        get
        {
            if (m_Material == null)
            {
                if (shader == null || !shader.isSupported)
                    return null;

                m_Material = new Material(shader);
            }

            return m_Material;
        }
    }

    private Camera m_Camera;
    public Camera camera_
    {
        get
        {
            if (m_Camera == null)
                m_Camera = GetComponent<Camera>();

            return m_Camera;
        }
    }

    private Mesh m_Dodecahedron;
    private Mesh dodecahedron
    {
        get
        {
            if (m_Dodecahedron == null)
            {
                m_Dodecahedron = Resources.Load("Meshes/Dodecahedron") as Mesh;

                var meshFilter = GetComponent<MeshFilter>();

                if (meshFilter)
                    meshFilter.sharedMesh = m_Dodecahedron;
            }

            return m_Dodecahedron;
        }
    }

    private Texture2D m_LookupTexture;
    private Texture2D lookupTexture
    {
        get
        {
            if (m_LookupTexture == null)
            {
                m_LookupTexture = new Texture2D(256, 256, TextureFormat.RGBAFloat, false);
                m_LookupTexture.name = "Lookup";
                m_LookupTexture.wrapMode = TextureWrapMode.Repeat;

                for (int i = 0; i < m_LookupTexture.height; ++i)
                {
                    for (int k = 0; k < m_LookupTexture.width; ++k)
                    {
                        Color color = new Color(Random.value, 0f, 0f, 0f);
                        m_LookupTexture.SetPixel(k, i, color);
                    }
                }

                for (int i = 0; i < m_LookupTexture.height; ++i)
                {
                    for (int k = 0; k < m_LookupTexture.width; ++k)
                    {
                        Color color = m_LookupTexture.GetPixel(k, i);
                        color.g = m_LookupTexture.GetPixel(k + 37, i + 17).r;
                        color.b = m_LookupTexture.GetPixel(k + 59, i + 83).r;
                        color.a = m_LookupTexture.GetPixel(k + 96, i + 100).r;

                        m_LookupTexture.SetPixel(k, i, color);
                    }
                }

                m_LookupTexture.Apply();
            }

            return m_LookupTexture;
        }
    }

    [ImageEffectOpaque]
    public void OnRenderImage(RenderTexture source, RenderTexture destination)
    {
        material.SetTexture("_LookupTexture", lookupTexture);

        material.SetMatrix("_ViewMatrix", camera_.worldToCameraMatrix);
        material.SetMatrix("_ProjectionMatrix", camera_.projectionMatrix);

        material.SetInt("_MaximumIterationCount", 16);

        material.SetFloat("_Range", 100f);

        Graphics.SetRenderTarget(destination);

        material.SetPass(0);
        Graphics.DrawMeshNow(dodecahedron, Matrix4x4.identity, 0);

        material.SetPass(1);
        Graphics.DrawMeshNow(dodecahedron, Matrix4x4.identity, 1);

        material.SetPass(2);
        Graphics.DrawMeshNow(dodecahedron, Matrix4x4.identity, 2);
    }
}
