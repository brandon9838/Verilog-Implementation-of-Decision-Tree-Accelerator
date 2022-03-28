module DEC
#(parameter NUM_FEATURE=8)
(
    clk         ,
    rst_n       ,
    input_data_valid ,
    input_data_0,
	input_data_1,
	input_data_2,
	input_data_3,
	input_data_4,
	input_data_5,
	input_data_6,
	input_data_7,
	input_ID,
	input_mode  ,
    input_ready ,
    out_valid   ,
    out_ID,
	out         
);
integer i;

//IO
input clk;
input rst_n;
input input_data_valid;
input [1:0]input_mode;

input [7:0] input_data_0 ;
input [7:0] input_data_1 ;
input [7:0] input_data_2 ;
input [7:0] input_data_3 ;
input [7:0] input_data_4 ;
input [7:0] input_data_5 ;
input [7:0] input_data_6 ;
input [7:0] input_data_7 ;

input [11:0] input_ID;

output input_ready;
output reg out_valid;
output [7:0] out_ID;
output reg out;

//Memory
reg [7:0] fea_idx_sram_d_w;
wire[7:0] fea_idx_sram_q;
reg 	  fea_idx_sram_wen_w;
reg [7:0] fea_idx_sram_a_w;  

reg [7:0] thd_sram_d_w;
wire[7:0] thd_sram_q;
reg 	  thd_sram_wen_w;
reg [7:0] thd_sram_a_w;  

reg [7:0] child_sram_d_w;
wire[7:0] child_sram_q;
reg 	  child_sram_wen_w;
reg [8:0] child_sram_a_w;  

sram_256x8 fea_idx_sram(
    .D          (fea_idx_sram_d_w  ),
	.Q          (fea_idx_sram_q    ),
    .CLK        (clk          	   ),
    .CEN        (1'b0              ), 
    .WEN        (fea_idx_sram_wen_w),
    .A          (fea_idx_sram_a_w  )
    
);

sram_256x8 thd_sram(
    .D          (thd_sram_d_w  ),
	.Q          (thd_sram_q    ),
    .CLK        (clk           ),
    .CEN        (1'b0          ), 
    .WEN        (thd_sram_wen_w),
    .A          (thd_sram_a_w  )
);

sram_512x8 child_sram(
    .D          (child_sram_d_w  ),
	.Q          (child_sram_q    ),
    .CLK        (clk          	 ),
    .CEN        (1'b0            ), 
    .WEN        (child_sram_wen_w),
    .A          (child_sram_a_w  )
);


//Internal Logic
//stage 1
reg [7:0] feature_s1_w[NUM_FEATURE-1:0],feature_s1_r[NUM_FEATURE-1:0];
reg [11:0] input_ID_s1_w,input_ID_s1_r;
//reg input_ready_s1_w,input_ready_s1_r;
reg [1:0] input_mode_s1_w,input_mode_s1_r;
reg [7:0] node_s1_w,node_s1_r;

//stage 2
reg [7:0] feature_s2_w[NUM_FEATURE-1:0],feature_s2_r[NUM_FEATURE-1:0];
reg [11:0] input_ID_s2_w,input_ID_s2_r;
reg input_ready_s2_w,input_ready_s2_r;
reg [1:0] input_mode_s2_w,input_mode_s2_r;
reg [7:0] node_s2_w,node_s2_r;
//stage 3
reg [7:0] feature_s3_w[NUM_FEATURE-1:0],feature_s3_r[NUM_FEATURE-1:0];
reg [11:0] input_ID_s3_w,input_ID_s3_r;
reg [7:0] selected_feature_s2_w,selected_feature_s2_r;
reg input_ready_s3_w,input_ready_s3_r;
reg [1:0] input_mode_s3_w,input_mode_s3_r;
reg out_valid_s2_w;
reg out_s2_w;
reg [7:0] node_s3_w,node_s3_r;
//
assign input_ready=input_ready_s2_r;
assign out_ID=input_ID_s2_r;
always@(*)begin
	for(i=0;i<NUM_FEATURE;i=i+1)begin
		feature_s1_w[i]=feature_s3_r[i];
		feature_s2_w[i]=feature_s1_r[i];
		feature_s3_w[i]=feature_s2_r[i];
	end
	input_ID_s1_w=input_ID_s3_r;
	input_ID_s2_w=input_ID_s1_r;
	input_ID_s3_w=input_ID_s2_r;
	selected_feature_s2_w=selected_feature_s2_r;
	
	fea_idx_sram_d_w=0;
	fea_idx_sram_wen_w=1;
	fea_idx_sram_a_w=0;  
	thd_sram_d_w=0;
	thd_sram_wen_w=1;
	thd_sram_a_w=0;  
	child_sram_d_w=0;
	child_sram_wen_w=1;
	child_sram_a_w=0;
	
	//input_ready_s1_w=input_ready_s3_r;
	input_ready_s2_w=0;
	input_ready_s3_w=input_ready_s2_r;
	
	input_mode_s1_w=input_mode_s3_r;
	input_mode_s2_w=input_mode_s1_r;
	input_mode_s3_w=input_mode_s2_r;
	
	out_valid_s2_w=0;
	out_s2_w=0;
	
	node_s1_w=node_s3_r;
	node_s2_w=node_s1_r;
	node_s3_w=node_s2_r;
	//stage1
	if(input_data_valid && input_ready_s3_r)begin
		feature_s1_w[0]=input_data_0;
		feature_s1_w[1]=input_data_1;
		feature_s1_w[2]=input_data_2;
		feature_s1_w[3]=input_data_3;
		feature_s1_w[4]=input_data_4;
		feature_s1_w[5]=input_data_5;
		feature_s1_w[6]=input_data_6;
		feature_s1_w[7]=input_data_7;
		input_mode_s1_w=input_mode;
		// input mode == 00
		if (!(|input_mode))begin
			fea_idx_sram_d_w=input_data_0;
			fea_idx_sram_a_w=input_data_1;
			fea_idx_sram_wen_w=0;
		end
		else begin
			input_ID_s1_w=input_ID;
			fea_idx_sram_a_w=2;
			node_s1_w=2;
		end
	end
	else begin 
		fea_idx_sram_a_w=child_sram_q;
		node_s1_w=child_sram_q;
	end
	
	//stage2
	selected_feature_s2_w=feature_s1_r[fea_idx_sram_q];
	thd_sram_a_w=node_s1_r;
	if (input_mode_s1_r==2'b01)begin
		thd_sram_d_w=feature_s1_r[0];
		thd_sram_a_w=feature_s1_r[1];
		thd_sram_wen_w=0;
	end
	

	if((&input_mode_s1_r) && !(|node_s1_r[7:1]))begin
		out_valid_s2_w=1;
		out_s2_w=node_s1_r[0];
		input_ID_s2_w=0;
	end
	
	input_ready_s2_w=((&input_mode_s1_r) && (|node_s1_r[7:1]))?0:1;
	
	//stage3
	if (input_mode_s2_r==2'b10)begin
		child_sram_d_w=feature_s2_r[0];
		child_sram_a_w={{feature_s2_r[2][0]},feature_s2_r[1]};
		child_sram_wen_w=0;
	end
	else begin
		if(selected_feature_s2_r<=thd_sram_q)begin
			child_sram_a_w={node_s2_r,{1'b0}};
		end
		else begin
			child_sram_a_w={node_s2_r,{1'b1}};
		end
	end
	
end

always@(posedge clk or negedge rst_n)begin
	if (!rst_n)begin
		for(i=0;i<NUM_FEATURE;i=i+1)begin
			feature_s1_r[i]<=0;
			feature_s2_r[i]<=0;
			feature_s3_r[i]<=0;
		end
		input_ID_s1_r<=0;
		input_ID_s2_r<=0;
		input_ID_s3_r<=0;
		selected_feature_s2_r<=0;
		//Logic
		//input_ready_s1_r<=1;
		input_ready_s2_r<=1;
		input_ready_s3_r<=1;
		input_mode_s1_r<=0;
		input_mode_s2_r<=0;
		input_mode_s3_r<=0;
		out_valid<=0;
		out<=0;
		node_s1_r<=0;
		node_s2_r<=0;
		node_s3_r<=0;
	end
	else begin
		for(i=0;i<NUM_FEATURE;i=i+1)begin
			feature_s1_r[i]<=feature_s1_w[i];
			feature_s2_r[i]<=feature_s2_w[i];
			feature_s3_r[i]<=feature_s3_w[i];
		end
		input_ID_s1_r<=input_ID_s1_w;
		input_ID_s2_r<=input_ID_s2_w;
		input_ID_s3_r<=input_ID_s3_w;
		selected_feature_s2_r<=selected_feature_s2_w;

		//Logic
		//input_ready_s1_r<=input_ready_s1_w;
		input_ready_s2_r<=input_ready_s2_w;
		input_ready_s3_r<=input_ready_s3_w;
		input_mode_s1_r<=input_mode_s1_w;
		input_mode_s2_r<=input_mode_s2_w;
		input_mode_s3_r<=input_mode_s3_w;
		out_valid<=out_valid_s2_w;
		out<=out_s2_w;
		node_s1_r<=node_s1_w;
		node_s2_r<=node_s2_w;
		node_s3_r<=node_s3_w;
	end
end

endmodule


