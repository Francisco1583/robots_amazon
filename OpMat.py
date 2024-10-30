import numpy as np
import math

class OpMat:

    def __init__(self):
        self.init_matrix = np.array(
              [[1.0,0.0,0.0],
               [0.0,1.0,0.0],
               [0.0,0.0,1.0]])
        self.pila = []

    def translate(self,tx,ty):
        translation_m =  np.array(
              [[1.0,0.0,tx],
               [0.0,1.0,ty],
               [0.0,0.0,1.0]])
        self.init_matrix = self.init_matrix @ translation_m

    def scale(self,sx,sy):
        scale_m =  np.array(
              [[sx,0.0,0.0],
               [0.0,sy,0.0],
               [0.0,0.0,1.0]])
        self.init_matrix = self.init_matrix @ scale_m

    def rotation(self,deg):
        deg = math.radians(deg)
        rotate_m = np.array(
              [[math.cos(deg),-math.sin(deg),0.0],
               [math.sin(deg),math.cos(deg),0.0],
               [0.0,0.0,1.0]])
        self.init_matrix = self.init_matrix @ rotate_m

    def push(self):
        self.pila.append(self.init_matrix.copy())

    def pop(self):
        if self.pila:
            self.init_matrix = self.pila[-1].copy()
            self.pila.pop()

    def mult_Points(self,points):
        #triangule_cords = np.array(points)
        triangule_cords = points
        new_triangule_cords = [self.init_matrix @ x for x in triangule_cords]
        new_triangule_cords = [x[:-1] for x in new_triangule_cords]
        return new_triangule_cords
        
    def imprimir_init(self):
        print(self.init_matrix)
