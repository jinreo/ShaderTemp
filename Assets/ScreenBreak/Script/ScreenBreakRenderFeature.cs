using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

public class ScreenBreakRenderFeature : ScriptableRendererFeature
{
    [System.Serializable]
    public class BlitSettings
    {
        public bool enable = true;
        public RenderPassEvent Event = RenderPassEvent.AfterRenderingOpaques;

        public Material material = null;
        public int sobelMaterialPassIndex = -1;
        public string textureId = "testPassTexture";
    }

    public BlitSettings settings = new BlitSettings();
    private RenderTargetHandle m_RenderTextureHandle;
    public ScreenBreakRenderPass testPass;


    public override void Create()
    {
        var passIndex = settings.material != null ? settings.material.passCount - 1 : 1;
        settings.sobelMaterialPassIndex = Mathf.Clamp(settings.sobelMaterialPassIndex, -1, passIndex);
        testPass = new ScreenBreakRenderPass(settings.Event, settings.material, settings.sobelMaterialPassIndex, name);
        m_RenderTextureHandle.Init(settings.textureId);

        testPass.enable = settings.enable;
    }

    public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
    {
        var src = renderer.cameraColorTarget;
        var dest = RenderTargetHandle.CameraTarget;

        if (settings.material == null)
        {
            Debug.LogWarningFormat("Missing Blit Material. {0} blit pass will not execute. Check for missing reference in the assigned renderer.", GetType().Name);
            return;
        }

        testPass.Setup(src, dest);
        renderer.EnqueuePass(testPass);
    }
}

public class ScreenBreakRenderPass : ScriptableRenderPass
{

    public bool enable;
    public Material material = null;
    public int blitShaderPassIndex = 0;
    public FilterMode filterMode { get; set; }

    private RenderTargetIdentifier source { get; set; }
    private RenderTargetHandle destination { get; set; }

    RenderTargetHandle m_TemporaryColorTexture;

    string m_ProfilerTag;
    /// </summary>
    public ScreenBreakRenderPass(RenderPassEvent renderPassEvent, Material sobelMaterial, int blitShaderPassIndex, string tag)
    {
        this.renderPassEvent = renderPassEvent;
        this.material = sobelMaterial;
        this.blitShaderPassIndex = blitShaderPassIndex;
        m_ProfilerTag = tag;

        m_TemporaryColorTexture.Init("Temp");
    }

    public void Setup(RenderTargetIdentifier source, RenderTargetHandle destination)
    {
        this.source = source;
        this.destination = destination;
    }

    public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
    {
        CommandBuffer cmd = CommandBufferPool.Get(m_ProfilerTag);
        cmd.Clear();

        RenderTexture tempSrc = RenderTexture.GetTemporary(Screen.width, Screen.height);
        material.SetTexture("_MainTex", tempSrc);

        cmd.Blit(source, tempSrc, material);
        cmd.Blit(tempSrc, source);
        
        context.ExecuteCommandBuffer(cmd);
        CommandBufferPool.Release(cmd);

        RenderTexture.ReleaseTemporary(tempSrc);
    }
}