extends StaticBody2D

func Collicion_Mode(IS_ACTIVE : bool): #ACTIVA Y DESACTIVA COLLICIONES
	# WARNING : SIRVE PARA LA OPTIMISACION
	if IS_ACTIVE:
		for i in self:
			i.disabled = false
	else:
		for i in self:
			i.disabled = true
