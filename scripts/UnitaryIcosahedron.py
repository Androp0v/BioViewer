import numpy as np

# Program flags
addRadiusAndPosition = False

# Create empty list to store icosahedron points
icosahedronPoints = []

# Icosahedron parameter
t = ( 1.0 + np.sqrt(5.0) ) / 2.0

# Add all icosahedron vertices
icosahedronPoints.append( np.array( (-1, t, 0) ))
icosahedronPoints.append( np.array( (1, t, 0) ))
icosahedronPoints.append( np.array( (-1, -t, 0) ))
icosahedronPoints.append( np.array( (1, t, 0) ))

icosahedronPoints.append( np.array( (0, -1, t) ))
icosahedronPoints.append( np.array( (0, 1, t) ))
icosahedronPoints.append( np.array( (0, -1, -t) ))
icosahedronPoints.append( np.array( (0, 1, -t) ))

icosahedronPoints.append( np.array( (t, 0, -1) ))
icosahedronPoints.append( np.array( (t, 0, 1) ))
icosahedronPoints.append( np.array( (-t, 0, -1) ))
icosahedronPoints.append( np.array( (-t, 0, 1) ))

# Normalice vertices to the unitary sphere (so it has a radius of 1)
for i in range(len(icosahedronPoints)):
    icosahedronPoints[i] /= np.sqrt(icosahedronPoints[i][0]**2 
                                    + icosahedronPoints[i][1]**2 
                                    + icosahedronPoints[i][2]**2)


##### PRINTING RESULTS #####

if addRadiusAndPosition:
    # Print results ready to copy/paste in the Metal kernel function body
    for index, icosahedronVertex in enumerate(icosahedronPoints):
        print("generatedSpherePoints[i+" 
            + str(index) + "] = simd_float3("
            + str(icosahedronVertex[0]) + ", "
            + str(icosahedronVertex[1]) + ", "
            + str(icosahedronVertex[2]) + ")"
            + " * radius + position;")
else:  
    # Print prettier results for the console 
    for index, icosahedronVertex in enumerate(icosahedronPoints):
        print("Vertex " + str(index) + " = "
            + str(icosahedronVertex[0]) + ", "
            + str(icosahedronVertex[1]) + ", "
            + str(icosahedronVertex[2]))

