class_name SequenceSkill
extends BaseSkill

@export var skill_phases: Array[AttackSet]

func _do_execute(owner: Node, state_machine: StateMachine):
	var skill_combo_comp = owner.find_child("SkillComboComponent")
	if not skill_combo_comp:
		push_error("SequenceSkill: SkillComboComponent não encontrado no owner.")
		return

	var next_phase = skill_combo_comp.get_next_skill_phase(self)
	if next_phase:
		state_machine.on_sequence_skill_pressed(next_phase)
