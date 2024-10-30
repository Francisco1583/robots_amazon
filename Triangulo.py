import pygame
from pygame.locals import *
import numpy as np
import math
from OpMat import OpMat
from OpenGL.GL import *
from OpenGL.GLU import *
from OpenGL.GLUT import *

class Triangulo:
    def __init__(self,model_m,):
        self.pointsT = [[0.0,1.0,1.0],[-1.0,-1.0,1.0],[1.0,-1.0,1.0]]
        self.pointsR =[[-1.0,2.0,1.0],[1.0,2.0,1.0],[1,-2,1],[-1,-2,1]]
        self.pointsC =[[-1.0,1.0,1.0],[1.0,1.0,1.0],[1,-1,1],[-1,-1,1]]
        self.opera = model_m
        self.r = 0.0
        self.g = 1.0
        self.b = 0.0
        self.deg = 0
        self.Robot_orientation = 90
        self.delt_deg = 10
        self.girol = 0
        self.giror = 0
        self.pos_x = 0
        self.pos_y = 0
        self.ac_boxDes = 0
        self.ac_boxCarg = 0
        # 1 en ejecución de alguna acción
        # 0 sin acción a ejecutar
        self.mode = 0
        self.scl = 1
        self.trans_box = -50
        self.delt_trans = 5
        self.transUp = 0
        self.transDown = 0
        self.carga = 0

    def setCarga(self,carga):
        self.carga = carga
        
    def setMode(self):
        self.mode = 1

    def setXY(self,x,y):
        self.pos_x = x
        self.pos_y = y

    def unsetMode(self):
        self.mode = 0
        
    def setGirol(self,deg):
        self.girol = deg
        
    def setGiror(self,deg):
        self.giror = deg

    def seTransUp(self,delt_trans):
        self.transUp = delt_trans

    def seTransDown(self,delt_trans):
        self.transDown = delt_trans
    
        
    def setScl(self,scl):
        self.scl = scl
        self.trans_box = -scl

    def setAc_boxDes(self):
        self.ac_boxDes = -round((self.scl)*2)

    def setAc_boxCarg(self):
        self.ac_boxCarg = round((self.scl)*2)

    def setColor(self,r,g,b):
        self.r = r
        self.g = g
        self.b = b

    def bresenhan(self,x1,y1,x0,y0):
        if abs(y1-y0) > abs(x1-x0):
            dx = y1 - y0
            dy = x1 - x0
            x = y0
            y = x0
            cambio = y1
            y1 = x1
            x1 = cambio
            caso = 0
        else:
            dy = y1 - y0
            dx = x1 - x0
            x = x0
            y = y0
            caso = 1
        signX = round(dx/(abs(dx)+0.01))
        signY = round(dy/(abs(dy)+0.01))
        dy = abs(dy)
        dx = abs(dx)
        E = 2*dy
        NE = 2*(dy-dx)
        Dinit = 2*dy - dx
        if caso == 0:
            glColor3f(self.r, self.g,self.b)
            glBegin(GL_POINTS)
            glVertex2f(y,x)
            glEnd()
            glLineWidth(1.0)
        else:
            glColor3f(self.r, self.g,self.b)
            glBegin(GL_POINTS)
            glVertex2f(x,y)
            glEnd()
            glLineWidth(1.0)

        while x-x1 != 0 or y-y1 != 0:
            x = x + signX
            if Dinit <= 0:
                Dinit = Dinit + E

            else:
                y = y + signY
                Dinit = Dinit + NE

            if caso == 0:
                glColor3f(self.r, self.g,self.b)
                glBegin(GL_POINTS)
                glVertex2f(y,x)
                glEnd()
                glLineWidth(1.0)
            else:
                glColor3f(self.r, self.g,self.b)
                glBegin(GL_POINTS)
                glVertex2f(x,y)
                glEnd()
                glLineWidth(1.0)

    def render(self,points):
        triangule_cords = np.array(points)
        new_triangule_cords = self.opera.mult_Points(triangule_cords)
        self.bresenhan(round(new_triangule_cords[0][0]),round(new_triangule_cords[0][1]),round(new_triangule_cords[1][0]),round(new_triangule_cords[1][1]))
        self.bresenhan(round(new_triangule_cords[1][0]),round(new_triangule_cords[1][1]),round(new_triangule_cords[2][0]),round(new_triangule_cords[2][1]))
        self.bresenhan(round(new_triangule_cords[2][0]),round(new_triangule_cords[2][1]),round(new_triangule_cords[3][0]),round(new_triangule_cords[3][1]))
        self.bresenhan(round(new_triangule_cords[3][0]),round(new_triangule_cords[3][1]),round(new_triangule_cords[0][0]),round(new_triangule_cords[0][1]))

    def up(self):
        rad = math.radians(self.Robot_orientation)  
        dx = self.delt_trans * math.cos(rad) 
        dy = self.delt_trans * math.sin(rad)
        self.pos_x = self.pos_x + dx
        self.pos_y = self.pos_y + dy

    def down(self):
        rad = math.radians(self.Robot_orientation)  
        dx = self.delt_trans * math.cos(rad) 
        dy = self.delt_trans * math.sin(rad)
        self.pos_x = self.pos_x - dx
        self.pos_y = self.pos_y - dy

    def cons_up(self):
        if self.transUp != 0:
            self.mode = 1
            rad = math.radians(self.Robot_orientation)  
            dx = self.delt_trans * math.cos(rad) 
            dy = self.delt_trans * math.sin(rad)
            self.pos_x = self.pos_x + dx
            self.pos_y = self.pos_y + dy
            self.transUp = self.transUp - self.delt_trans
            if self.transUp == 0:
                self.mode = 0
                
    def cons_down(self):
        if self.transDown != 0:
            self.mode = 1
            rad = math.radians(self.Robot_orientation)  
            dx = self.delt_trans * math.cos(rad) 
            dy = self.delt_trans * math.sin(rad)
            self.pos_x = self.pos_x - dx
            self.pos_y = self.pos_y - dy
            self.transDown = self.transDown - self.delt_trans
            if self.transDown == 0:
                self.mode = 0
            
                

    def left(self):
        if self.girol != 0:
            self.mode = 1
            self.deg = (self.deg + self.delt_deg) % 360
            self.Robot_orientation = (self.Robot_orientation + self.delt_deg) % 360
            self.girol = self.girol - self.delt_deg
            if self.girol == 0:
                self.mode = 0


    def right(self):
        if self.giror != 0:
            self.mode = 1
            self.deg = (self.deg - self.delt_deg) % 360
            self.Robot_orientation = (self.Robot_orientation - self.delt_deg) % 360
            self.giror = self.giror + self.delt_deg
            if self.giror == 0:
                self.mode = 0

    def descarga(self):
        if self.ac_boxDes != 0 and self.girol == 0:
            self.trans_box = (self.trans_box - self.delt_trans)
            self.ac_boxDes = self.ac_boxDes + self.delt_trans
            if self.ac_boxDes == 0:
                self.mode = 0
            
    def carga(self):
        if self.ac_boxCarg!= 0 and self.girol == 0:
            self.trans_box = (self.trans_box + self.delt_trans)
            self.ac_boxCarg = self.ac_boxCarg - self.delt_trans
            if self.ac_boxDes == 0:
                self.mode = 0
        

    def robot(self):
        self.opera.push()
        #self.opera.rotation(180)
        self.opera.translate(self.pos_x,self.pos_y)
        self.opera.rotation(self.deg)
        #caja
        if self.carga == 1:
            self.opera.push()
            self.opera.translate(0,self.trans_box)
            self.opera.scale(round((self.scl)/1.53),round((self.scl)/1.53))
            self.render(self.pointsC.copy())
            self.opera.pop()
        #rueda
        self.opera.push()
        self.opera.translate(-round((self.scl)/0.769),round((self.scl)/0.7142))
        self.opera.scale(round((self.scl)/3.33),round((self.scl)/3.33))
        self.render(self.pointsR.copy())
        self.opera.pop()
        #rueda2
        self.opera.push()
        self.opera.translate(round((self.scl)/0.769),round((self.scl)/0.7142))
        self.opera.scale(round((self.scl)/3.33),round((self.scl)/3.33))
        self.render(self.pointsR.copy())
        self.opera.pop()
        #rueda3
        self.opera.push()
        self.opera.translate(-round((self.scl)/0.769),-round((self.scl)/0.7142))
        self.opera.scale(round((self.scl)/3.33),round((self.scl)/3.33))
        self.render(self.pointsR.copy())
        self.opera.pop()
        #rueda4
        self.opera.push()
        self.opera.translate(round((self.scl)/0.769),-round((self.scl)/0.7142))
        self.opera.scale(round((self.scl)/3.33),round((self.scl)/3.33))
        self.render(self.pointsR.copy())
        self.opera.pop()
        
        self.opera.scale(self.scl,self.scl)
        self.render(self.pointsR.copy())
        self.opera.pop()
        self.left()
        self.right()
        self.cons_up()
        self.cons_down()

    def cuadrado(self,x,y,sx,sy):
        self.opera.push()
        self.opera.translate(x,y)
        self.opera.scale(sx,sy)
        self.render(self.pointsC.copy())
        self.opera.pop()
