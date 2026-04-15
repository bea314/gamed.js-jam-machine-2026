extends Node2D

var lado_Door : int # Tiene 4 formas - 1 ARRIBA / 2 DERECHA / 3 ABAJO / 4 IZQUERDA

# !TEST ESTO FUNCIONA PARA VER PRTESUPUESTO
@onready var presupuesto: Label = $Presupuesto

var Presupuesto_Room_ind : int 

func presupuesto_mark():
	presupuesto.text = str(Presupuesto_Room_ind)
