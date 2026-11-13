//Copyright 1986-2019 Xilinx, Inc. All Rights Reserved.
//--------------------------------------------------------------------------------
//Tool Version: Vivado v.2019.1 (win64) Build 2552052 Fri May 24 14:49:42 MDT 2019
//Date        : Fri Nov 13 08:21:30 2026
//Host        : DESKTOP-HKQ2PM6 running 64-bit major release  (build 9200)
//Command     : generate_target FM_Demod_wrapper.bd
//Design      : FM_Demod_wrapper
//Purpose     : IP block netlist
//--------------------------------------------------------------------------------
`timescale 1 ps / 1 ps

module FM_Demod_wrapper
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
  input aclk;
  input aresetn;
  output [15:0]rx_audio_tdata;
  output rx_audio_tvalid;
  input [63:0]rx_iq_tdata;
  input rx_iq_tvalid;
  output rx_squelch_open;
  input [15:0]tx_audio_tdata;
  input tx_audio_tvalid;
  output [63:0]tx_iq_tdata;
  output tx_iq_tvalid;

  wire aclk;
  wire aresetn;
  wire [15:0]rx_audio_tdata;
  wire rx_audio_tvalid;
  wire [63:0]rx_iq_tdata;
  wire rx_iq_tvalid;
  wire rx_squelch_open;
  wire [15:0]tx_audio_tdata;
  wire tx_audio_tvalid;
  wire [63:0]tx_iq_tdata;
  wire tx_iq_tvalid;

  FM_Demod FM_Demod_i
       (.aclk(aclk),
        .aresetn(aresetn),
        .rx_audio_tdata(rx_audio_tdata),
        .rx_audio_tvalid(rx_audio_tvalid),
        .rx_iq_tdata(rx_iq_tdata),
        .rx_iq_tvalid(rx_iq_tvalid),
        .rx_squelch_open(rx_squelch_open),
        .tx_audio_tdata(tx_audio_tdata),
        .tx_audio_tvalid(tx_audio_tvalid),
        .tx_iq_tdata(tx_iq_tdata),
        .tx_iq_tvalid(tx_iq_tvalid));
endmodule
