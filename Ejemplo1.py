import pygame
from pygame.locals import *
import numpy as np
import math
import requests
import sys
sys.path.append('..')
# Cargamos las bibliotecas de OpenGL
from OpenGL.GL import *
from OpenGL.GLU import *
from OpenGL.GLUT import *
from OpMat import OpMat
from Triangulo import Triangulo

URL_BASE = "http://localhost:8000"
r = requests.post(URL_BASE+ "/simulations", allow_redirects=False)
datos = r.json()
robots = datos["robots"]
trees = datos["trees"]
print(datos)
LOCATION = datos["Location"]

opera = OpMat()
ts = []
for i in range (5):
    ts.append(Triangulo(opera))
    ts[i].setScl(10)
t1 = Triangulo(opera)
t1.setScl(10)
#t2 = Triangulo(opera)
pygame.init()


screen_width = 900
screen_height = 600

#Variables para dibujar los ejes del sistema
X_MIN=-500
X_MAX=500
Y_MIN=-500
Y_MAX=500

def Axis():
    glShadeModel(GL_FLAT)
    glLineWidth(3.0)
    #X axis in red
    glColor3f(1.0,0.0,0.0)
    glBegin(GL_LINES)
    glVertex2f(X_MIN,0.0)
    glVertex2f(X_MAX,0.0)
    glEnd()
    #Y axis in green
    glColor3f(0.0,1.0,0.0)
    glBegin(GL_LINES)
    glVertex2f(0.0,Y_MIN)
    glVertex2f(0.0,Y_MAX)
    glEnd()
    glLineWidth(1.0)


def cuadrado():
    #global trees
    global opera
    global deg
    response = requests.get(URL_BASE + LOCATION)
    datos = response.json()
    opera.push()
    trees = datos["trees"]
    robots = datos["robots"]
    for robot in robots:
        tupone = robot["previous_pos"][0]
        tuptwo = robot["previous_pos"][1]
        if robot["regreso"] == 1:
            ts[robot["who"]-1].setColor(0,0,1)
            #t1.setColor(0,0,1)
        else:
            ts[robot["who"]-1].setColor(0,1,0)
            #t1.setColor(0,1,0)
        opera.push()
        if robot["rotation_direction"] == "LEFT":
            if ts[robot["who"]-1].mode == 0:
            #if t1.mode == 0:
                ts[robot["who"]-1].setGirol(90)
                #t1.setGirol(90)
        elif robot["rotation_direction"] == "RIGHT":
            if ts[robot["who"]-1].mode == 0:
            #if t1.mode == 0:
                ts[robot["who"]-1].setGiror(-90)
                #t1.setGiror(-90)
        elif robot["rotation_direction"] == "DOWN":
            if ts[robot["who"]-1].mode == 0:
            #if t1.mode == 0:
                ts[robot["who"]-1].setGirol(180)
                #t1.setGiror(-180)
            
        #opera.translate((robot["pos"][0]* 40)-900,-((robot["pos"][1] * 40)-900))
        if robot["timer"] == 0:
            ts[robot["who"]-1].setXY((robot["previous_pos"][0]* 40)-900,-((robot["previous_pos"][1] * 40)-900))
            #t1.setXY((robot["previous_pos"][0]* 40)-900,-((robot["previous_pos"][1] * 40)-900))
            
            #opera.translate((robot["previous_pos"][0]* 40)-900,-((robot["previous_pos"][1] * 40)-900))
        ts[robot["who"]-1].robot()
        #t1.robot()
        #t1.cuadrado((robot["pos"][0]* 40)-900,-((robot["pos"][1] * 40)-900),15,15)
        opera.pop()
    for tree in trees:   
        if tree["num"] < 5:
            t1.setColor(0,1,0)
        else:
            t1.setColor(1,0,0)
        opera.push()
        t1.cuadrado((tree["pos"][0]* 40)-900,-((tree["pos"][1] * 40)-900),15,15)
        opera.pop()
    opera.pop()
    


def display():
    global opera
    global deg
    opera.push()
    #opera.translate((robots[3]["pos"][0]* 40)-900,-((robots[3]["pos"][1] * 40)-900))
    t1.robot()
    opera.pop()

def init():
    screen = pygame.display.set_mode(
        (screen_width, screen_height), DOUBLEBUF | OPENGL)
    pygame.display.set_caption("OpenGL: ejes 2D")

    glMatrixMode(GL_PROJECTION)
    glLoadIdentity()
    #gluOrtho2D(-450,450,-300,300)
    gluOrtho2D(-1350,1350,-900,900)
    glMatrixMode(GL_MODELVIEW)
    glLoadIdentity()
    glClearColor(0,0,0,0)
    #OPCIONES: GL_LINE, GL_POINT, GL_FILL
    glPolygonMode(GL_FRONT_AND_BACK, GL_LINE)
    glShadeModel(GL_FLAT)

# código principal ---------------------------------
init()

done = False
while not done:
    for event in pygame.event.get():
        if event.type == pygame.QUIT:
            done = True
        if event.type == pygame.KEYDOWN:
            if event.key == pygame.K_l:
                #t1.up()
                print("Presionando tecla l")
    
    keys = pygame.key.get_pressed()
    if keys[pygame.K_w]:
        #t1.up()
        if t1.mode == 0:
            t1.seTransUp((t1.scl)*2)
        print("Manteniendo presionada la tecla w")
    elif keys[pygame.K_s]:
        if t1.mode == 0:
            t1.seTransDown((t1.scl)*2)
        print("Manteniendo presionada la tecla s")
    elif keys[pygame.K_a]:
        if t1.mode == 0:
            t1.setGirol(90)
    elif keys[pygame.K_d]:
        if t1.mode == 0:
            t1.setGiror(-90)
    elif keys[pygame.K_q]:
        print("Manteniendo presionada la tecla q")
        if t1.ac_boxDes == 0 and t1.trans_box == -round(t1.scl):
            print("entra")
            t1.setAc_boxDes()
            t1.setGirol(180)
    elif keys[pygame.K_e]:
        print("Manteniendo presionada la tecla e")
        if t1.ac_boxCarg == 0 and t1.trans_box == -(round((t1.scl)*2)+t1.scl):
            print("entra")
            t1.setAc_boxCarg()
            t1.setGirol(180)

    glClear(GL_COLOR_BUFFER_BIT)
    #Axis()
    #display()
    cuadrado()
    pygame.display.flip()
    pygame.time.wait(16)
    # 60 fps = 16
    

pygame.quit()
