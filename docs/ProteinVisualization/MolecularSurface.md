# Creating the molecular surface

Molecular surfaces are one of the most common visual representations in a protein visualizer tool. But how are they generated? Apparently, someone was crazy enough to devise an **analytic** way of computing the surface. It's even called a _Conolly_ surface sometimes, in the name of the person who thought of if.

Thankfully, there's also a numerical approach. It's explained in some detail in Xu D, Zhang Y, _Generating Triangulated Macromolecular Surfaces by Euclidean Distance Transform_, but the explanation waves over some important implementation details. Here's how I _think_ it's made:

### Step 1

First we need to compute the solvent-accessible surface (SAS). We generate one sphere for each atom, where the radius is the Van der Waals radius + the radius of a water molecule, 1.4 Å. This is because we want to emulate the surface that is accessible for probe of a certain radius (in this case a water molecule). Then we remove all points inside other spheres, so we end up with a surface, the solvent-accessible surface. The **center** of the probe molecule could reach any point of this surface, but no further.

This spheres would be represented as a collection of points in the computer (we don't need triangles yet).

### Step 2

For the molecular surface, we want the compute the surface that contains the points of the molecule that could be touched by a solvent molecule (its **outermost** part, not the center). To do this, we need to compute something called the signed Euclidean Distance Transform, or sEDT, for all points inside a grid. That's because the points we want have something in common: they are all at the same distance from the SAS, equal to the radius of the probe, 1.4 Å.

So we create a uniform 3D grid in the bounding box around the protein, and compute the signed Euclidean Distance Transformation to the SAS for all points in this 3D grid. That is, the distance between the grid point and the nearest sphere point from the SAS. The grid points at 1.4 Å from the SAS are the points that will make our molecular surface.

How many points would this 3D grid need? Well, it does depend on the size of the protein, but apparently, not that many! The maximum resolution in the cited paper (from 2009) was a grid of 128x128x128 voxels. A grid of 256x256x256 may be achievable now, for a smoother surface.

### Step 3

Finally, we need to join this points in triangles to make a mesh and display the surface.  How do we do this? Using a Marching Cubes algorithm. And that's about it. Easy!



## Optimizations

This code needs to be reasonably fast. After all, we don't want to wait for too long before being able to visualize the protein. And other tools make this representation really fast. Some  ideas:

* Use Metal for parallel computing in the GPU. This one is a must, obviously.
* Fastest way to generate sphere points in Step 1? Maybe do a table look-up of these points from a unitary sphere pre computed at compile time, and transform to the coordinates of the new sphere.
* Remove non-surface points (points inside other spheres) in a different compute pass than the generation.
* Spheres could be distributed in a k-tree, to (dramatically) speed up finding neighbours. This could be helpful in many steps (finding which SAS points are inside other spheres for Step 1, and finding closest SAS point for a given 3D grid point in Step 2, maybe even for the Marching Cubes).
