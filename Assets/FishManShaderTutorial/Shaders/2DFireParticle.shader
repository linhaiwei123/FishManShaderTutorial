
Shader "FishManShaderTutorial/2DFireParticle"{
	Properties{
	    _MainTex ("MainTex", 2D) = "white" {}
	}

	SubShader
	{
	    Tags { "RenderType" = "Transparent" "Queue" = "Transparent" }

	    Pass
	    {
	        ZWrite Off
	        Blend SrcAlpha OneMinusSrcAlpha

	        CGPROGRAM
	        #pragma vertex vert
	        #pragma fragment frag
			#pragma exclude_renderers d3d11_9x
	        #include "UnityCG.cginc"
			#include "ShaderLibs/Noise.cginc" 
		 
            struct v2f {
		        fixed4 pos : SV_POSITION;
		        fixed2 uv : TEXCOORD0;
		        fixed2 uv_depth : TEXCOORD1;
		        fixed4 interpolatedRay : TEXCOORD2;
	        };
	        v2f vert(appdata_img v) {
		        v2f o;
		        o.pos = UnityObjectToClipPos(v.vertex);
		        o.uv = v.texcoord;
		        return o;
	        }
			
			fixed4 ProcessFrag(v2f input);

			fixed4 frag(v2f i) : SV_Target{
				fixed4 finalColor =fixed4(0.,0.,0.,0.);
				fixed4 processCol = ProcessFrag(i);
                finalColor = processCol;
                finalColor.w =1.0;
				return finalColor;
			}
			
			fixed3 mod289(fixed3 x) {
				return x - floor(x * (1.0 / 289.0)) * 289.0;
			}

			fixed4 mod289(fixed4 x) {
				return x - floor(x * (1.0 / 289.0)) * 289.0;
			}

			fixed4 permute(fixed4 x) {
					 return mod289(((x*34.0)+1.0)*x);
			}

			fixed4 taylorInvSqrt(fixed4 r)
			{
				return 1.79284291400159 - 0.85373472095314 * r;
			}
			
			

			float prng(in fixed2 seed) {
				seed = frac (seed * fixed2 (5.3983, 5.4427));
				seed += dot (seed.yx, seed.xy + fixed2 (21.5351, 14.3137));
				return frac (seed.x * seed.y * 95.4337);
			}

			float NoiseStack(fixed3 pos,int octaves,float falloff){
				float Noise = SNoise(fixed3(pos));
				float off = 1.0;
				if (octaves>1) {
					pos *= 2.0;
					off *= falloff;
					Noise = (1.0-off)*Noise + off*SNoise(fixed3(pos));
				}
				if (octaves>2) {
					pos *= 2.0;
					off *= falloff;
					Noise = (1.0-off)*Noise + off*SNoise(fixed3(pos));
				}
				if (octaves>3) {
					pos *= 2.0;
					off *= falloff;
					Noise = (1.0-off)*Noise + off*SNoise(fixed3(pos));
				}
				return (1.0+Noise)/2.0;
			}

			fixed2 NoiseStackUV(fixed3 pos,int octaves,float falloff,float diff){
				float displaceA = NoiseStack(pos,octaves,falloff);
				float displaceB = NoiseStack(pos+fixed3(3984.293,423.21,5235.19),octaves,falloff);
				return fixed2(displaceA,displaceB);
			}
			fixed4 ProcessFrag(v2f i)  {
				fixed3 acc = fixed3(0.0,0.0,0.0);
				fixed time = _Time.y;

				fixed3 fireCol = fixed3(1.0,0.3,0.0);
				fixed sparkGridSize = 30.0;//»®·Ö¸ñ×Ó
				fixed rotateSpd = 3.*time;//¿ØÖÆÐý×ªËÙ¶È
				fixed yOffset = 4.*time;//¿ØÖÆÁ£×ÓÉÏÉýËÙ¶È

				fixed2 coord = i.uv*sparkGridSize - fixed2(0.,yOffset);
				//coord -= .8*NoiseStackUV(0.01*fixed3(coord*30.,30.0*time),1,0.4,0.1);
				if (abs(fmod(coord.y,2.0))<1.0) //Æ«ÒÆ°ë¸ö¸ñ×Ó
					coord.x += 0.5;
				fixed2 sparkGridIndex = fixed2(floor(coord));
				fixed sparkRandom = prng(sparkGridIndex);//¶¨ÒåÁ£×ÓµÄ´óÐ¡
				fixed sparkLife = min(10.0*(1.0-min((sparkGridIndex.y + yOffset)/(24.0-20.0*sparkRandom),1.0)),1.0);//Ë³Ó¦YÖáÍùÏÂÒÆ¶¯µÄÍ¬Ê±  ²»¶ÏµÄÉ¾¼õÁÁ¶È
				//acc = fixed3(sparkRandom,sparkRandom,sparkRandom);
				if (sparkLife>0.0 ) {
					fixed size = 0.08*sparkRandom;//¶¨ÒåÁ£×ÓµÄ´óÐ¡
					fixed deg = 999.0*sparkRandom*2.0*PI + rotateSpd*(0.5+0.5*sparkRandom);//³õÊ¼»¯Ðý×ª³õ½Ç¶È
					fixed2 rotate = fixed2(sin(deg),cos(deg));
					fixed radius =  0.5-size*0.2;
					fixed2 cirOffset = radius*rotate;//¸ù¾ÝÁ£×ÓµÄ´óÐ¡¾ö¶¨ÆäÐý×ª°ë¾¶
					fixed2 part = frac(coord-cirOffset) - 0.5 ;
					float len = length(part);
					fixed sparksGray = max(0.0,1.0 -len/size);//ÈÃÔ²±äÐ¡µã
					fixed sinval = sin(PI*1.*(0.3+0.7*sparkRandom)*time+sparkRandom*10.);
					fixed period = pow(sinval,5.);
					period = clamp(pow(period,5.),0.,1.);
					fixed blink =(0.8+0.8*abs(period));
					acc = sparkLife*sparksGray*fireCol*blink;
				}
				return fixed4(acc, 1.0);
			}
	    ENDCG
	}//end pass
  }//end SubShader
}//end Shader

