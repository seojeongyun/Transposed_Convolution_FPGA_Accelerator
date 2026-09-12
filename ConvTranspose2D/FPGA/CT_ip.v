
`timescale 1 ns / 1 ps


	module CT_ip #
	(
		// Users to add parameters here
		//(lab12)
		parameter   FW = 4,
		parameter   FH = 4,
		//
		parameter   IW = 2,
		parameter   IH = 2,
		//
		parameter   S = 1,
		parameter   PAD = 1,
		parameter   IN_C = 1,
		parameter   OUT_C = 1,
		//
		parameter IDX_BITS = 10,
		parameter ENABLE_CNT_BITS = 3,
		//
		parameter BITS     = 8,
		parameter SIGNED_BITS = 8,
		parameter MULT_BITS = 16,
		parameter OFMAP_BITS = 32,
		//
		parameter ORIG_OW = FW + S*(IW-1),
		parameter ORIG_OH = FH + S*(IH-1),
		//
		parameter PADDED_OW = FW + S*(IW-1) - 2*PAD,
		parameter PADDED_OH = FH + S*(IH-1) - 2*PAD,
		//
		parameter OW = PAD ? FW + S*(IW-1) - 2*PAD : FW + S*(IW-1),
		parameter OH = PAD ? FH + S*(IH-1) - 2*PAD : FH + S*(IH-1),
		//
		parameter DELAY = 1,
		parameter ENABLE_DELAY = 2,
		parameter IN_PAD_REGION_DELAY = 2,
		//
		parameter   IFMAP_AWIDTH     =    10,              // if an image size is 1024, the MEM_DEPTH is 2^20.
		parameter   IFMAP_DWIDTH     =  SIGNED_BITS,
		parameter   IFMAP_MEM_DEPTH  =  IW * IH * IN_C,
		//
		parameter   WEIGHT_AWIDTH    =   10,              // 
		parameter   WEIGHT_DWIDTH    =   FW * SIGNED_BITS,
		parameter   WEIGHT_MEM_DEPTH =   IN_C * OUT_C * FH ,
		//
		parameter   OFMAP_AWIDTH     =  10,
		parameter   OFMAP_DWIDTH     =  OFMAP_BITS,
		
		// User parameters ends
		// Do not modify the parameters beyond this line
		// Parameters of Axi Slave Bus Interface S00_AXI
		parameter integer C_S00_AXI_DATA_WIDTH	= 32,
		parameter integer C_S00_AXI_ADDR_WIDTH	= 6
	)
	(
		// Users to add ports here

		// User ports ends
		// Do not modify the ports beyond this line


		// Ports of Axi Slave Bus Interface S00_AXI
		input wire  s00_axi_aclk,
		input wire  s00_axi_aresetn,
		input wire [C_S00_AXI_ADDR_WIDTH-1 : 0] s00_axi_awaddr,
		input wire [2 : 0] s00_axi_awprot,
		input wire  s00_axi_awvalid,
		output wire  s00_axi_awready,
		input wire [C_S00_AXI_DATA_WIDTH-1 : 0] s00_axi_wdata,
		input wire [(C_S00_AXI_DATA_WIDTH/8)-1 : 0] s00_axi_wstrb,
		input wire  s00_axi_wvalid,
		output wire  s00_axi_wready,
		output wire [1 : 0] s00_axi_bresp,
		output wire  s00_axi_bvalid,
		input wire  s00_axi_bready,
		input wire [C_S00_AXI_ADDR_WIDTH-1 : 0] s00_axi_araddr,
		input wire [2 : 0] s00_axi_arprot,
		input wire  s00_axi_arvalid,
		output wire  s00_axi_arready,
		output wire [C_S00_AXI_DATA_WIDTH-1 : 0] s00_axi_rdata,
		output wire [1 : 0] s00_axi_rresp,
		output wire  s00_axi_rvalid,
		input wire  s00_axi_rready
	);
	parameter   OFMAP_MEM_DEPTH  =  PAD ? (PADDED_OW * PADDED_OH * OUT_C) : (ORIG_OW * ORIG_OH * OUT_C);

	// Memory I/F
	// IFMAP MEMORY ADDRESS
	wire		[IFMAP_AWIDTH - 1 : 0] 		ifmap_bram_addr;
	wire		 							ifmap_bram_ce1;
	wire		 							ifmap_bram_we1;
	wire 		[IFMAP_DWIDTH - 1 : 0]  	ifmap_bram_q1;
	wire signed [IFMAP_DWIDTH - 1 : 0] 		ifmap_bram_d1;

	// WEIGHT MEMORY ADDRESS
	wire		[WEIGHT_AWIDTH - 1 : 0] 	weight_bram_addr;
	wire		 							weight_bram_ce1;
	wire		 							weight_bram_we1;
	wire 		[WEIGHT_DWIDTH - 1 : 0]  	weight_bram_q1;
	wire signed [WEIGHT_DWIDTH - 1 : 0] 	weight_bram_d1;

	// OFMAP MEMORY ADDRESS
	wire		[OFMAP_AWIDTH - 1 : 0] 		ofmap_bram_addr;
	wire		 							ofmap_bram_ce1;
	wire		 							ofmap_bram_we1;
	wire signed [OFMAP_DWIDTH - 1 : 0]  	ofmap_bram_q1;
	wire		[OFMAP_DWIDTH - 1 : 0] 		ofmap_bram_d1;
	
	// BRAM INIT RUN
	wire									ifmap_bram_init_run;
	wire									weight_bram_init_run;
	wire									ofmap_bram_init_run;
	//
	wire									i_run;
	wire  signed [OFMAP_BITS -1 : 0]        read_ofmap_value;                   
	// CONTROL BRAM ADDR/CE/WE FROM INITIALIZING USING AXI4-LITE AND CT MODULE

// Instantiation of Axi Bus Interface S00_AXI
	myip_v1_0_S00_AXI # ( 
		// (lab12)
		.FW                 (FW),
        .FH                 (FH),
        //                   
        .IW                 (IW),
        .IH                 (IH),
        //                   
        .S                  (S),
        .PAD                (PAD),
        .IN_C               (IN_C),
        .OUT_C              (OUT_C),
        //                   
        .IDX_BITS           (IDX_BITS),
        .ENABLE_CNT_BITS    (ENABLE_CNT_BITS),
        //                   
        .BITS               (BITS),
        .SIGNED_BITS        (SIGNED_BITS),
        .MULT_BITS          (MULT_BITS),
        .OFMAP_BITS         (OFMAP_BITS),
        //                   
        .ORIG_OW            (ORIG_OW),
        .ORIG_OH            (ORIG_OH),
        //                   
        .PADDED_OW          (PADDED_OW),
        .PADDED_OH          (PADDED_OH),
        //                   
        .OW                 (OW),
        .OH                 (OH),
        //                   
        .DELAY              (DELAY),
        .ENABLE_DELAY       (ENABLE_DELAY),
        .IN_PAD_REGION_DELAY(IN_PAD_REGION_DELAY),
		//
		.IFMAP_AWIDTH		(IFMAP_AWIDTH),
		.IFMAP_DWIDTH		(IFMAP_DWIDTH),
		.IFMAP_MEM_DEPTH	(IFMAP_MEM_DEPTH),
		//
		.WEIGHT_AWIDTH		(WEIGHT_AWIDTH),
		.WEIGHT_DWIDTH		(WEIGHT_DWIDTH),
		.WEIGHT_MEM_DEPTH	(WEIGHT_MEM_DEPTH),
		//
		.OFMAP_AWIDTH		(OFMAP_AWIDTH),
		.OFMAP_DWIDTH		(OFMAP_DWIDTH),
		//
		.C_S_AXI_DATA_WIDTH(C_S00_AXI_DATA_WIDTH),
		.C_S_AXI_ADDR_WIDTH(C_S00_AXI_ADDR_WIDTH)
	) myip_v1_0_S00_AXI_inst (
		.S_AXI_ACLK(s00_axi_aclk),
		.S_AXI_ARESETN(s00_axi_aresetn),
		.S_AXI_AWADDR(s00_axi_awaddr),
		.S_AXI_AWPROT(s00_axi_awprot),
		.S_AXI_AWVALID(s00_axi_awvalid),
		.S_AXI_AWREADY(s00_axi_awready),
		.S_AXI_WDATA(s00_axi_wdata),
		.S_AXI_WSTRB(s00_axi_wstrb),
		.S_AXI_WVALID(s00_axi_wvalid),
		.S_AXI_WREADY(s00_axi_wready),
		.S_AXI_BRESP(s00_axi_bresp),
		.S_AXI_BVALID(s00_axi_bvalid),
		.S_AXI_BREADY(s00_axi_bready),
		.S_AXI_ARADDR(s00_axi_araddr),
		.S_AXI_ARPROT(s00_axi_arprot),
		.S_AXI_ARVALID(s00_axi_arvalid),
		.S_AXI_ARREADY(s00_axi_arready),
		.S_AXI_RDATA(s00_axi_rdata),
		.S_AXI_RRESP(s00_axi_rresp),
		.S_AXI_RVALID(s00_axi_rvalid),
		.S_AXI_RREADY(s00_axi_rready),

		// IFMAP MEMORY ADDRESS
		.ifmap_bram_addr	(ifmap_bram_addr),
		.ifmap_bram_ce1		(ifmap_bram_ce1),
		.ifmap_bram_we1		(ifmap_bram_we1),
		.ifmap_bram_q1		(ifmap_bram_q1),		// 0
		.ifmap_bram_d1		(ifmap_bram_d1),

		// WEIGHT MEMORY ADDRESS
		.weight_bram_addr	(weight_bram_addr),
		.weight_bram_ce1	(weight_bram_ce1),
		.weight_bram_we1	(weight_bram_we1),
		.weight_bram_q1		(weight_bram_q1),		// 0
		.weight_bram_d1		(weight_bram_d1),

		// OFMAP MEMORY ADDRESS
		.ofmap_bram_addr	(ofmap_bram_addr),
		.ofmap_bram_ce1		(ofmap_bram_ce1),
		.ofmap_bram_we1		(ofmap_bram_we1),
		.ofmap_bram_q1		(ofmap_bram_q1),
		.ofmap_bram_d1		(ofmap_bram_d1),
		
		//
		.ifmap_bram_init_run		(ifmap_bram_init_run),
		.weight_bram_init_run		(weight_bram_init_run),
		.ofmap_bram_init_run		(ofmap_bram_init_run),
		
		//
		.i_run						(i_run),
		.are_all_channel_calcs_done	(are_all_channel_calcs_done),
		.CT_idle					(o_idle),
		.CT_load					(o_load),
		.CT_calc					(o_calc),
		.CT_save					(o_save),
		.CT_done					(o_done)
	);
	//
	wire o_idle;
	wire o_load;
	wire o_calc;
	wire o_save;
	wire o_done;
	wire are_all_channel_calcs_done;
	//
	wire [IFMAP_DWIDTH - 1 : 0] ifmap_addr;
	wire [WEIGHT_AWIDTH -1 : 0] wegt_addr;
	//
	wire ifmap_ce0;
	wire wegt_ce0;
	//
	//
	wire [IFMAP_DWIDTH - 1 : 0] ifmap_q1_;
	wire [WEIGHT_DWIDTH - 1 : 0] weight_q1_;
	//
	wire signed [IFMAP_DWIDTH - 1 : 0] ifmap_value;
	wire signed [WEIGHT_DWIDTH - 1 : 0] weight_vec;	
	//
	wire [IFMAP_AWIDTH - 1 : 0] ifmap_addr_ = ifmap_bram_init_run ? ifmap_bram_addr - 1: ifmap_addr;
	wire ifmap_ce1_ = ifmap_bram_init_run ? 1'b1 : ifmap_ce0;
	wire ifmap_we1_ = ifmap_bram_init_run ? 1'b1 : 1'b0;
	wire signed [IFMAP_DWIDTH - 1 : 0] ifmap_d1_ = ifmap_bram_init_run ? ifmap_bram_d1 : 0;
	assign ifmap_value = ifmap_q1_;
	//
	wire [WEIGHT_AWIDTH - 1 : 0] weight_addr_ = weight_bram_init_run ? weight_bram_addr - 1: wegt_addr;
	wire weight_ce1_ = weight_bram_init_run ? 1'b1 : wegt_ce0;
	wire weight_we1_ = weight_bram_init_run ? 1'b1 : 1'b0;
	wire signed [WEIGHT_DWIDTH - 1 : 0] weight_d1_ = weight_bram_init_run ? weight_bram_d1 : 0;
	assign weight_vec = weight_q1_;
	
	assign ofmap_bram_q1 = read_ofmap_value[OFMAP_DWIDTH -1 : 0];
	//
	//


	// INSTANTIATION OF BRAM
    dpbram#
    (
        .AWIDTH         (IFMAP_AWIDTH),
        .DWIDTH         (IFMAP_DWIDTH),
        .MEM_DEPTH      (IFMAP_MEM_DEPTH)
    ) ifmap_dpbram
    (
        .clk           (s00_axi_aclk),
        //
        .addr0          (ifmap_addr_),
        .ce0            (ifmap_ce1_),
        .we0            (ifmap_we1_),
        //
		.d0				(ifmap_d1_),
        .q0             (ifmap_q1_)
    );
    
    
    dpbram#
    (
        .AWIDTH         (WEIGHT_AWIDTH),
        .DWIDTH         (WEIGHT_DWIDTH),
        .MEM_DEPTH      (WEIGHT_MEM_DEPTH)
    ) weight_dpbram
    (
        .clk           (s00_axi_aclk),
        //
        .addr0          (weight_addr_),
        .ce0            (weight_ce1_),
        .we0            (weight_we1_),
        //
		.d0				(weight_d1_),
        .q0             (weight_q1_)
    );

	// CT_module 설계할 때 실수로 tb에서 ifmap과 weight를 1 cycle delay 시켰었음.
	// 그래서 그거 맞춰주려고 강제로 1 cycle delay.
	reg signed [IFMAP_DWIDTH - 1 : 0] ifmap_value__;
	reg signed [WEIGHT_DWIDTH - 1 : 0] weight_vec__;

	always @(posedge s00_axi_aclk or negedge s00_axi_aresetn) begin
        if(!s00_axi_aresetn) begin
            ifmap_value__ <= 0;
            weight_vec__ <= 0;
        end
        
        else begin
            ifmap_value__ <= ifmap_value;
            weight_vec__ <= weight_vec;
        end
    end 

	wire signed [IFMAP_DWIDTH - 1 : 0] ifmap_value__input;
	wire signed [WEIGHT_DWIDTH - 1 : 0] weight_vec__input;

	assign ifmap_value__input = ifmap_value__;
	assign weight_vec__input = weight_vec__;

	// INSTANTIATION OF CT module
	CT_module#
    (
        .FW                 (FW),
        .FH                 (FH),
        //                   
        .IW                 (IW),
        .IH                 (IH),
        //                   
        .S                  (S),
        .PAD                (PAD),
        .IN_C               (IN_C),
        .OUT_C              (OUT_C),
        //                   
        .IDX_BITS           (IDX_BITS),
        .ENABLE_CNT_BITS    (ENABLE_CNT_BITS),
        //                   
        .BITS               (BITS),
        .SIGNED_BITS        (SIGNED_BITS),
        .MULT_BITS          (MULT_BITS),
        .OFMAP_BITS         (OFMAP_BITS),
        //                   
        .ORIG_OW            (ORIG_OW),
        .ORIG_OH            (ORIG_OH),
        //                   
        .PADDED_OW          (PADDED_OW),
        .PADDED_OH          (PADDED_OH),
        //                   
        .OW                 (OW),
        .OH                 (OH),
        //                   
        .DELAY              (DELAY),
        .ENABLE_DELAY       (ENABLE_DELAY),
        .IN_PAD_REGION_DELAY(IN_PAD_REGION_DELAY),
        //                   
        .IFMAP_AWIDTH       (IFMAP_AWIDTH),
        //                   
        .WEIGHT_AWIDTH      (WEIGHT_AWIDTH),
        //                   
        .OFMAP_AWIDTH       (OFMAP_AWIDTH),
        .OFMAP_DWIDTH       (OFMAP_DWIDTH)
    )
    u0_CT_module
    (   
        .i_run              (i_run),
        .clk                (s00_axi_aclk),
        .reset_n            (s00_axi_aresetn),
		//
		.ofmap_bram_init_run(ofmap_bram_init_run),
        //
        .ifmap_value        (ifmap_value__input),
        .weight_vec         (weight_vec__input),
        //
        .row_idx            (row_idx),
        .col_idx            (col_idx),
        .in_channel_idx     (in_channel_idx),
        .out_channel_idx    (out_channel_idx),
        //
        .intermediate       (intermediate),
        //
        .o_idle             (o_idle),
        .o_load             (o_load),
        .o_calc             (o_calc),
        .o_save             (o_save),
        .o_done             (o_done),
        //
        .wegt_ce0           (wegt_ce0),
        .ifmap_ce0          (ifmap_ce0),
        //
        .captured_ifmap_row         (captured_row),
        .captured_ifmap_col         (captured_col),
        .captured_ifmap_in_channel  (captured_ifmap_in_channel),
        .captured_ifmap_out_channel (captured_ifmap_out_channel),
        //
        .wegt_addr          (wegt_addr),
        .ifmap_addr         (ifmap_addr),
		//
		.ofmap_bram_addr	(ofmap_bram_addr),
		.ofmap_bram_ce1		(ofmap_bram_ce1),
		.ofmap_bram_we1		(ofmap_bram_we1),
		.ofmap_bram_d1		(ofmap_bram_d1),
        //
        .ofmap                  (ofmap),
        .ofmap_generate_success (ofmap_generate_success),
        // DEBUG
        .are_all_channel_calcs_done   (are_all_channel_calcs_done),
		//
		.read_ofmap_value			(read_ofmap_value)
    );
	endmodule
