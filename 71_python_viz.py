import matplotlib.pyplot as plt
from mpl_toolkits.mplot3d import Axes3D


for distribution in qqq:
  fig = plt.figure()
  ax = fig.add_subplot(projection='3d')
  ax.plot_surface(x,y,distribution,cmap='viridis',linewidth=0)
  ax.set_xlabel('X axis')
  ax.set_ylabel('Y axis')
  ax.set_zlabel('Z axis')
  plt.show()
