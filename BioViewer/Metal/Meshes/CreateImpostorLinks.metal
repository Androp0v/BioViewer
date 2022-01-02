//
//  CreateImpostorLinks.metal
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 29/12/21.
//

#include <metal_stdlib>
#include "AtomProperties.h"
#include "GeneratedVertex.h"

using namespace metal;

kernel void create_impostor_links(const device LinkStruct *link_array [[ buffer(0) ]],
                                  device BillboardVertex *generated_vertices [[ buffer(1) ]],
                                  device uint32_t *generated_indices [[ buffer(2) ]],
                                  uint i [[ thread_position_in_grid ]],
                                  uint l [[ thread_position_in_threadgroup ]]) {
    
    constexpr int16_t vertices_per_link = 8;
    constexpr int16_t indices_per_link = 24;
    
    int32_t index = i * vertices_per_link;
    int32_t index_2 = i * indices_per_link;
    
    float3 atom_A = link_array[i].atom_A;
    float3 atom_B = link_array[i].atom_B;
    float3 cylinder_center = link_array[i].cylinder_center;
    float link_radius = link_array[i].link_radius;
    float link_radius_root = sqrt(link_radius);
    
    float2 direction_B_to_A = normalize(atom_A.xy - atom_B.xy);
    float2 direction_A_to_B = normalize(atom_B.xy - atom_A.xy);
    
    // MARK: - Vertices
    
    // Vertices of Atom A Face 0
    generated_vertices[index + 0].position = simd_float3(-direction_A_to_B.y * link_radius,
                                                         direction_A_to_B.x * link_radius,
                                                         -link_radius) + atom_B;
    generated_vertices[index + 0].billboard_world_center = cylinder_center;
    
    generated_vertices[index + 1].position = simd_float3(direction_A_to_B.y * link_radius,
                                                         -direction_A_to_B.x * link_radius,
                                                         -link_radius) + atom_B;
    generated_vertices[index + 1].billboard_world_center = cylinder_center;
    
    // Vertices of Atom B Face 0
    generated_vertices[index + 2].position = simd_float3(-direction_B_to_A.y * link_radius,
                                                         direction_B_to_A.x * link_radius,
                                                         -link_radius) + atom_A;
    generated_vertices[index + 2].billboard_world_center = cylinder_center;
    
    generated_vertices[index + 3].position = simd_float3(direction_B_to_A.y * link_radius,
                                                         -direction_B_to_A.x * link_radius,
                                                         -link_radius) + atom_A;
    generated_vertices[index + 3].billboard_world_center = cylinder_center;
    
    // Vertices of Atom A Face 1
    generated_vertices[index + 4].position = simd_float3(-direction_A_to_B.y * link_radius,
                                                         direction_A_to_B.x * link_radius,
                                                         link_radius) + atom_B;
    generated_vertices[index + 4].billboard_world_center = cylinder_center;
    
    generated_vertices[index + 5].position = simd_float3(direction_A_to_B.y * link_radius,
                                                         -direction_A_to_B.x * link_radius,
                                                         link_radius) + atom_B;
    generated_vertices[index + 5].billboard_world_center = cylinder_center;
    
    // Vertices of Atom B Face 1
    generated_vertices[index + 6].position = simd_float3(-direction_B_to_A.y * link_radius,
                                                         direction_B_to_A.x * link_radius,
                                                         link_radius) + atom_A;
    generated_vertices[index + 6].billboard_world_center = cylinder_center;
    
    generated_vertices[index + 7].position = simd_float3(direction_B_to_A.y * link_radius,
                                                         -direction_B_to_A.x * link_radius,
                                                         link_radius) + atom_A;
    generated_vertices[index + 7].billboard_world_center = cylinder_center;
    
    // MARK: - Indices
    
    // Indices of Face 0
    generated_indices[index_2 + 0] = 0 + index;
    generated_indices[index_2 + 1] = 1 + index;
    generated_indices[index_2 + 2] = 2 + index;
    
    generated_indices[index_2 + 3] = 2 + index;
    generated_indices[index_2 + 4] = 3 + index;
    generated_indices[index_2 + 5] = 0 + index;
    
    // Indices of Face 1
    generated_indices[index_2 + 6] = 4 + index;
    generated_indices[index_2 + 7] = 6 + index;
    generated_indices[index_2 + 8] = 5 + index;
    
    generated_indices[index_2 + 9] = 6 + index;
    generated_indices[index_2 + 10] = 4 + index;
    generated_indices[index_2 + 11] = 7 + index;
    
    // Indices of Face 2
    generated_indices[index_2 + 12] = 4 + index;
    generated_indices[index_2 + 13] = 0 + index;
    generated_indices[index_2 + 14] = 3 + index;
    
    generated_indices[index_2 + 15] = 3 + index;
    generated_indices[index_2 + 16] = 7 + index;
    generated_indices[index_2 + 17] = 4 + index;
    
    // Indices of Face 3
    generated_indices[index_2 + 18] = 5 + index;
    generated_indices[index_2 + 19] = 2 + index;
    generated_indices[index_2 + 20] = 1 + index;
    
    generated_indices[index_2 + 21] = 2 + index;
    generated_indices[index_2 + 22] = 5 + index;
    generated_indices[index_2 + 23] = 6 + index;
}
