extends Node3D

# Variable prenant un objet 3D sur le quel la caméra va se centrer
@export var target : Node3D

# Variable gardant en mémoire la première cible qui lui a été donné, afin de pouvoir s'y repositioner par défaut
@export var initialTarget : Node3D

# Point de l'espace au quel se trouve la caméra relativement à sa cible.
var offset := Vector3.ZERO

# Variable gardant en mémoire la position de décalage qui lui a été donné, afin de pouvoir s'y repositioner par défaut
@onready var initialOffset := global_position-target.global_position

# Tableau dont les indices correspondent chacun à un click différent de la souris 
# Indiquant si celui-ci est préssé ou non.
var mouse_buttons := [false, false, false] # Gauche, Droite, Centre





# Fonction appelé lorsqu'une touche quelconque est appuyé
# Elle vérifie qu'il s'agit d'un bouton de la souris dont l'indice correspond à ceux du tableau, change les valeures booléennes en fonction de cela et appel la fonction update.
func _unhandled_input(event):
	if (event is InputEventMouseButton ) :
		var mouse_button = event as InputEventMouseButton
		if mouse_button.button_index-1 in range(3) :
			mouse_buttons[mouse_button.button_index-1] = mouse_button.is_pressed()
	update(event)


# Fonction appellé à chaque frame. 'delta' est le temps s'étant écoulé depuis la dernière frame.
# Elle remet ses valeures initiales si jamais le pointeur vers sa cible a été libéré de la mémoire.
# Elle se déplace ensuite de manière interpolée vers la position qui est celle de sa cible puis d'un décalage relatif à cette cible d'une position "offset"
func _process(delta) :
	if target==null : 
		target = initialTarget
		offset=initialOffset
	get_parent().position=target.global_position
	position = position.move_toward(offset, delta*30);


# Fonction métant à jour la position de la caméra en fonction des touches appuyés. 
# Elle eloigne ou rapproche la caméra si la roulette est utilisée, pivote si le clique gauche est maintenu préssé et tourne autour de la cible si le clique gauche est appuyé
func update(event) :
	if (event is InputEventMouseButton ) :
		var mouse_button = event as InputEventMouseButton
		offset.z -= ((0.2 if mouse_button.button_index==4 else 0.) + (-0.2 if mouse_button.button_index==5 else 0.))
		offset.z = max(offset.z, 0)
		
	if (event is InputEventMouseMotion) :
		var mouse_motion = event as InputEventMouseMotion
		if abs(mouse_motion.relative.x)>200 or abs(mouse_motion.relative.y)>200 : return
	
		if mouse_buttons[1] :
			get_parent_node_3d().rotate(global_transform.basis.y,-3*event.relative.x/1000.)
			get_parent_node_3d().rotate(global_transform.basis.x, -3*event.relative.y/1000.)
			
		if mouse_buttons[0] :
			rotate(transform.basis.x.normalized(), -3*event.relative.y/1000.)
			rotate(transform.basis.y.normalized(),-3*event.relative.x/1000.)



# Fonction appelé automatiquement quand le noeud racine est instancié dans la scène pour la première fois.
# Garde en mémoire les valeures initiales de offset et de la cible.
func _ready():
	offset=initialOffset
	initialTarget=target


