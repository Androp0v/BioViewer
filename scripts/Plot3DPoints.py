import matplotlib.pyplot as plt
import numpy as np
from mpl_toolkits.mplot3d import Axes3D

fig = plt.figure()
ax = Axes3D(fig)

points = np.array([]) # Points are copy-pasted here when debugging

print(np.shape(points))
ax.scatter(points[:,0], points[:,1], points[:,2])
plt.show()