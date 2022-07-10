//
//  ShaderCommon.h
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 11/6/22.
//

#ifndef ShaderCommon_h
#define ShaderCommon_h

struct DepthPrePassFragmentOut{
    half4 throwaway_color [[ color(0) ]];
    float bounded_depth [[ color(1) ]];
};

struct ShadowDepthPrePassFragmentOut{
    float throwaway_color [[ color(0) ]];
    float bounded_depth [[ color(1) ]];
};

#endif /* ShaderCommon_h */
