# Definitional proc to organize widgets for parameters.
proc init_gui { IPINST } {
  ipgui::add_param $IPINST -name "Component_Name"
  #Adding Page
  set Page_0 [ipgui::add_page $IPINST -name "Page 0"]
  ipgui::add_param $IPINST -name "AUDIO_W" -parent ${Page_0}
  ipgui::add_param $IPINST -name "AVG_LOG2" -parent ${Page_0}
  ipgui::add_param $IPINST -name "MAG_W" -parent ${Page_0}


}

proc update_PARAM_VALUE.AUDIO_W { PARAM_VALUE.AUDIO_W } {
	# Procedure called to update AUDIO_W when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.AUDIO_W { PARAM_VALUE.AUDIO_W } {
	# Procedure called to validate AUDIO_W
	return true
}

proc update_PARAM_VALUE.AVG_LOG2 { PARAM_VALUE.AVG_LOG2 } {
	# Procedure called to update AVG_LOG2 when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.AVG_LOG2 { PARAM_VALUE.AVG_LOG2 } {
	# Procedure called to validate AVG_LOG2
	return true
}

proc update_PARAM_VALUE.MAG_W { PARAM_VALUE.MAG_W } {
	# Procedure called to update MAG_W when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.MAG_W { PARAM_VALUE.MAG_W } {
	# Procedure called to validate MAG_W
	return true
}


proc update_MODELPARAM_VALUE.MAG_W { MODELPARAM_VALUE.MAG_W PARAM_VALUE.MAG_W } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.MAG_W}] ${MODELPARAM_VALUE.MAG_W}
}

proc update_MODELPARAM_VALUE.AUDIO_W { MODELPARAM_VALUE.AUDIO_W PARAM_VALUE.AUDIO_W } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.AUDIO_W}] ${MODELPARAM_VALUE.AUDIO_W}
}

proc update_MODELPARAM_VALUE.AVG_LOG2 { MODELPARAM_VALUE.AVG_LOG2 PARAM_VALUE.AVG_LOG2 } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.AVG_LOG2}] ${MODELPARAM_VALUE.AVG_LOG2}
}

