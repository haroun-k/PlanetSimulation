extends Label

# Fonction appellé à chaque frame. 'delta' est le temps s'étant écoulé depuis la dernière frame.
# Elle affiche en information au dessus de celui-ci, la valeure séléctionnée avec le slider. 
func _process(delta):
	set_text( "Biais de temperature : " +str($"%tempSlider".value) + "°" )
