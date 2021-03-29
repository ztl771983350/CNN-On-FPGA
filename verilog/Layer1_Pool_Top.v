`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    15:39:45 03/11/2019 
// Design Name: 
// Module Name:    Layer1_Pool_Top 
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
module Layer1_Pool_Top
#(
	parameter						bits			=	16		,	//quantization bit number
	parameter						bits_shift		=	4		,	//we can shift but not multy
	parameter						channel_bits		=	64		,	//channel_out_num*bits   
	parameter						channel_bits_shift	=	6		,      //第一层的conv一次性计算了16个数，再*layer1conv的4个输出通道
	parameter						channel_in_num		=	64		,      //也就是一次性输入了64个数
	parameter						channel_out_num		=	16	                
	)
	(
	input								clk_in,
	input 								rst_n,
	input 	[(channel_in_num<<bits_shift)-1:0]			data_in,      //输入时64个16bit的数，就是layer1conv 同时并行计算的16组卷积*4个卷积核
	input								start,
	output	[(channel_out_num<<bits_shift)-1:0]			data_out, 
	output								ready
    );

integer w_file;
initial w_file = $fopen("pool1.txt");
always @(*)
begin
    $fdisplay(w_file,"%d",data_out[255:240]);
end 

wire			ready_temp[0:channel_out_num-1];
assign			ready				 =		ready_temp[0]					;
genvar i;
generate
	for (i = 0; i < channel_out_num; i = i + 1)         //layer1pool 输出的16个数，2*2*4
	begin:pooling
		maxpool_one_clk layer_pool(
			.clk_in			(clk_in),
			.rst_n			(rst_n),
			.data_in			(data_in[(i<<channel_bits_shift)+channel_bits-1:(i<<channel_bits_shift)]),
			.start			(start),
			.data_out		(data_out[(i<<bits_shift)+bits-1:(i<<bits_shift)]),
			.ready			(ready_temp[i])
			);
		
	end
endgenerate
endmodule
