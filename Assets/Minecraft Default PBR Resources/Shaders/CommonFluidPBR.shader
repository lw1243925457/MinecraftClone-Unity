﻿Shader "Minecraft/Common Fluid (PBR)"
{
    Properties
    {
		[HDR] _MainColor("Main Color", Color) = (1, 1, 1, 1)
		_BumpScale("Bump Scale", Float) = 1.0
    }
    SubShader
    {
		HLSLINCLUDE
		#include "Includes/Minecraft/BlockBRDF.hlsl"

		CBUFFER_START(UnityPerMaterial)
			half4 _MainColor;
			half _BumpScale;
		CBUFFER_END
		ENDHLSL

		Tags
		{
			"RenderPipeline" = "UniversalPipeline"
			"UniversalMaterialType" = "Lit"
			"RenderType" = "Transparent"
			"Queue" = "Transparent"
			"IgnoreProjector" = "True"
			"ShaderModel"="4.5"
		}

        Pass
        {
			Tags { "LightMode" = "UniversalForward" }

			LOD 200
			Cull Off
			ZTest Less
			ZWrite Off
			Blend SrcAlpha OneMinusSrcAlpha

            HLSLPROGRAM
			#pragma vertex vert
            #pragma fragment frag

			struct Varyings
			{
				float2 uv : TEXCOORD0;
				int3 texIndices : TEXCOORD1;
				float3 positionWS : TEXCOORD2;
				float3 normalWS : TEXCOORD3;
				float4 tangentWS : TEXCOORD4;
				float3 lights : TEXCOORD5;
				float3 viewDirWS : TEXCOORD6;
				float4 shadowCoord : TEXCOORD7;
				float4 positionCS : SV_POSITION;
			};

			Varyings vert(BlockAttributes input)
			{
				Varyings output = (Varyings)0;
				VertexPositionInputs vertexInput = GetVertexPositionInputs(input.positionOS.xyz);
				VertexNormalInputs normalInput = GetVertexNormalInputs(input.normalOS, input.tangentOS);

				half3 viewDirWS = GetWorldSpaceViewDir(vertexInput.positionWS);

				output.uv = input.uv;
				output.texIndices = input.texIndices;
				output.positionWS = vertexInput.positionWS;
				output.normalWS = normalInput.normalWS;
				real sign = input.tangentOS.w * GetOddNegativeScale();
				output.tangentWS = half4(normalInput.tangentWS.xyz, sign);
				output.lights = input.lights;
				output.viewDirWS = viewDirWS;
				output.shadowCoord = GetShadowCoord(vertexInput);
				output.positionCS = vertexInput.positionCS;
				return output;
			}

			float4 frag(Varyings input) : SV_TARGET
			{
				half4 albedo = SAMPLE_BLOCK_ALBEDO(input.uv, input.texIndices) * _MainColor;

				float3 bitangent = input.tangentWS.w * cross(input.normalWS.xyz, input.tangentWS.xyz);
				float3 normalTS = UnpackNormalScale(SAMPLE_BLOCK_NORMAL(input.uv, input.texIndices), _BumpScale);
				float3 normalWS = TransformTangentToWorld(normalTS, half3x3(input.tangentWS.xyz, bitangent.xyz, input.normalWS.xyz));

				half4 mer = SAMPLE_BLOCK_MER(input.uv, input.texIndices);

				BlockBRDFData data;
				InitializeBlockBRDFData(albedo, normalWS, mer, input.lights, input.viewDirWS, input.shadowCoord, data);
				return BlockFragmentPBR(data, albedo.a, input.positionWS);
			}
            ENDHLSL
        }
    }
}
