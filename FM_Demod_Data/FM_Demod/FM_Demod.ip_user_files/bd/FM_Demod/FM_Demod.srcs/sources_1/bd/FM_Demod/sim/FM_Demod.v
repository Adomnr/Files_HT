//Copyright 1986-2019 Xilinx, Inc. All Rights Reserved.
//--------------------------------------------------------------------------------
//Tool Version: Vivado v.2019.1 (win64) Build 2552052 Fri May 24 14:49:42 MDT 2019
//Date        : Fri Nov 13 07:09:43 2026
//Host        : DESKTOP-HKQ2PM6 running 64-bit major release  (build 9200)
//Command     : generate_target FM_Demod.bd
//Design      : FM_Demod
//Purpose     : IP block netlist
//--------------------------------------------------------------------------------
`timescale 1 ps / 1 ps

(* CORE_GENERATION_INFO = "FM_Demod,IP_Integrator,{x_ipVendor=xilinx.com,x_ipLibrary=BlockDiagram,x_ipName=FM_Demod,x_ipVersion=1.00.a,x_ipLanguage=VERILOG,numBlks=51,numReposBlks=49,numNonXlnxBlks=0,numHierBlks=2,maxHierDepth=1,numSysgenBlks=0,numHlsBlks=0,numHdlrefBlks=13,numPkgbdBlks=0,bdsource=USER,synth_mode=OOC_per_IP}" *) (* HW_HANDOFF = "FM_Demod.hwdef" *) 
module FM_Demod
   (aclk,
    aresetn,
    rx_audio_tdata,
    rx_audio_tvalid,
    rx_iq_tdata,
    rx_iq_tvalid,
    rx_squelch_open,
    tx_audio_tdata,
    tx_audio_tvalid,
    tx_iq_tdata,
    tx_iq_tvalid);
  (* X_INTERFACE_INFO = "xilinx.com:signal:clock:1.0 CLK.ACLK CLK" *) (* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME CLK.ACLK, ASSOCIATED_RESET aresetn, CLK_DOMAIN FM_Demod_aclk, FREQ_HZ 100000000, INSERT_VIP 0, PHASE 0.000" *) input aclk;
  (* X_INTERFACE_INFO = "xilinx.com:signal:reset:1.0 RST.ARESETN RST" *) (* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME RST.ARESETN, INSERT_VIP 0, POLARITY ACTIVE_LOW" *) input aresetn;
  output [15:0]rx_audio_tdata;
  output rx_audio_tvalid;
  input [31:0]rx_iq_tdata;
  input rx_iq_tvalid;
  output rx_squelch_open;
  input [15:0]tx_audio_tdata;
  input tx_audio_tvalid;
  output [31:0]tx_iq_tdata;
  output tx_iq_tvalid;

  wire aclk_1;
  wire aresetn_1;
  wire [15:0]fm_demod_m_axis_audio_tdata;
  wire fm_demod_m_axis_audio_tvalid;
  wire fm_demod_squelch_open;
  wire [31:0]fm_mod_m_axis_iq_tdata;
  wire fm_mod_m_axis_iq_tvalid;
  wire [31:0]rx_iq_tdata_1;
  wire rx_iq_tvalid_1;
  wire [15:0]tx_audio_tdata_1;
  wire tx_audio_tvalid_1;

  assign aclk_1 = aclk;
  assign aresetn_1 = aresetn;
  assign rx_audio_tdata[15:0] = fm_demod_m_axis_audio_tdata;
  assign rx_audio_tvalid = fm_demod_m_axis_audio_tvalid;
  assign rx_iq_tdata_1 = rx_iq_tdata[31:0];
  assign rx_iq_tvalid_1 = rx_iq_tvalid;
  assign rx_squelch_open = fm_demod_squelch_open;
  assign tx_audio_tdata_1 = tx_audio_tdata[15:0];
  assign tx_audio_tvalid_1 = tx_audio_tvalid;
  assign tx_iq_tdata[31:0] = fm_mod_m_axis_iq_tdata;
  assign tx_iq_tvalid = fm_mod_m_axis_iq_tvalid;
  fm_demod_imp_HG3VFG fm_demod
       (.aclk(aclk_1),
        .aresetn(aresetn_1),
        .m_axis_audio_tdata(fm_demod_m_axis_audio_tdata),
        .m_axis_audio_tvalid(fm_demod_m_axis_audio_tvalid),
        .s_axis_iq_tdata(rx_iq_tdata_1),
        .s_axis_iq_tvalid(rx_iq_tvalid_1),
        .squelch_open(fm_demod_squelch_open));
  fm_mod_imp_1G9E4IN fm_mod
       (.aclk(aclk_1),
        .aresetn(aresetn_1),
        .m_axis_iq_tdata(fm_mod_m_axis_iq_tdata),
        .m_axis_iq_tvalid(fm_mod_m_axis_iq_tvalid),
        .s_axis_audio_tdata(tx_audio_tdata_1),
        .s_axis_audio_tvalid(tx_audio_tvalid_1));
endmodule

module fm_demod_imp_HG3VFG
   (aclk,
    aresetn,
    m_axis_audio_tdata,
    m_axis_audio_tvalid,
    s_axis_iq_tdata,
    s_axis_iq_tvalid,
    squelch_open);
  input aclk;
  input aresetn;
  output [15:0]m_axis_audio_tdata;
  output m_axis_audio_tvalid;
  input [31:0]s_axis_iq_tdata;
  input s_axis_iq_tvalid;
  output squelch_open;

  wire aclk_1;
  wire aresetn_1;
  wire [25:0]bq0_out_data;
  wire bq0_out_valid;
  wire [25:0]bq1_out_data;
  wire bq1_out_valid;
  wire [25:0]bq2_out_data;
  wire bq2_out_valid;
  wire [25:0]bq3_out_data;
  wire bq3_out_valid;
  wire [25:0]bq_guard_dout;
  wire [7:0]bq_zero_dout;
  wire [47:0]cordic_rx_m_axis_dout_tdata;
  wire cordic_rx_m_axis_dout_tvalid;
  wire [31:0]de_acc_Q;
  wire [0:0]de_ce_Q;
  wire [15:0]de_fb_Dout;
  wire [27:0]de_mul_P;
  wire [17:0]de_out_Dout;
  wire [16:0]de_sub_S;
  wire [0:0]de_vld_Q;
  wire [15:0]disc_sat_out_data;
  wire disc_sat_out_valid;
  wire [0:0]disc_vld_Q;
  wire [15:0]iq_i_Dout;
  wire [0:0]iq_i_sign_Dout;
  wire [47:0]iq_pack_dout;
  wire [5:0]iq_pad_dout;
  wire [15:0]iq_q_Dout;
  wire [0:0]iq_q_sign_Dout;
  wire [17:0]mag_reg_Q;
  wire [17:0]mag_sel_Dout;
  wire [15:0]out_round_out_data;
  wire out_round_out_valid;
  wire [19:0]phase_diff_S;
  wire [19:0]phase_sel_Dout;
  wire [19:0]phase_z1_Q;
  wire [0:0]rst_inv_Res;
  wire [31:0]s_axis_iq_tdata_1;
  wire s_axis_iq_tvalid_1;
  wire [17:0]sq_th_close_dout;
  wire [17:0]sq_th_open_dout;
  wire [15:0]squelch_audio;
  wire squelch_gate;
  wire squelch_out_valid;

  assign aclk_1 = aclk;
  assign aresetn_1 = aresetn;
  assign m_axis_audio_tdata[15:0] = out_round_out_data;
  assign m_axis_audio_tvalid = out_round_out_valid;
  assign s_axis_iq_tdata_1 = s_axis_iq_tdata[31:0];
  assign s_axis_iq_tvalid_1 = s_axis_iq_tvalid;
  assign squelch_open = squelch_gate;
  FM_Demod_bq0_2 bq0
       (.aclk(aclk_1),
        .aresetn(aresetn_1),
        .in_data(bq_guard_dout),
        .in_valid(de_vld_Q),
        .out_data(bq0_out_data),
        .out_valid(bq0_out_valid));
  FM_Demod_bq1_2 bq1
       (.aclk(aclk_1),
        .aresetn(aresetn_1),
        .in_data(bq0_out_data),
        .in_valid(bq0_out_valid),
        .out_data(bq1_out_data),
        .out_valid(bq1_out_valid));
  FM_Demod_bq2_2 bq2
       (.aclk(aclk_1),
        .aresetn(aresetn_1),
        .in_data(bq1_out_data),
        .in_valid(bq1_out_valid),
        .out_data(bq2_out_data),
        .out_valid(bq2_out_valid));
  FM_Demod_bq3_2 bq3
       (.aclk(aclk_1),
        .aresetn(aresetn_1),
        .in_data(bq2_out_data),
        .in_valid(bq2_out_valid),
        .out_data(bq3_out_data),
        .out_valid(bq3_out_valid));
  FM_Demod_bq_guard_2 bq_guard
       (.In0(bq_zero_dout),
        .In1(de_out_Dout),
        .dout(bq_guard_dout));
  FM_Demod_bq_zero_2 bq_zero
       (.dout(bq_zero_dout));
  FM_Demod_cordic_rx_1 cordic_rx
       (.aclk(aclk_1),
        .aresetn(aresetn_1),
        .m_axis_dout_tdata(cordic_rx_m_axis_dout_tdata),
        .m_axis_dout_tvalid(cordic_rx_m_axis_dout_tvalid),
        .s_axis_cartesian_tdata(iq_pack_dout),
        .s_axis_cartesian_tvalid(s_axis_iq_tvalid_1));
  FM_Demod_de_acc_1 de_acc
       (.B(de_mul_P),
        .CE(de_ce_Q),
        .CLK(aclk_1),
        .Q(de_acc_Q),
        .SCLR(rst_inv_Res));
  FM_Demod_de_ce_1 de_ce
       (.CLK(aclk_1),
        .D(squelch_out_valid),
        .Q(de_ce_Q));
  FM_Demod_de_fb_1 de_fb
       (.Din(de_acc_Q),
        .Dout(de_fb_Dout));
  FM_Demod_de_mul_1 de_mul
       (.A(de_sub_S),
        .CLK(aclk_1),
        .P(de_mul_P));
  FM_Demod_de_out_1 de_out
       (.Din(de_acc_Q),
        .Dout(de_out_Dout));
  FM_Demod_de_sub_1 de_sub
       (.A(squelch_audio),
        .B(de_fb_Dout),
        .CLK(aclk_1),
        .S(de_sub_S));
  FM_Demod_de_vld_1 de_vld
       (.CLK(aclk_1),
        .D(de_ce_Q),
        .Q(de_vld_Q));
  FM_Demod_disc_sat_1 disc_sat
       (.aclk(aclk_1),
        .aresetn(aresetn_1),
        .in_data(phase_diff_S),
        .in_valid(disc_vld_Q),
        .out_data(disc_sat_out_data),
        .out_valid(disc_sat_out_valid));
  FM_Demod_disc_vld_1 disc_vld
       (.CLK(aclk_1),
        .D(cordic_rx_m_axis_dout_tvalid),
        .Q(disc_vld_Q));
  FM_Demod_iq_i_1 iq_i
       (.Din(s_axis_iq_tdata_1),
        .Dout(iq_i_Dout));
  FM_Demod_iq_i_sign_1 iq_i_sign
       (.Din(s_axis_iq_tdata_1),
        .Dout(iq_i_sign_Dout));
  FM_Demod_iq_pack_1 iq_pack
       (.In0(iq_i_Dout),
        .In1(iq_i_sign_Dout),
        .In2(iq_i_sign_Dout),
        .In3(iq_pad_dout),
        .In4(iq_q_Dout),
        .In5(iq_q_sign_Dout),
        .In6(iq_q_sign_Dout),
        .In7(iq_pad_dout),
        .dout(iq_pack_dout));
  FM_Demod_iq_pad_1 iq_pad
       (.dout(iq_pad_dout));
  FM_Demod_iq_q_1 iq_q
       (.Din(s_axis_iq_tdata_1),
        .Dout(iq_q_Dout));
  FM_Demod_iq_q_sign_1 iq_q_sign
       (.Din(s_axis_iq_tdata_1),
        .Dout(iq_q_sign_Dout));
  FM_Demod_mag_reg_1 mag_reg
       (.CE(cordic_rx_m_axis_dout_tvalid),
        .CLK(aclk_1),
        .D(mag_sel_Dout),
        .Q(mag_reg_Q));
  FM_Demod_mag_sel_1 mag_sel
       (.Din(cordic_rx_m_axis_dout_tdata),
        .Dout(mag_sel_Dout));
  FM_Demod_out_round_1 out_round
       (.aclk(aclk_1),
        .aresetn(aresetn_1),
        .in_data(bq3_out_data),
        .in_valid(bq3_out_valid),
        .out_data(out_round_out_data),
        .out_valid(out_round_out_valid));
  FM_Demod_phase_diff_1 phase_diff
       (.A(phase_sel_Dout),
        .B(phase_z1_Q),
        .CE(cordic_rx_m_axis_dout_tvalid),
        .CLK(aclk_1),
        .S(phase_diff_S));
  FM_Demod_phase_sel_1 phase_sel
       (.Din(cordic_rx_m_axis_dout_tdata),
        .Dout(phase_sel_Dout));
  FM_Demod_phase_z1_1 phase_z1
       (.CE(cordic_rx_m_axis_dout_tvalid),
        .CLK(aclk_1),
        .D(phase_sel_Dout),
        .Q(phase_z1_Q));
  FM_Demod_rst_inv_2 rst_inv
       (.Op1(aresetn_1),
        .Res(rst_inv_Res));
  FM_Demod_sq_th_close_1 sq_th_close
       (.dout(sq_th_close_dout));
  FM_Demod_sq_th_open_1 sq_th_open
       (.dout(sq_th_open_dout));
  FM_Demod_squelch_1 squelch
       (.aclk(aclk_1),
        .aresetn(aresetn_1),
        .audio(squelch_audio),
        .disc(disc_sat_out_data),
        .gate(squelch_gate),
        .in_valid(disc_sat_out_valid),
        .mag(mag_reg_Q),
        .out_valid(squelch_out_valid),
        .th_close(sq_th_close_dout),
        .th_open(sq_th_open_dout));
endmodule

module fm_mod_imp_1G9E4IN
   (aclk,
    aresetn,
    m_axis_iq_tdata,
    m_axis_iq_tvalid,
    s_axis_audio_tdata,
    s_axis_audio_tvalid);
  input aclk;
  input aresetn;
  output [31:0]m_axis_iq_tdata;
  output m_axis_iq_tvalid;
  input [15:0]s_axis_audio_tdata;
  input s_axis_audio_tvalid;

  wire aclk_1;
  wire aresetn_1;
  wire [23:0]bq0_out_data;
  wire bq0_out_valid;
  wire [23:0]bq1_out_data;
  wire bq1_out_valid;
  wire [23:0]bq2_out_data;
  wire bq2_out_valid;
  wire [23:0]bq3_out_data;
  wire bq3_out_valid;
  wire [23:0]bq_guard_dout;
  wire [15:0]bq_round_out_data;
  wire bq_round_out_valid;
  wire [7:0]bq_zero_dout;
  wire [31:0]cordic_tx_m_axis_dout_tdata;
  wire cordic_tx_m_axis_dout_tvalid;
  wire [24:0]dev_limit_out_data;
  wire dev_limit_out_valid;
  wire [27:0]phase_acc_Q;
  wire [1:0]phase_lsb_dout;
  wire [31:0]phase_pack_dout;
  wire [0:0]phase_sign_Dout;
  wire [0:0]phase_vld_Q;
  wire [31:0]pre_emph_m_axis_data_tdata;
  wire pre_emph_m_axis_data_tvalid;
  wire [30:0]pre_sel_Dout;
  wire [0:0]rst_inv_Res;
  wire [15:0]s_axis_audio_tdata_1;
  wire s_axis_audio_tvalid_1;

  assign aclk_1 = aclk;
  assign aresetn_1 = aresetn;
  assign m_axis_iq_tdata[31:0] = cordic_tx_m_axis_dout_tdata;
  assign m_axis_iq_tvalid = cordic_tx_m_axis_dout_tvalid;
  assign s_axis_audio_tdata_1 = s_axis_audio_tdata[15:0];
  assign s_axis_audio_tvalid_1 = s_axis_audio_tvalid;
  FM_Demod_bq0_3 bq0
       (.aclk(aclk_1),
        .aresetn(aresetn_1),
        .in_data(bq_guard_dout),
        .in_valid(s_axis_audio_tvalid_1),
        .out_data(bq0_out_data),
        .out_valid(bq0_out_valid));
  FM_Demod_bq1_3 bq1
       (.aclk(aclk_1),
        .aresetn(aresetn_1),
        .in_data(bq0_out_data),
        .in_valid(bq0_out_valid),
        .out_data(bq1_out_data),
        .out_valid(bq1_out_valid));
  FM_Demod_bq2_3 bq2
       (.aclk(aclk_1),
        .aresetn(aresetn_1),
        .in_data(bq1_out_data),
        .in_valid(bq1_out_valid),
        .out_data(bq2_out_data),
        .out_valid(bq2_out_valid));
  FM_Demod_bq3_3 bq3
       (.aclk(aclk_1),
        .aresetn(aresetn_1),
        .in_data(bq2_out_data),
        .in_valid(bq2_out_valid),
        .out_data(bq3_out_data),
        .out_valid(bq3_out_valid));
  FM_Demod_bq_guard_3 bq_guard
       (.In0(bq_zero_dout),
        .In1(s_axis_audio_tdata_1),
        .dout(bq_guard_dout));
  FM_Demod_bq_round_1 bq_round
       (.aclk(aclk_1),
        .aresetn(aresetn_1),
        .in_data(bq3_out_data),
        .in_valid(bq3_out_valid),
        .out_data(bq_round_out_data),
        .out_valid(bq_round_out_valid));
  FM_Demod_bq_zero_3 bq_zero
       (.dout(bq_zero_dout));
  FM_Demod_cordic_tx_1 cordic_tx
       (.aclk(aclk_1),
        .aresetn(aresetn_1),
        .m_axis_dout_tdata(cordic_tx_m_axis_dout_tdata),
        .m_axis_dout_tvalid(cordic_tx_m_axis_dout_tvalid),
        .s_axis_phase_tdata(phase_pack_dout),
        .s_axis_phase_tvalid(phase_vld_Q));
  FM_Demod_dev_limit_1 dev_limit
       (.aclk(aclk_1),
        .aresetn(aresetn_1),
        .in_data(pre_sel_Dout),
        .in_valid(pre_emph_m_axis_data_tvalid),
        .out_data(dev_limit_out_data),
        .out_valid(dev_limit_out_valid));
  FM_Demod_phase_acc_1 phase_acc
       (.B(dev_limit_out_data),
        .CE(dev_limit_out_valid),
        .CLK(aclk_1),
        .Q(phase_acc_Q),
        .SCLR(rst_inv_Res));
  FM_Demod_phase_lsb_1 phase_lsb
       (.dout(phase_lsb_dout));
  FM_Demod_phase_pack_1 phase_pack
       (.In0(phase_lsb_dout),
        .In1(phase_acc_Q),
        .In2(phase_sign_Dout),
        .In3(phase_sign_Dout),
        .dout(phase_pack_dout));
  FM_Demod_phase_sign_1 phase_sign
       (.Din(phase_acc_Q),
        .Dout(phase_sign_Dout));
  FM_Demod_phase_vld_1 phase_vld
       (.CLK(aclk_1),
        .D(dev_limit_out_valid),
        .Q(phase_vld_Q));
  FM_Demod_pre_emph_1 pre_emph
       (.aclk(aclk_1),
        .aresetn(aresetn_1),
        .m_axis_data_tdata(pre_emph_m_axis_data_tdata),
        .m_axis_data_tvalid(pre_emph_m_axis_data_tvalid),
        .s_axis_data_tdata(bq_round_out_data),
        .s_axis_data_tvalid(bq_round_out_valid));
  FM_Demod_pre_sel_1 pre_sel
       (.Din(pre_emph_m_axis_data_tdata),
        .Dout(pre_sel_Dout));
  FM_Demod_rst_inv_3 rst_inv
       (.Op1(aresetn_1),
        .Res(rst_inv_Res));
endmodule
