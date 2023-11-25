//
//  ComputeAmbientOcclusion.metal
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 29/4/23.
//

#include <metal_stdlib>
#include "../SharedDataStructs.h"

using namespace metal;
using namespace raytracing;

kernel void compute_occlusion_texture(instance_acceleration_structure acceleration_structure [[ buffer(0) ]],
                                      intersection_function_table<instancing> functionTable [[buffer(1)]],
                                      device simd_float3 *atom_positions [[ buffer(2) ]],
                                      device uint16_t *atom_types [[ buffer(3) ]],
                                      constant AtomRadii &atom_radii [[buffer(4)]],
                                      const texture3d<float, access::read_write>  ambient_occlusion [[ texture(0) ]],
                                      uint3 tid [[ thread_position_in_grid ]]) {
    // Create the ray
    ray ray;
        
    // Create intersector
    intersector<instancing> intersector;
    
    // Intersect with scene
    intersection_result<instancing> intersection;
    intersection = intersector.intersect(ray, acceleration_structure, functionTable);
}

struct BoundingBoxIntersectionResult {
    bool continue_search [[ continue_search ]];
    bool accept [[accept_intersection]];
    float distance [[distance]];
};

// MARK: - Sphere intersection

[[intersection(bounding_box)]]
BoundingBoxIntersectionResult sphere_intersection_function(float3 origin [[origin]],
                                                           float3 direction [[direction]],
                                                           float minDistance [[min_distance]],
                                                           float maxDistance [[max_distance]],
                                                           uint primitiveIndex [[primitive_id]],
                                                           device Sphere *spheres [[buffer(0)]]) {
    // Get the actual sphere enclosed in this bounding box.
    Sphere sphere = spheres[primitiveIndex];
    
    // Check for intersection between the ray and sphere mathematically.
    float3 oc = origin - sphere.origin;

    float a = dot(direction, direction);
    float b = 2 * dot(oc, direction);
    float c = dot(oc, oc) - sphere.radius * sphere.radius;

    float disc = b * b - 4 * a * c;

    BoundingBoxIntersectionResult intersection_result;
    
    // No need to find the closest intersection: for ambient occlusion it's enough to check
    // whether the ray hits anything or not.
    intersection_result.continue_search = false;

    if (disc <= 0.0f) {
        // If the ray missed the sphere, return false.
        intersection_result.accept = false;
    } else {
        // Otherwise, compute the intersection distance.
        intersection_result.distance = (-b - sqrt(disc)) / (2 * a);

        // The intersection function must also check whether the intersection distance is
        // within the acceptable range. Intersection functions do not run in any particular order,
        // so the maximum distance may be different from the one passed into the ray intersector.
        intersection_result.accept = intersection_result.distance >= minDistance
            && intersection_result.distance <= maxDistance;
    }

    return intersection_result;
}
