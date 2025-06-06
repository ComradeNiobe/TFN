#define OPTION_RENAME "Rename"
#define OPTION_DESCRIPTION "Description"
#define OPTION_RESET "Reset"

/**
 * Renaming tool element
 *
 * When using this tool on an object with UNIQUE_RENAME,
 * lets the user rename/redesc it.
 */
/datum/element/tool_renaming

/datum/element/tool_renaming/Attach(datum/target)
	. = ..()
	if(!isitem(target))
		return ELEMENT_INCOMPATIBLE

	RegisterSignal(target, COMSIG_ITEM_ATTACK_OBJ, PROC_REF(attempt_rename))

/datum/element/tool_renaming/Detach(datum/source)
	. = ..()
	UnregisterSignal(source, COMSIG_ITEM_ATTACK_OBJ)

/datum/element/tool_renaming/proc/attempt_rename(datum/source, mob/living/user, atom/interacting_with, list/modifiers)
	SIGNAL_HANDLER

	if(!isobj(interacting_with))
		return NONE

	var/obj/renamed_obj = interacting_with

	if(!(renamed_obj.obj_flags & UNIQUE_RENAME))
		return NONE

	INVOKE_ASYNC(src, PROC_REF(async_rename), user, renamed_obj)
	return TRUE

/datum/element/tool_renaming/proc/async_rename(mob/living/user, obj/renamed_obj)
	var/custom_choice = tgui_input_list(user, "What would you like to edit?", "Customization", list(OPTION_RENAME, OPTION_DESCRIPTION, OPTION_RESET))
	if(QDELETED(renamed_obj) || !user.canUseTopic(renamed_obj) || isnull(custom_choice))
		return

	switch(custom_choice)
		if(OPTION_RENAME)
			var/old_name = renamed_obj.name
			var/input = tgui_input_text(user, "What do you want to name [renamed_obj]?", "Object Name", "[old_name]", MAX_NAME_LEN)
			if(QDELETED(renamed_obj) || !user.canUseTopic(renamed_obj))
				return
			if(input == old_name || !input)
				to_chat(user, span_notice("You changed [renamed_obj] to... well... [renamed_obj]."))
				return
			renamed_obj.AddComponent(/datum/component/rename, input, renamed_obj.desc)
			to_chat(user, span_notice("You have successfully renamed \the [old_name] to [renamed_obj]."))
			ADD_TRAIT(renamed_obj, TRAIT_WAS_RENAMED, RENAMING_TOOL_LABEL_TRAIT)
			renamed_obj.update_icon()

		if(OPTION_DESCRIPTION)
			var/old_desc = renamed_obj.desc
			var/input = tgui_input_text(user, "Describe [renamed_obj]", "Description", "[old_desc]", MAX_DESC_LEN)
			if(QDELETED(renamed_obj) || !user.canUseTopic(renamed_obj))
				return
			if(input == old_desc || !input)
				to_chat(user, span_notice("You decide against changing [renamed_obj]'s description."))
				return
			renamed_obj.AddComponent(/datum/component/rename, renamed_obj.name, input)
			to_chat(user, span_notice("You have successfully changed [renamed_obj]'s description."))
			ADD_TRAIT(renamed_obj, TRAIT_WAS_RENAMED, RENAMING_TOOL_LABEL_TRAIT)
			renamed_obj.update_icon()

		if(OPTION_RESET)
			qdel(renamed_obj.GetComponent(/datum/component/rename))
			to_chat(user, span_notice("You have successfully reset [renamed_obj]'s name and description."))
			REMOVE_TRAIT(renamed_obj, TRAIT_WAS_RENAMED, RENAMING_TOOL_LABEL_TRAIT)
			renamed_obj.update_icon()

#undef OPTION_RENAME
#undef OPTION_DESCRIPTION
#undef OPTION_RESET
