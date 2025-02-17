`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    15:25:37 03/11/2019 
// Design Name: 
// Module Name:    Conv_unsign_sign 
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
//做一个解释：主要就是一个 加法模块，每次输入一个a和b，对他俩相乘，然后暂时存到一个加和中，
//然后重复“卷积核大小次”，最后一个函数判断完成一次完整卷积核运算，执行一个价偏置过程，然后输出data_out
//////////////////////////////////////////////////////////////////////////////////
module Conv_unsign_sign#(
	parameter			bits		=	16	,
	parameter			filter_size 	= 	25	,
	parameter			filter_size_2 	=	5	
	)
	(
	//system clock
	input		 		clk_in		,
	input		 		rst_n		,
	//feature map input & bias & weight
	input signed	[bits-1:0]	data_in		,    //每次data_in一个16bit的数
	input signed    [(bits<<1)-1:0]	bias		,   //每次 bias一个 32bit的数
	input signed	[bits-1:0]	weight		,   //每次weight一个16bit的数
	//enable conv
	input 				start		,
	//deature map output 
	output reg signed		[(bits<<1)+filter_size_2:0]	data_out,     //疑惑？？？？data_out的位数设置是处于什么考虑
	//enable next module
	output reg			ready
	);
	
reg signed	[(bits<<1)-1+filter_size_2:0]	add_result; //加和的一个暂存变量，因为要不止调用一次Conv_unsign_sign函数
wire signed	[bits-1:0]			a;	//其中的一个乘数 16bit
wire signed	[bits-1:0]			b;	//另外一个个乘数 16bit
wire signed	[(bits<<1)-1:0]		        p;	//两个乘数的积 32bit
assign 	a 	= 	                        data_in;
assign 	b 	= 	                        weight;
reg 						flag;
reg 		[filter_size_2-1:0]		cnt;
reg		[1:0]				out_flag;
reg					        out_ready;
reg signed	[(bits<<1)-1+filter_size_2:0]	temp_out;//所有乘法的加和完成时，的整个加和
reg		[1:0]				out_cnt;
reg						start_delay1;
reg						start_delay2;

mult mult_16_unsign_sign (
  .clk					        (clk_in), // input clk
  .a						(a), // input [15 : 0] a
  .b						(b), // input [15 : 0] b
  .p						(p) // output [31 : 0] p
);

always@(posedge clk_in or negedge rst_n)
begin
	if(~rst_n)
	begin
		cnt 		<=	1'b0;
		add_result      <=	1'b0;
		flag	        <=	1'b0;
		temp_out        <=      0;
	end
	else
	begin
		if(start)
		begin
			start_delay1     <=	1'b1;
		end
		else
		begin
			start_delay1	 <=	1'b0;
		end
		if(start_delay1)
		begin
			start_delay2     <=	1'b1;
		end
		else
		begin
			start_delay2	 <=     1'b0;
		end		
		if(flag == 1'b1 || start_delay2 == 1'b1)
		begin
			if(cnt	==	0)
			begin
				cnt				<=	cnt	+	1'b1;
				add_result			<=      p;
				flag				<=	1'b1;
			end
			else if(cnt < filter_size-1)
			begin
				cnt				<=      cnt		+	1'b1;
				add_result			<=	add_result	+	p;
				flag				<=       1'b1;
			end
			else if(cnt == filter_size-1)
			begin
				add_result			<=	add_result	+	p;
				flag				<=      1'b0;
				temp_out			<=	add_result      +	p;
				cnt				<=      1'b0;
			end
		end
	end
end

always@(posedge clk_in or negedge rst_n)
begin
	if(~rst_n)
	begin
		out_cnt			        <=			0;
		out_ready			<=			0;
	end
	else
	begin
		out_flag 		        <=			{out_flag[0],flag};
		if(out_flag[0]&&(~flag))
		begin
			out_ready	        <=			1'b1;
		end
		if(out_ready)
		begin
			if(out_cnt == 0)
			begin
				ready				<=      1'b1;	
				data_out 			<=	temp_out  +  bias;				
				out_cnt		 		<=	out_cnt   +  1'b1;			
			end
			else if(out_cnt == 2'd1)
			begin
				out_cnt				<=	1'b0;
				out_ready			<=	1'b0;
				ready				<=      1'b0;	
			end
		end
	end
end
endmodule
