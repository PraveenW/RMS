`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: San Jose State University
// Engineer: Praveen Waliitagi
// 
// Create Date:    13:08:29 04/01/2015 
// Design Name: 
// Module Name:    rms 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module rms(
input clk,
input rst,
input pushin,
input [1:0] cmdin,
input signed [31:0] Xin,
input pullout,
output stopout,
output [31:0] Xout
);



reg [1:0] cmd_q;
reg pushin_q,pullout_q;
reg signed [31:0] Xin_q;


//--------------------------------------------------------------------
always @(posedge clk or posedge rst)
begin 
if (rst)
begin
cmd_q <= #1 2'b00;
pushin_q <= #1 0;
pullout_q <= #1 0;
Xin_q <= #1 32'd0;
end
else
begin
cmd_q <= #1 cmdin;
pushin_q <= #1 pushin;
pullout_q <= #1 pullout;
Xin_q <= #1 Xin;
end
end
//--------------------------------------------------------------------

reg [9:0] n_d,n_q;
reg [71:0] sum_d,sum_q;
reg div_en_d,div_en_q;
reg [1:0] cmd_q1,cmd_q2,cmd_q3,cmd_q4;
reg pushin_q1,pushin_q2,pushin_q3,pushin_q4;

//These signals are used when cmdin =11 
reg [9:0] n_d1,n_q1;
reg [71:0] sum_d1,sum_q1;
//------------------------------------
//FIFO interface signals
wire fifo_full,fifo_empty;
wire fifo_wr_en,fifo_rd_en;
wire div_en;


reg signed [63:0] temp_d,temp_q;

//-------------------------------------------------------
always @(posedge clk or posedge rst)
begin 
if (rst)
begin
cmd_q1 <= #1 2'b00;
cmd_q2 <= #1 2'b00;
cmd_q3 <= #1 2'b00;
cmd_q4 <= #1 2'b00;
div_en_q <= #1 0;
sum_q <= #1 72'd0;
n_q <= #1 10'd0;
sum_q1 <= #1 72'd0;
n_q1 <= #1 10'd0;
pushin_q1 <= #1 0;
pushin_q2 <= #1 0;
pushin_q3 <= #1 0;
pushin_q4 <= #1 0;
temp_q <= #1 0;
end
else 
begin
cmd_q1 <= #1 cmd_q;
cmd_q2 <= #1 cmd_q1;
cmd_q3 <= #1 cmd_q2;
cmd_q4 <= #1 cmd_q3;
div_en_q <= #1 div_en_d;
sum_q <= #1 sum_d;
n_q <= #1 n_d;
sum_q1 <= #1 sum_d1;
n_q1 <= #1 n_d1;
pushin_q1 <= #1 pushin_q;
pushin_q2 <= #1 pushin_q1;
pushin_q3 <= #1 pushin_q2;
pushin_q4 <= #1 pushin_q3;
temp_q <= #1 temp_d;
end
end

//----------------------------------------------------------------------------
//First Stage Multiplication
//----------------------------------------------------------------------------
wire [63:0] prod;

DW02_mult_3_stage #(32,32)
    U1_3_stage_mult ( .A(Xin_q), .B(Xin_q), .TC(1'b1), 
         .CLK(clk), .PRODUCT(prod) );



//---------------------------------------------------------------------
//--Irrespective of whats cmd_q is First stage is always multiplication
//---------------------------------------------------------------------
always @(*)
begin
if(pushin_q2)
temp_d = prod;
else
temp_d = temp_q;
end

//--------------------------------------------------------------------------------------


//---------------------------------------------------------
//Second Stage Addition 
//---------------------------------------------------------
always @(*)
begin
//initialise signals here to avoid latch
sum_d = sum_q;
n_d = n_q;
div_en_d = div_en_q;
sum_d1 = sum_q1;
n_d1 = n_q1;

if(pushin_q3 && cmd_q3 == 2'b00)
begin
sum_d = sum_q + temp_q;
n_d = n_q + 10'd1;
div_en_d = 0;
end

else if(pushin_q3 && cmd_q3 == 2'b01)
begin
sum_d = sum_q - temp_q;
n_d = n_q - 10'd1;
div_en_d = 0;
end


else if(pushin_q3 && cmd_q3 == 2'b10)
begin
sum_d = sum_q + temp_q;
n_d = n_q + 10'd1;
div_en_d = 1;
end



else if(pushin_q3 && cmd_q3 == 2'b11)
begin
sum_d1 = sum_q + temp_q;
n_d1 = n_q + 10'd1;
div_en_d = 1;
sum_d = 72'd0;
n_d= 10'd0;
end

end




//-----------------------------------------------------
//Multiplexer logic to choose dividend and divisor
//-----------------------------------------------------

wire [71:0] dividend;
wire [9:0] divisor;
wire mux_sel;
wire [71:0] div_res;

wire [31:0] rms_value;

assign mux_sel = cmd_q4[1] & cmd_q4[0];

assign dividend = mux_sel ? sum_q1 : sum_q;

assign divisor = mux_sel ? n_q1 : n_q;

//----------------------------------------------------------
//Divider Block Instantiation
//----------------------------------------------------------

DW_div_pipe #(72,10,0,1,38,1,1,0) u1_DW_div_pipe (
.clk(clk),
.rst_n(~rst),
.en(1'b1),
.a(dividend),
.b(divisor),
.quotient(div_res),
.remainder(),
.divide_by_0()
);

wire [37:0] din;

assign din[0] = div_en;
genvar i;
generate
for(i=1; i<38; i=i+1) begin
dff u1_dff (.clk(clk),.rst(rst),.d(din[i-1]),.q(din[i]));
end
endgenerate




//-------------------------------------------------------------------
//Square Root Block Instantiation
//-------------------------------------------------------------------
DW_sqrt_pipe #(64,0,32,1,1,0) u1_DW_sqrt_pipe (
.clk(clk),
.rst_n(~rst),
.en(1'b1),
.a(div_res[63:0]),
.root(rms_value)
);


wire [31:0] datain;

assign datain[0] = din[37];
genvar j;
generate
for(j=1; j<32; j=j+1) begin
dff u2_dff (.clk(clk),.rst(rst),.d(datain[j-1]),.q(datain[j]));
end
endgenerate


//--------------------------------------------------------------------------------
//Instantiation of output FIFO block
//--------------------------------------------------------------------------------
fifo u1_fifo(
.clk(clk),
.rst(rst),
.data_in(rms_value),
.rd_en(fifo_rd_en),
.wr_en(fifo_wr_en),
.data_out(Xout),
.full(fifo_full),
.empty(fifo_empty)
);


assign fifo_wr_en = (datain[31] && (!fifo_full));

assign fifo_rd_en = ((pullout == 1'b1 && (!fifo_empty)));
assign div_en = ((cmd_q4 == 2'b10 || cmd_q4 == 2'b11) && pushin_q4);



assign stopout = fifo_empty;


endmodule
