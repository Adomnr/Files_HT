# Definitional proc to organize widgets for parameters.
proc init_gui { IPINST } {
  ipgui::add_param $IPINST -name "Component_Name"
  #Adding Page
  set Page_0 [ipgui::add_page $IPINST -name "Page 0"]
  ipgui::add_param $IPINST -name "IN_W" -parent ${Page_0}
  ipgui::add_param $IPINST -name "LIMIT" -parent ${Page_0}
  ipgui::add_param $IPINST -name "OUT_W" -parent ${Page_0}
  ipgui::add_param $IPINST -name "ROUND" -parent ${Page_0}
  ipgui::add_param $IPINST -name "SHIFT" -parent ${Page_0}


}

proc update_PARAM_VALUE.IN_W { PARAM_VALUE.IN_W } {
	# Procedure called to update IN_W when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.IN_W { PARAM_VALUE.IN_W } {
	# Procedure called to validate IN_W
	return true
}

proc update_PARAM_VALUE.LIMIT { PARAM_VALUE.LIMIT } {
	# Procedure called to update LIMIT when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.LIMIT { PARAM_VALUE.LIMIT } {
	# Procedure called to validate LIMIT
	return true
}

proc update_PARAM_VALUE.OUT_W { PARAM_VALUE.OUT_W } {
	# Procedure called to update OUT_W when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.OUT_W { PARAM_VALUE.OUT_W } {
	# Procedure called to validate OUT_W
	return true
}

proc update_PARAM_VALUE.ROUND { PARAM_VALUE.ROUND } {
	# Procedure called to update ROUND when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.ROUND { PARAM_VALUE.ROUND } {
	# Procedure called to validate ROUND
	return true
}

proc update_PARAM_VALUE.SHIFT { PARAM_VALUE.SHIFT } {
	# Procedure called to update SHIFT when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.SHIFT { PARAM_VALUE.SHIFT } {
	# Procedure called to validate SHIFT
	return true
}


proc update_MODELPARAM_VALUE.IN_W { MODELPARAM_VALUE.IN_W PARAM_VALUE.IN_W } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.IN_W}] ${MODELPARAM_VALUE.IN_W}
}

proc update_MODELPARAM_VALUE.SHIFT { MODELPARAM_VALUE.SHIFT PARAM_VALUE.SHIFT } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.SHIFT}] ${MODELPARAM_VALUE.SHIFT}
}

proc update_MODELPARAM_VALUE.ROUND { MODELPARAM_VALUE.ROUND PARAM_VALUE.ROUND } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.ROUND}] ${MODELPARAM_VALUE.ROUND}
}

proc update_MODELPARAM_VALUE.OUT_W { MODELPARAM_VALUE.OUT_W PARAM_VALUE.OUT_W } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.OUT_W}] ${MODELPARAM_VALUE.OUT_W}
}

proc update_MODELPARAM_VALUE.LIMIT { MODELPARAM_VALUE.LIMIT PARAM_VALUE.LIMIT } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.LIMIT}] ${MODELPARAM_VALUE.LIMIT}
}

