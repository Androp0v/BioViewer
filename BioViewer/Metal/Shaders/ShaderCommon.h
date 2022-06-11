//
//  ShaderCommon.h
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 11/6/22.
//

#ifndef ShaderCommon_h
#define ShaderCommon_h

struct DepthBoundFragmentOut{
    half4 throwaway_color [[ color(0) ]];
    float bounded_depth [[ color(1) ]];
};

struct ShadowDepthBoundFragmentOut{
    float throwaway_color [[ color(0) ]];
    float bounded_depth [[ color(1) ]];
};

#endif /* ShaderCommon_h */
