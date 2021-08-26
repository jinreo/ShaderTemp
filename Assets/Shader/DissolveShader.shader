
Shader "Custom/Dissolve" 
{
	Properties
	{
		_MainTex("Texture", 2D) = "white" {}
		_NoiseTex("Texture", 2D) = "white" {}
		_Level("Dissolution level", Range(0.0, 1.0)) = 0.1
	}

	SubShader
	{
		Tags { "Queue" = "Transparent" "RenderType" = "Transparent" "RenderPipeline" = "UniversalPipeline"}
		LOD 100

		Pass
		{
			Blend SrcAlpha OneMinusSrcAlpha
			Cull Off
			Lighting Off
			ZWrite Off
			Fog { Mode Off }

			HLSLPROGRAM
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
			#pragma vertex vert
			#pragma fragment frag
			
			struct appdata
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
			};

			struct v2f
			{
				float2 uv : TEXCOORD0;
				float4 vertex : SV_POSITION;
			};

			CBUFFER_START(UnityPerMaterial)
			sampler2D _MainTex;
			sampler2D _NoiseTex;
			float _Level;
			float4 _MainTex_ST;
			CBUFFER_END

			v2f vert(appdata v)
			{
				v2f o;
				o.vertex = TransformObjectToHClip(v.vertex.xyz);
				o.uv = TRANSFORM_TEX(v.uv, _MainTex);
				
				return o;
			}

			float4 frag(v2f i) : SV_Target
			{
				float cutout = tex2D(_NoiseTex, i.uv).r;
				float4 col = tex2D(_MainTex, i.uv);

				if (cutout < _Level)
					discard;

				if (cutout < col.a && cutout < _Level)
					col = cutout - _Level;

				return col;
			}
			ENDHLSL
		}
	}
}