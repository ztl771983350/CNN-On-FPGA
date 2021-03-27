`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    15:22:02 03/11/2019 
// Design Name: 
// Module Name:    Layer1_Conv_Top 
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
/////////////////////////////
module Layer1_Conv_Top#(
	parameter					bits			=	16		,	//quantization bit number,一个数据的位数
	parameter					bits_shift		=	4		,	//we can shift but not multy
	parameter					channel_num		=	4		,
	parameter					channel_height_num	=	4		,
	parameter					channel_length_num	=	4		,
	parameter					channel_paralell_num	=	16		,
	parameter					channel_in_num 		=	16		, 
	parameter				        channel_in_num_2	=	5		,
	parameter					channel_out_num		=	64		,
//////////////////////////////////////////////卷积运算参数和池化运算层参数的分界线\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
	parameter					pool_stride_length	=	2		,
	parameter					pool_stride_height  	=	2		,
	parameter					pool_stride_num_length  =       2		,
	parameter					pool_stride_num_height  =       2		,
	parameter					pool_channel_heignt	=	2		,
	parameter				        pool_channel_length	=	2		,
	parameter					pool_channel		=	4		,
	parameter					pool_channel_bits	=	256		,
	parameter					pool_channel_bits_shift	=	8		,
	parameter 					conv_num		=	64	,//channel_num*channel_in_num，输入的16个数分别和4个卷积元素都相乘，共进行64次乘法与运算
	parameter					filter_size		=	25		,
	parameter					filter_size_2		=	5		
	)
	(
	input								clk_in,
	input 								rst_n,
	input 		[(channel_in_num<<bits_shift)-1:0]		data_in,       // 输入 data_in 为16个16bit的数，也就是一口气输入16*16位的数据串
	input								start,
	input		[(channel_num<<bits_shift)-1:0]			weights,       // 输入4个16bit权重个数，和输入的数据个数相同，都是4个16bit的数。
	output	reg 	[(channel_out_num<<bits_shift)-1:0]   		data_out,      // 输出16个16bit data_out是16个16bit的数
	output								ready
    );

wire				[bits-1:0]				data_in_conv			[0:channel_in_num-1]	;  //16个16bit的存储器阵列
wire				[bits-1:0]				weight_in_conv			[0:channel_num-1]	;  //一次权重4个16bit，每个卷积核一个
wire	signed			[(bits<<1)-1+filter_size_2:0]		data_conv			[0:conv_num-1]		;  //存着16个数和4个卷积元素全相乘的64个数
wire									ready_conv			[0:conv_num-1]		;
assign 									ready		=	ready_conv[0]			;
wire	signed			[(bits<<1)-1:0]	bias			[0:channel_num-1]		;//每个卷积核专属的一个bias，也就是4个32位的bias
wire				[pool_channel_bits-1:0]data_temp	[0:pool_channel-1]		;
assign				bias[3]		=			32'b00100010001011000011010000000000	;																				 
assign				bias[2]		=			32'b00000110100101101100110010111000	;
assign				bias[1]		=			32'b00001001111010011000011110110000	;
assign				bias[0]		=			32'b00011001011001001000001101100000	;
genvar i,j,k,l,r,s,t,u,v;
generate
	for(i = 0; i < channel_num; i = i + 1)           //4个卷积核的遍历循环
	begin:conv_channel
		for(l = 0; l < channel_in_num; l = l + 1)    //对输入16个16bit的data_in的循环，接入模块 Conv_unsign_sign 
		               				      					    //（专门对a和b进行乘法运算，然后进行加法，25次即卷积核大小次乘法运算后，再加偏置）
		begin:conv_in_channel
			Conv_unsign_sign layer_conv(
				.clk_in			(clk_in)					,
				.rst_n			(rst_n)					,
				.data_in		(data_in_conv[l])		,	
				.weight			(weight_in_conv[i])	,
				.bias			(bias[i])				,
//				.weight			(1),
//				.bias			(0),
				.start			(start)					,
				.data_out		(data_conv[i*channel_in_num+l])				,
				.ready			(ready_conv[i*channel_in_num+l])
				);
		end
	end
	
	for (r = 0; r < pool_channel_heignt; r = r + 1)
	begin:data_temp1
		for (s = 0; s < pool_channel_length; s = s + 1)
		begin:data_temp2
			for (v = 0; v < channel_num; v = v + 1)
			begin:data_temp3
				for (t = 0; t < pool_stride_num_height; t = t + 1)
				begin:data_temp4
					for (u = 0; u < pool_stride_num_length; u = u + 1)
					begin:data_temp5
						assign data_temp[r*pool_channel_length+s][((v*pool_stride_num_length*pool_stride_num_height+(t*pool_stride_num_length+u))<<bits_shift)+bits-1:((v*pool_stride_num_length*pool_stride_num_height+(t*pool_stride_num_length+u))<<bits_shift)]    =
								 (data_conv[v*channel_in_num+((r*pool_stride_num_height+t)*pool_channel_length*pool_stride_num_length+s*pool_stride_num_length+u)]>0)?
								 data_conv[v*channel_in_num+((r*pool_stride_num_height+t)*pool_channel_length*pool_stride_num_length+s*pool_stride_num_length+u)][(bits<<1)+1:bits+1]:0;
					end
				end
			end
		end
	end
	for (l = 0; l < pool_channel; l = l + 1) 
	begin:output_data
		always@(posedge clk_in)
		begin
			data_out[(l<<pool_channel_bits_shift)+pool_channel_bits-1:(l<<pool_channel_bits_shift)]		<=		data_temp[l]	;
		end
	end
	
	for(j = 0; j < channel_in_num; j = j + 1)
	begin:conv_data_in
		assign data_in_conv[j]			=			data_in[(j<<bits_shift)+bits-1:(j<<bits_shift)]	;
	end
	
	for(k = 0; k < channel_num; k = k + 1)
	begin:conv_parameters_in
		assign weight_in_conv[k]		=			weights[(k<<bits_shift)+bits-1:(k<<bits_shift)]	;
	end
endgenerate	

integer w_file;
initial w_file = $fopen("mult1_1.txt");
always @(*)
begin
    $fdisplay(w_file,"%d",data_out[255:240]);
end
endmodule
