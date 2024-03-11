//******************************************************************************
/// @FILE    wishbone_classic_block_ram.v
/// @AUTHOR  JAY CONVERTINO
/// @DATE    2024.03.07
/// @BRIEF   WISHBONE UART
/// @DETAILS
///
/// @LICENSE MIT
///  Copyright 2024 Jay Convertino
///
///  Permission is hereby granted, free of charge, to any person obtaining a copy
///  of this software and associated documentation files (the "Software"), to
///  deal in the Software without restriction, including without limitation the
///  rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
///  sell copies of the Software, and to permit persons to whom the Software is
///  furnished to do so, subject to the following conditions:
///
///  The above copyright notice and this permission notice shall be included in
///  all copies or substantial portions of the Software.
///
///  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
///  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
///  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
///  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
///  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
///  FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
///  IN THE SOFTWARE.
//******************************************************************************

`timescale 1ns/100ps

//UART
module wishbone_classic_block_ram #(
    parameter ADDRESS_WIDTH     = 32,
    parameter BUS_WIDTH         = 4,
    parameter DEPTH             = 512,
    parameter RAM_TYPE          = "block",
    parameter BIN_FILE          = ""
  )
  (
    //clock and reset
    input           clk,
    input           rst,
    //Wishbone
    input                       s_wb_cyc,
    input                       s_wb_stb,
    input                       s_wb_we,
    input   [ADDRESS_WIDTH-1:0] s_wb_addr,
    input   [BUS_WIDTH*8-1:0]   s_wb_data_i,
    input   [BUS_WIDTH-1:0]     s_wb_sel,
    input   [ 1:0]              s_wb_bte,
    input   [ 2:0]              s_wb_cti,
    output                      s_wb_ack,
    output  [BUS_WIDTH*8-1:0]   s_wb_data_o,
    output                      s_wb_err
  );

  `include "util_helper_math.vh"

  // calculate widths
  localparam c_PWR_RAM  = clogb2(DEPTH);
  localparam c_RAM_DEPTH = 2 ** c_PWR_RAM;

  //read interface
  wire                      up_rreq;
  reg                       up_rack;
  wire  [ADDRESS_WIDTH-1:0] up_raddr;
  wire  [BUS_WIDTH*8-1:0]   up_rdata;
  //write interface
  wire                      up_wreq;
  reg                       up_wack;
  wire  [ADDRESS_WIDTH-1:0] up_waddr;
  wire  [BUS_WIDTH*8-1:0]   up_wdata;


  up_wishbone_classic #(
    .ADDRESS_WIDTH(ADDRESS_WIDTH),
    .BUS_WIDTH(BUS_WIDTH)
  ) inst_up_wishbone_classic (
    .clk(clk),
    .rst(rst),
    //Wishbone
    .s_wb_cyc(s_wb_cyc),
    .s_wb_stb(s_wb_stb),
    .s_wb_we(s_wb_we),
    .s_wb_addr(s_wb_addr),
    .s_wb_data_i(s_wb_data_i),
    .s_wb_sel(s_wb_sel),
    .s_wb_cti(s_wb_cti),
    .s_wb_bte(s_wb_bte),
    .s_wb_ack(s_wb_ack),
    .s_wb_data_o(s_wb_data_o),
    .s_wb_err(s_wb_err),
    //uP
    //read interface
    .up_rreq(up_rreq),
    .up_rack(up_rack),
    .up_raddr(up_raddr),
    .up_rdata(up_rdata),
    //write interface
    .up_wreq(up_wreq),
    .up_wack(up_wack),
    .up_waddr(up_waddr),
    .up_wdata(up_wdata)
  );

  dc_block_ram #(
    .RAM_DEPTH(c_RAM_DEPTH),
    .BYTE_WIDTH(BUS_WIDTH),
    .ADDR_WIDTH(c_PWR_RAM),
    .BIN_FILE(BIN_FILE),
    .RAM_TYPE(RAM_TYPE)
  ) inst_dc_block_ram (
    // read output
    .rd_clk(clk),
    .rd_rstn(~rst),
    .rd_en(up_rreq),
    .rd_data(up_rdata),
    .rd_addr(up_raddr[c_PWR_RAM+1:2]),
    // write input
    .wr_clk(clk),
    .wr_rstn(~rst),
    .wr_en(up_wreq),
    .wr_ben(s_wb_sel),
    .wr_data(up_wdata),
    .wr_addr(up_waddr[c_PWR_RAM+1:2])
  );

  always @(posedge clk)
  begin
    if(rst)
    begin
      up_wack <= 1'b0;
      up_rack <= 1'b0;
    end else begin
      up_wack <= up_wreq;
      up_rack <= up_rreq;
    end
  end

endmodule
