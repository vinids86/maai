class_name ActionCostValidator
extends Node

var stamina_component: StaminaComponent
var focus_component: FocusComponent

func _ready() -> void:
	stamina_component = owner.get_node_or_null("StaminaComponent")
	focus_component = owner.get_node_or_null("FocusComponent")
	print(stamina_component, focus_component)

func try_pay_costs(profile: Resource) -> bool:
	if not profile:
		return false
		
	var stamina_cost: float = 0.0
	if "stamina_cost" in profile:
		stamina_cost = profile.stamina_cost

	var focus_cost: int = 0
	if "focus_cost" in profile:
		focus_cost = profile.focus_cost

	if stamina_component and not stamina_component.has_enough_stamina(stamina_cost):
		return false
	
	if focus_component and not focus_component.has_enough_focus(focus_cost):
		return false

	if stamina_component:
		stamina_component.consume_stamina(stamina_cost)
	
	if focus_component:
		focus_component.consume_focus(focus_cost)
		
	return true
