/*
 *  Simple Display Depths Shader for Nvidia Ansel, written by Extravi.
 *  https://extravi.dev/
*/

#include "Reshade.fxh"

uniform int DEPTHS <
    ui_type = "combo";
    ui_items = "Linear Depth\0Normal Buffer\0";
    ui_label = "Display Depths";
> = 0;

uniform float FAR_PLANE <
	ui_type = "slider";
	ui_min = 1.1;
	ui_max = 3000.0;
	ui_label = "Far Plane";
> = 2000.0;

uniform float NEAR_PLANE <
	ui_type = "slider";
	ui_min = 1.1;
	ui_max = 1000.0;
	ui_label = "Near Plane";
> = 25.0;

//////////////////////////////////////
// Functions and code below
//////////////////////////////////////

// function to get the depths buffer
float GetDepth(float2 texcoord)
{
    return ReShade::GetLinearizedDepth(texcoord);
}

float3 PS_DisplayDepth(float4 position : SV_Position, float2 texcoord : TEXCOORD0) : SV_Target
{
    // defines far plane distance and near plane distance
    float f = FAR_PLANE;
    float n = NEAR_PLANE;

    // get the depth value at the texture coordinate
    float depth = GetDepth(texcoord);

    // linearize depth
    depth = lerp(n, f, depth);
    
    // normalize depth
    return depth / (f - n);
}

float3 PS_NormalBuffer(float4 position : SV_Position, float2 texcoord : TEXCOORD0) : SV_Target
{
    // get the depth value at the texture coordinate
    float depth = GetDepth(texcoord);
    // buffer dimensions vector dims
    float2 dims = float2(BUFFER_WIDTH, BUFFER_HEIGHT);

    // horizontal differences
    float2 texOffset = float2(1, 0) / dims;
    float depthsX = depth - ReShade::GetLinearizedDepth(texcoord - texOffset);
    depthsX += (depth - ReShade::GetLinearizedDepth(texcoord + texOffset)) - depthsX;

    // vertical  differences
    texOffset = float2(0, 1) / dims;
    float depthsY = depth - ReShade::GetLinearizedDepth(texcoord - texOffset);
    depthsY += (depth - ReShade::GetLinearizedDepth(texcoord + texOffset)) - depthsY;

    // normalized normal
    return 0.5 + 0.5 * normalize(float3(depthsX, depthsY, depth / FAR_PLANE));
}

// display depths mode
float3 MainPS(float4 position : SV_Position, float2 texcoord : TEXCOORD0) : SV_Target
{
    if (DEPTHS == 0)
    {
        return PS_DisplayDepth(position, texcoord);
    }
    else
    {
        return PS_NormalBuffer(position, texcoord);
    }
}

technique SimpleDisplayDepth
{
    pass
    {
        VertexShader = PostProcessVS;
        PixelShader = MainPS;
    }
}