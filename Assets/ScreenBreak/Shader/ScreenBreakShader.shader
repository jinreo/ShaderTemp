Shader "Custom/RenderImage/ScreenBroken" {
	Properties{
		_MainTex("Main Tex", 2D) = "white" {}
		_BrokenNormalMap("BrokenNormal Map",2D) = "bump"{}
		_BrokenScale("BrokenScale",Range(0,0.1)) = 0
	}
		SubShader
		{
			Tags { "RenderPipeline"="UniversalPipeline" }

			Pass
			{
				Tags { "LightMode" = "ForwardBase" }

				HLSLPROGRAM
				#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

				#pragma vertex vert
				#pragma fragment frag

				CBUFFER_START(UnityPerMaterial)

				sampler2D _MainTex;
				float4 _MainTex_ST;
				sampler2D _BrokenNormalMap;
				float4 _BrokenNormalMap_ST;
				float _BrokenScale;
				CBUFFER_END

				struct a2v 
				{
					float4 vertex : POSITION;
					float4 texcoord : TEXCOORD0;
				};

				struct v2f 
				{
					float4 pos : SV_POSITION;
					float4 uv : TEXCOORD0;
				};

				v2f vert(a2v v) 
				{
					v2f o;
					o.pos = TransformObjectToHClip(v.vertex.xyz);

					o.uv.xy = TRANSFORM_TEX(v.texcoord,_MainTex);
					o.uv.zw = TRANSFORM_TEX(v.texcoord, _BrokenNormalMap);
					return o;
				}

				float4 frag(v2f i) : SV_Target
				{

					float4 packedNormal = tex2D(_BrokenNormalMap,i.uv.zw);
					float3 tangentNormal;
					tangentNormal = UnpackNormal(packedNormal);

					tangentNormal.xy *= _BrokenScale;
					float2 offset = tangentNormal.xy;

					float3 col = tex2D(_MainTex, i.uv.xy + offset).rgb;

					float3 lightColor = float3(1, 1, 1);

					float luminance = (col.r + col.g + col.b) / 3;
					float3 finalCol = lerp(float3(luminance,luminance,luminance), col, 0.25);

					return float4(col, 1.0f);
				}

				ENDHLSL
			}

		}
			FallBack "Diffuse"
}