@tool
class_name QodotFGDFile
extends Resource

## A node used to to express a set of entity definitions that can be exproted

#psuedo-button to export
@export var export_file: bool:
	get:
		return export_file # TODOConverter40 Non existent get function 
	set(new_export_file):
		if new_export_file != export_file:
			do_export_file()
func do_export_file():
	if Engine.is_editor_hint() and get_fgd_classes().size() > 0:
				if target_folder.is_empty():
					print("Skipping export: No target folder")
					return

				if fgd_name == "":
					print("Skipping export: Empty FGD name")

				var fgd_file = target_folder + "/" + fgd_name + ".fgd"

				print("Exporting FGD to ", fgd_file)
				var file_obj := FileAccess.open(fgd_file, FileAccess.WRITE)
				file_obj.store_string(build_class_text())
				file_obj = null
@export var target_folder : String # (String, DIR, GLOBAL)
@export var fgd_name: String = "Qodot"
@export var base_fgd_files: Array[Resource] = [] # (Array, Resource)
@export var entity_definitions: Array[Variant] = [ # (Array, Resource)
	preload("res://addons/qodot/game_definitions/fgd/solid_classes/worldspawn_solid_class.tres"),
	preload("res://addons/qodot/game_definitions/fgd/solid_classes/group_solid_class.tres"),
	preload("res://addons/qodot/game_definitions/fgd/solid_classes/detail_solid_class.tres"),
	preload("res://addons/qodot/game_definitions/fgd/solid_classes/illusionary_solid_class.tres"),
	preload("res://addons/qodot/game_definitions/fgd/solid_classes/worldspawn_solid_class.tres"),
	preload("res://addons/qodot/game_definitions/fgd/base_classes/light_base_class.tres"),
	preload("res://addons/qodot/game_definitions/fgd/point_classes/light_point_class.tres"),
]

func build_class_text() -> String:
	var res : String = ""

	for base_fgd in base_fgd_files:
		res += base_fgd.build_class_text()

	var entities = get_fgd_classes()
	for ent in entities:
		if ent.qodot_internal:
			continue
		var ent_text = ent.build_def_text()
		res += ent_text
		if ent != entities[-1]:
			res += "\n"
	return res

#This getter does a little bit of validation. Providing only an array of non-null uniquely-named entity definitions
func get_fgd_classes() -> Array:
	var res : Array = []
	for cur_ent_def_ind in range(entity_definitions.size()):
		var cur_ent_def = entity_definitions[cur_ent_def_ind]
		if cur_ent_def == null:
			continue
		elif not (cur_ent_def is QodotFGDClass):
			printerr("Bad value in entity definition set at position %s! Not an entity defintion." % cur_ent_def_ind)
			continue
		res.append(cur_ent_def)
	return res

func get_entity_definitions() -> Dictionary:
	var res : Dictionary = {}

	for base_fgd in base_fgd_files:
		var fgd_res = base_fgd.get_entity_definitions()
		for key in fgd_res:
			res[key] = fgd_res[key]

	for ent in get_fgd_classes():
		if ent is QodotFGDPointClass or ent is QodotFGDSolidClass:
			var entity_def = ent.duplicate()
			var meta_properties := {}
			var class_properties := {}
			var class_property_descriptions := {}

			for base_class in _generate_base_class_list(entity_def):
				for meta_property in base_class.meta_properties:
					meta_properties[meta_property] = base_class.meta_properties[meta_property]

				for class_property in base_class.class_properties:
					class_properties[class_property] = base_class.class_properties[class_property]

				for class_property_desc in base_class.class_property_descriptions:
					class_property_descriptions[class_property_desc] = base_class.class_property_descriptions[class_property_desc]

			for meta_property in entity_def.meta_properties:
				meta_properties[meta_property] = entity_def.meta_properties[meta_property]

			for class_property in entity_def.class_properties:
				class_properties[class_property] = entity_def.class_properties[class_property]

			for class_property_desc in entity_def.class_property_descriptions:
				class_property_descriptions[class_property_desc] = entity_def.class_property_descriptions[class_property_desc]

			entity_def.meta_properties = meta_properties
			entity_def.class_properties = class_properties
			entity_def.class_property_descriptions = class_property_descriptions

			res[ent.classname] = entity_def
	return res

func _generate_base_class_list(entity_def : Resource, visited_base_classes = []) -> Array:
	var base_classes : Array = []
	
	visited_base_classes.append(entity_def.classname)
	
	# End recursive search if no more base_classes
	if len(entity_def.base_classes) == 0:
		return base_classes
	
	# Traverse up to the next level of hierarchy, if not already visited
	for base_class in entity_def.base_classes:
		if not base_class.classname in visited_base_classes:
			base_classes.append(base_class)
			base_classes += _generate_base_class_list(base_class, visited_base_classes)
		else:
			printerr(str("Entity '", entity_def.classname,"' contains cycle/duplicate to Entity '", base_class.classname, "'"))

	return base_classes
