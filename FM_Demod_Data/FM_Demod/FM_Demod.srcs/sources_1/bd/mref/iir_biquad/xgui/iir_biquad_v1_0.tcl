# Definitional proc to organize widgets for parameters.
proc init_gui { IPINST } {
  ipgui::add_param $IPINST -name "Component_Name"
  #Adding Page
  set Page_0 [ipgui::add_page $IPINST -name "Page 0"]
  ipgui::add_param $IPINST -name "A1" -parent ${Page_0}
  ipgui::add_param $IPINST -name "A2" -parent ${Page_0}
  ipgui::add_param $IPINST -name "B0" -parent ${Page_0}
  ipgui::add_param $IPINST -name "B1" -parent ${Page_0}
  ipgui::add_param $IPINST -name "B2" -parent ${Page_0}
  ipgui::add_param $IPINST -name "COEF_W" -parent ${Page_0}
  ipgui::add_param $IPINST -name "DATA_W" -parent ${Page_0}
  ipgui::add_param $IPINST -name "FRAC" -parent ${Page_0}


}

proc update_PARAM_VALUE.A1 { PARAM_VALUE.A1 } {
	# Procedure called to update A1 when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.A1 { PARAM_VALUE.A1 } {
	# Procedure called to validate A1
	return true
}

proc update_PARAM_VALUE.A2 { PARAM_VALUE.A2 } {
	# Procedure called to update A2 when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.A2 { PARAM_VALUE.A2 } {
	# Procedure called to validate A2
	return true
}

proc update_PARAM_VALUE.B0 { PARAM_VALUE.B0 } {
	# Procedure called to update B0 when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.B0 { PARAM_VALUE.B0 } {
	# Procedure called to validate B0
	return true
}

proc update_PARAM_VALUE.B1 { PARAM_VALUE.B1 } {
	# Procedure called to update B1 when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.B1 { PARAM_VALUE.B1 } {
	# Procedure called to validate B1
	return true
}

proc update_PARAM_VALUE.B2 { PARAM_VALUE.B2 } {
	# Procedure called to update B2 when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.B2 { PARAM_VALUE.B2 } {
	# Procedure called to validate B2
	return true
}

proc update_PARAM_VALUE.COEF_W { PARAM_VALUE.COEF_W } {
	# Procedure called to update COEF_W when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.COEF_W { PARAM_VALUE.COEF_W } {
	# Procedure called to validate COEF_W
	return true
}

proc update_PARAM_VALUE.DATA_W { PARAM_VALUE.DATA_W } {
	# Procedure called to update DATA_W when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.DATA_W { PARAM_VALUE.DATA_W } {
	# Procedure called to validate DATA_W
	return true
}

proc update_PARAM_VALUE.FRAC { PARAM_VALUE.FRAC } {
	# Procedure called to update FRAC when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.FRAC { PARAM_VALUE.FRAC } {
	# Procedure called to validate FRAC
	return true
}


proc update_MODELPARAM_VALUE.DATA_W { MODELPARAM_VALUE.DATA_W PARAM_VALUE.DATA_W } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.DATA_W}] ${MODELPARAM_VALUE.DATA_W}
}

proc update_MODELPARAM_VALUE.COEF_W { MODELPARAM_VALUE.COEF_W PARAM_VALUE.COEF_W } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.COEF_W}] ${MODELPARAM_VALUE.COEF_W}
}

proc update_MODELPARAM_VALUE.FRAC { MODELPARAM_VALUE.FRAC PARAM_VALUE.FRAC } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.FRAC}] ${MODELPARAM_VALUE.FRAC}
}

proc update_MODELPARAM_VALUE.B0 { MODELPARAM_VALUE.B0 PARAM_VALUE.B0 } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.B0}] ${MODELPARAM_VALUE.B0}
}

proc update_MODELPARAM_VALUE.B1 { MODELPARAM_VALUE.B1 PARAM_VALUE.B1 } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.B1}] ${MODELPARAM_VALUE.B1}
}

proc update_MODELPARAM_VALUE.B2 { MODELPARAM_VALUE.B2 PARAM_VALUE.B2 } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.B2}] ${MODELPARAM_VALUE.B2}
}

proc update_MODELPARAM_VALUE.A1 { MODELPARAM_VALUE.A1 PARAM_VALUE.A1 } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.A1}] ${MODELPARAM_VALUE.A1}
}

proc update_MODELPARAM_VALUE.A2 { MODELPARAM_VALUE.A2 PARAM_VALUE.A2 } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.A2}] ${MODELPARAM_VALUE.A2}
}

