`timescale 1ns/10ps
`define SDFFILE     "./DEC_syn.sdf"        // Modify your sdf file name

`define PERIOD  10                          // You can modify the clock period to improve the design performance
`define NUM_FEATURE 8
`define NUM_NODE 11
`define NUM_DATA 2874
`define MAX_LATENCY 1000000



module tb;
    // input
    reg clk;
    reg rst_n;
    reg input_data_valid;
    reg [7:0]input_data_0; // feature 0 also served as parameter input
	reg [7:0]input_data_1; // feature 1,2 also served as memory address
	reg [7:0]input_data_2;
	reg [7:0]input_data_3;
	reg [7:0]input_data_4;
	reg [7:0]input_data_5;
	reg [7:0]input_data_6;
	reg [7:0]input_data_7;	
    reg [11:0]input_ID;
	
	reg [1:0] input_mode;  // 00: input feature index 01: input threshold 10: input children 11: input data
	
	// otuput
    wire input_ready;
	reg input_ready_r; 	   //assumes the host takes 1 cycle to prepare the data.   
    wire out_valid;
	wire [11:0]out_ID;
    wire out;

    // memory used to store test data
    reg [7:0]data_mem[0:`NUM_FEATURE*`NUM_DATA-1];
	reg ans_mem[0:`NUM_DATA-1];
	reg [7:0]child_mem[0:2*`NUM_NODE-1];
	reg [7:0]feature_mem[0:`NUM_NODE-1];
	reg [7:0]threshold_mem[0:`NUM_NODE-1];
	reg out_mem[0:`NUM_DATA-1];

    integer i,j,k,l;
    integer input_count;
    integer out_count;
	integer stage_count;

    DEC #(.NUM_FEATURE(`NUM_FEATURE)) u_DEC(
        .clk            (clk),
        .rst_n          (rst_n),
        .input_data_valid    (input_data_valid),
        .input_data_0(input_data_0),
		.input_data_1(input_data_1),
		.input_data_2(input_data_2),
		.input_data_3(input_data_3),
		.input_data_4(input_data_4),
		.input_data_5(input_data_5),
		.input_data_6(input_data_6),
		.input_data_7(input_data_7),
		.input_ID(input_ID),
		.input_mode     (input_mode),
        .input_ready    (input_ready),
        .out_valid      (mv_valid),
		.out_ID			(out_ID),
        .out            (out)
    );

    `ifdef SDF
       initial $sdf_annotate(`SDFFILE, u_DEC );
    `endif

    initial begin // mem initialization
        $readmemh ("../data/data.hex", data_mem);
		$readmemh ("../data/ans.hex", ans_mem);
		$readmemh ("../data/child.hex", child_mem);
		$readmemh ("../data/fea.hex", feature_mem);
		$readmemh ("../data/thd.hex", threshold_mem);
    end
	
    initial begin //dump waveform
        $fsdbDumpfile("DEC.fsdb");
        $fsdbDumpvars;
        $fsdbDumpMDA;
    end
	
	/*
	initial begin
	    $dumpfile("DEC2.vcd");
	    $dumpvars;
	end
	*/
    initial begin
        clk = 0;
        rst_n = 1;
        input_data_valid = 0;
		input_mode =0;
        input_data_0 =0;
		input_data_1 =0;
		input_data_2 =0;
		input_data_3 =0;
		input_data_4 =0;
		input_data_5 =0;
		input_data_6 =0;
		input_data_7 =0;
		input_ID =0;
		
        input_count = 0;
		stage_count = 0;
        out_count = 0;
    end

    always begin #(`PERIOD/2) clk = ~clk; end
	initial begin
		while(1)@(posedge clk)begin
			input_ready_r=input_ready;
		end
	end
    // input state
    initial begin
        $display("-----------------------------------------------------\n");
        $display("START!!! Simulation Start .....\n");
        $display("-----------------------------------------------------\n");
        #7 rst_n = 0;
        #`PERIOD rst_n = 1;
		
        repeat(2)@(negedge clk);
        
        // 00: input feature index 01: input threshold 10: input children 11: input data
		while(1) begin 
			@(negedge clk);
			if (input_ready_r==1)begin
				if (stage_count == 0) begin
					input_data_valid = 1;
					input_mode=0;
					input_data_0=feature_mem[input_count];
					input_data_1=input_count;
					if (input_count==`NUM_NODE-1)begin
						stage_count=1;
						input_count=0;
					end
					else begin
						input_count=input_count+1;
					end
				end
				else if (stage_count == 1) begin
					input_data_valid = 1;
					input_mode=1;
					input_data_0=threshold_mem[input_count];
					input_data_1=input_count;
					if (input_count==`NUM_NODE-1)begin
						stage_count=2;
						input_count=0;
					end
					else begin
						input_count=input_count+1;
					end
				end
				else if (stage_count == 2) begin
					input_data_valid = 1;
					input_mode=2;
					input_data_0=child_mem[input_count];
					input_data_1=input_count;
					input_data_2=input_count[8];
					if (input_count==`NUM_NODE*2-1)begin
						stage_count=3;
						input_count=0;
						
					end
					else begin
						input_count=input_count+1;
					end
				end
				else begin
					input_data_valid = 1;
					input_mode=3;
					input_data_0 = data_mem[input_count*8];
					input_data_1 = data_mem[input_count*8+1];
					input_data_2 = data_mem[input_count*8+2];
					input_data_3 = data_mem[input_count*8+3];
					input_data_4 = data_mem[input_count*8+4];
					input_data_5 = data_mem[input_count*8+5];
					input_data_6 = data_mem[input_count*8+6];
					input_data_7 = data_mem[input_count*8+7];
					input_ID=input_count;
					
					if (input_count==`NUM_DATA-1)begin
						input_mode=3;
					end
					else begin
						input_count=input_count+1;
					end
				end
			end
        end
    end

    //output state
    initial begin

        @(negedge rst_n);
        while(1) begin
            @(negedge clk);
            if (mv_valid) begin

                if (|out === 1'dx) begin
                    $display("================ Failed... Encounter unknown output data!!!================");
                    $finish;
                end

                out_mem[out_ID] = out;
                if (out!=ans_mem[out_ID])begin
					$display("Wrong output!");
					$display("Answer %d is %d", out_count, ans_mem[out_count]);
					$display("Output is %d", out);
					$finish;
				end
				
                if (out_count==`NUM_DATA-1) begin
                    you_pass_image;
					$finish;
                end
                
				out_count = out_count + 1;
            end
        end
    end

    initial begin
        repeat(`MAX_LATENCY)@(negedge clk);
        $display("Error!!! The simulation can't be terminated under normal operation!\n");
        $finish;
    end

    task you_pass_image;
    begin
		for (i=0;i<`NUM_DATA;i=i+1)begin
			if (out_mem[i]!=ans_mem[i])begin
				$display("The answer %d is wrong", i);
				$finish;
			end
		end
        $display("PASS");
    end
    endtask

endmodule