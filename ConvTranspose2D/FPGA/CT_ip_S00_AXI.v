
`timescale 1 ns / 1 ps

module CT_ip_S00_AXI #
(
	// Users to add parameters here
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
	parameter OFMAP_BITS = 20,
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

	// Width of S_AXI data bus
	parameter integer C_S_AXI_DATA_WIDTH	= 32,
	// Width of S_AXI address bus
	parameter integer C_S_AXI_ADDR_WIDTH	= 6
)
(
	// Global Clock Signal
	input wire  S_AXI_ACLK, 	// Global Reset Signal. This Signal is Active LOW
	input wire  S_AXI_ARESETN,	// Write address (issued by master, acceped by Slave)
	
	
	// -*-*-*-* ADDRESS WRITE -*-*-*-*
	input wire [C_S_AXI_ADDR_WIDTH-1 : 0] S_AXI_AWADDR,
	// Write channel Protection type. This signal indicates the
		// privilege and security level of the transaction, and whether
		// the transaction is a data access or an instruction access.
	input wire [2 : 0] S_AXI_AWPROT,
	// Write address valid. This signal indicates that the master signaling
		// valid write address and control information.
	input wire  S_AXI_AWVALID,
	// Write address ready. This signal indicates that the slave is ready
		// to accept an address and associated control signals.
	output wire  S_AXI_AWREADY,
	// Write data (issued by master, acceped by Slave) 


	// -*-*-*-* DATA WRITE -*-*-*-*
	input wire [C_S_AXI_DATA_WIDTH-1 : 0] S_AXI_WDATA, // C_S_AXI_DATA_WIDTH
	// Write strobes. This signal indicates which byte lanes hold
		// valid data. There is one write strobe bit for each eight
		// bits of the write data bus.    
	input wire [(C_S_AXI_DATA_WIDTH/8)-1 : 0] S_AXI_WSTRB,
	// Write valid. This signal indicates that valid write
		// data and strobes are available.
	input wire  S_AXI_WVALID,
	// Write ready. This signal indicates that the slave
		// can accept the write data.
	output wire  S_AXI_WREADY,
	// Write response. This signal indicates the status
		// of the write transaction.

	
	// -*-*-*-* DATA WRITE CHECK -*-*-*-*
	output wire [1 : 0] S_AXI_BRESP,
	// Write response valid. This signal indicates that the channel
		// is signaling a valid write response.
	output wire  S_AXI_BVALID,
	// Response ready. This signal indicates that the master
		// can accept a write response.
	input wire  S_AXI_BREADY,
	// Read address (issued by master, acceped by Slave)


	// -*-*-*-* READ ADDRESS -*-*-*-*
	input wire [C_S_AXI_ADDR_WIDTH-1 : 0] S_AXI_ARADDR,
	// Protection type. This signal indicates the privilege
		// and security level of the transaction, and whether the
		// transaction is a data access or an instruction access.
	input wire [2 : 0] S_AXI_ARPROT,
	// Read address valid. This signal indicates that the channel
		// is signaling valid read address and control information.
	input wire  S_AXI_ARVALID,
	// Read address ready. This signal indicates that the slave is
		// ready to accept an address and associated control signals.
	output wire  S_AXI_ARREADY,
	// Read data (issued by slave)


	// -*-*-*-* READ DATA -*-*-*-*
	output wire [C_S_AXI_DATA_WIDTH-1 : 0] S_AXI_RDATA,
	// Read response. This signal indicates the status of the
		// read transfer.
	output wire [1 : 0] S_AXI_RRESP,
	// Read valid. This signal indicates that the channel is
		// signaling the required read data.
	output wire  S_AXI_RVALID,
	// Read ready. This signal indicates that the master can
		// accept the read data and response information.
	input wire  S_AXI_RREADY,

	// IFMAP MEMORY ADDRESS
	output		[IFMAP_AWIDTH - 1 : 0] 		ifmap_bram_addr,
	output		 							ifmap_bram_ce1,
	output		 							ifmap_bram_we1,
	input 		[IFMAP_DWIDTH - 1 : 0]  	ifmap_bram_q1,
	output signed [IFMAP_DWIDTH - 1 : 0] 		ifmap_bram_d1,

	// WEIGHT MEMORY ADDRESS
	output		[WEIGHT_AWIDTH - 1 : 0] 	weight_bram_addr,
	output		 							weight_bram_ce1,
	output		 							weight_bram_we1,
	input 		[WEIGHT_DWIDTH - 1 : 0]  	weight_bram_q1,
	output signed [WEIGHT_DWIDTH - 1 : 0] 	weight_bram_d1,

	// OFMAP MEMORY ADDRESS
	output		[OFMAP_AWIDTH - 1 : 0] 		ofmap_bram_addr,
	output		 							ofmap_bram_ce1,
	output		 							ofmap_bram_we1,
	input signed[OFMAP_DWIDTH - 1 : 0]  	ofmap_bram_q1,
	output		[OFMAP_DWIDTH - 1 : 0] 		ofmap_bram_d1,

	//
	output reg ifmap_bram_init_run,
	output reg weight_bram_init_run,
	output ofmap_bram_init_run,
	//
	output	i_run,
	input	are_all_channel_calcs_done,

	input	CT_idle,
	input 	CT_load,
	input 	CT_calc,
	input 	CT_save,
	input	CT_done
);
	parameter   OFMAP_MEM_DEPTH  =  PAD ? (PADDED_OW * PADDED_OH * OUT_C) : (ORIG_OW * ORIG_OH * OUT_C);

	// AXI4LITE signals
	reg [C_S_AXI_ADDR_WIDTH-1 : 0] 	axi_awaddr;
	reg  							axi_awready;
	
	reg  							axi_wready;
	
	reg [1 : 0] 					axi_bresp;
	reg  							axi_bvalid;
	
	reg [C_S_AXI_ADDR_WIDTH-1 : 0] 	axi_araddr;
	reg  							axi_arready;
	reg [C_S_AXI_DATA_WIDTH-1 : 0] 	axi_rdata;
	reg [1 : 0] 					axi_rresp;
	reg  	axi_rvalid;
	reg  	axi_rvalid_d; // (lab12) delay 1 cycle from bram read

	// Example-specific design signals
	// local parameter for addressing 32 bit / 64 bit C_S_AXI_DATA_WIDTH
	// ADDR_LSB is used for addressing 32/64 bit registers/memoriess
	// ADDR_LSB = 2 for 32 bits (n downto 2)
	// ADDR_LSB = 3 for 64 bits (n downto 3)
	localparam integer ADDR_LSB = (C_S_AXI_DATA_WIDTH/32) + 1;
	localparam integer OPT_MEM_ADDR_BITS = 1 + 2;
	//----------------------------------------------
	//-- Signals for user logic register space example
	//------------------------------------------------
	//-- Number of Slave Registers 4
	reg [C_S_AXI_DATA_WIDTH-1:0]	slv_reg0;
	reg signed [C_S_AXI_DATA_WIDTH-1:0]	slv_reg1;
	reg [C_S_AXI_DATA_WIDTH-1:0]	slv_reg2;
	reg signed [C_S_AXI_DATA_WIDTH-1:0]	slv_reg3;
	reg [C_S_AXI_DATA_WIDTH-1:0]	slv_reg4;
	reg [C_S_AXI_DATA_WIDTH-1:0]	slv_reg5;
	reg [C_S_AXI_DATA_WIDTH-1:0]	slv_reg6;
	reg [C_S_AXI_DATA_WIDTH-1:0]	slv_reg7;
	reg [C_S_AXI_DATA_WIDTH-1:0]	slv_reg8;
	reg [C_S_AXI_DATA_WIDTH-1:0]	slv_reg9;
	reg [C_S_AXI_DATA_WIDTH-1:0]	slv_rega;
	reg [C_S_AXI_DATA_WIDTH-1:0]	slv_regb;
	reg [C_S_AXI_DATA_WIDTH-1:0]	slv_regc;
	reg [C_S_AXI_DATA_WIDTH-1:0]	slv_regd;
	reg [C_S_AXI_DATA_WIDTH-1:0]	slv_rege;
	reg [C_S_AXI_DATA_WIDTH-1:0]	slv_regf;
	//
	wire	 slv_reg_rden; 	// read_enable
	wire	 slv_reg_wren;	// write_enable
	//
	reg [C_S_AXI_DATA_WIDTH-1:0]	 reg_data_out;
	integer	 byte_index;
	reg	 aw_en;

	// I/O Connections assignments

	assign S_AXI_AWREADY	= axi_awready;
	assign S_AXI_WREADY	= axi_wready;
	assign S_AXI_BRESP	= axi_bresp;
	assign S_AXI_BVALID	= axi_bvalid;
	assign S_AXI_ARREADY	= axi_arready;
	assign S_AXI_RDATA	= axi_rdata;
	assign S_AXI_RRESP	= axi_rresp;
	//assign S_AXI_RVALID	= axi_rvalid;
	assign S_AXI_RVALID	= axi_rvalid_d; // (lab12) delay 1 cycle from bram read
	// Implement axi_awready generation
	// axi_awready is asserted for one S_AXI_ACLK clock cycle when both
	// S_AXI_AWVALID and S_AXI_WVALID are asserted. axi_awready is
	// de-asserted when reset is low.

	always @( posedge S_AXI_ACLK )
	begin
	  if ( S_AXI_ARESETN == 1'b0 )
	    begin
	      axi_awready <= 1'b0;
	      aw_en <= 1'b1;
	    end 
	  else
	    begin    
	      if (~axi_awready && S_AXI_AWVALID && S_AXI_WVALID && aw_en)
	        begin
	          // slave is ready to accept write address when 
	          // there is a valid write address and write data
	          // on the write address and data bus. This design 
	          // expects no outstanding transactions. 
	          axi_awready <= 1'b1;
	          aw_en <= 1'b0;
	        end
	        else if (S_AXI_BREADY && axi_bvalid)
	            begin
	              aw_en <= 1'b1;
	              axi_awready <= 1'b0;
	            end
	      else           
	        begin
	          axi_awready <= 1'b0;
	        end
	    end 
	end       

	// Implement axi_awaddr latching
	// This process is used to latch the address when both 
	// S_AXI_AWVALID and S_AXI_WVALID are valid. 

	always @( posedge S_AXI_ACLK )
	begin
	  if ( S_AXI_ARESETN == 1'b0 )
	    begin
	      axi_awaddr <= 0;
	    end 
	  else
	    begin    
	      if (~axi_awready && S_AXI_AWVALID && S_AXI_WVALID && aw_en)
	        begin
	          // Write Address latching 
	          axi_awaddr <= S_AXI_AWADDR;
	        end
	    end 
	end       

	// Implement axi_wready generation
	// axi_wready is asserted for one S_AXI_ACLK clock cycle when both
	// S_AXI_AWVALID and S_AXI_WVALID are asserted. axi_wready is 
	// de-asserted when reset is low. 

	always @( posedge S_AXI_ACLK )
	begin
	  if ( S_AXI_ARESETN == 1'b0 )
	    begin
	      axi_wready <= 1'b0;
	    end 
	  else
	    begin    
	      if (~axi_wready && S_AXI_WVALID && S_AXI_AWVALID && aw_en )
	        begin
	          // slave is ready to accept write data when 
	          // there is a valid write address and write data
	          // on the write address and data bus. This design 
	          // expects no outstanding transactions. 
	          axi_wready <= 1'b1;
	        end
	      else
	        begin
	          axi_wready <= 1'b0;
	        end
	    end 
	end        

	// Implement memory mapped register select and write logic generation
	// The write data is accepted and written to memory mapped registers when
	// axi_awready, S_AXI_WVALID, axi_wready and S_AXI_WVALID are asserted. Write strobes are used to
	// select byte enables of slave registers while writing.
	// These registers are cleared when reset (active low) is applied.
	// Slave register write enable is asserted when valid address and data are available
	// and the slave is ready to accept the write address and write data.
	assign slv_reg_wren = axi_wready && S_AXI_WVALID && axi_awready && S_AXI_AWVALID;

	always @( posedge S_AXI_ACLK )
	begin
	  if ( S_AXI_ARESETN == 1'b0 )
	    begin
	      slv_reg0 <= 0;  	// 0x00 -> ifmap bram addr set to zero
	      slv_reg1 <= 0;	// 0x04 -> data write to ifmap bram
	      slv_reg2 <= 0;	// 0x08 -> weight bram addr set to zero
	      slv_reg3 <= 0;	// 0x0c -> data write to weight bram
		//   slv_reg4 = 0;	// 0x10 -> fsm state check
		  slv_reg5 <= 0;	// 0x14	-> ofmap bram addr set to zero
		  slv_reg6 <= 0;	// 0x18 -> gen_ifmap_bram_init_run
		  slv_reg7 <= 0;	// 0x1c -> gen_weight_bram_init_run
		  slv_reg8 <= 0;	// 0x20 -> data write to ofmap bram
		  slv_reg9 <= 0;	// 0x24 -> gen_i_run
		  slv_rega <= 0;	// 0x28 -> gen_ofmap_bram_init_run
		  slv_regb <= 0;	// 0x2c -> read data from ofmap bram
		//   slv_regc <= 0;	// 0x30 -> for debug
		//   slv_regd <= 0;	// 0x34 -> for debug
		//   slv_rege <= 0;	// 0x38 -> for debug
		//   slv_regf <= 0;	// 0x3c -> for debug
	    end 
	  else begin
	    if (slv_reg_wren)
	      begin
	        case ( axi_awaddr[ADDR_LSB+OPT_MEM_ADDR_BITS:ADDR_LSB] )
	          4'h0:
	            for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
	              if ( S_AXI_WSTRB[byte_index] == 1 ) begin
	                // Respective byte enables are asserted as per write strobes 
	                // Slave register 0
	                slv_reg0[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
	              end  
	          4'h1:
	            for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
	              if ( S_AXI_WSTRB[byte_index] == 1 ) begin
	                // Respective byte enables are asserted as per write strobes 
	                // Slave register 1
	                slv_reg1[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
	              end  
	          4'h2:
	            for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
	              if ( S_AXI_WSTRB[byte_index] == 1 ) begin
	                // Respective byte enables are asserted as per write strobes 
	                // Slave register 2
	                slv_reg2[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
	              end  
	          4'h3:
	            for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
	              if ( S_AXI_WSTRB[byte_index] == 1 ) begin
	                // Respective byte enables are asserted as per write strobes 
	                // Slave register 3
	                slv_reg3[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
	              end 
			//   4'h4:
	        //     for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
	        //       if ( S_AXI_WSTRB[byte_index] == 1 ) begin
	        //         // Respective byte enables are asserted as per write strobes 
	        //         // Slave register 3
	        //         slv_reg4[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
	        //       end
	          4'h5:
	            for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
	              if ( S_AXI_WSTRB[byte_index] == 1 ) begin
	                // Respective byte enables are asserted as per write strobes 
	                // Slave register 3
	                slv_reg5[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
	              end
	          4'h6:
	            for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
	              if ( S_AXI_WSTRB[byte_index] == 1 ) begin
	                // Respective byte enables are asserted as per write strobes 
	                // Slave register 3
	                slv_reg6[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
	              end 
	          4'h7:
	            for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
	              if ( S_AXI_WSTRB[byte_index] == 1 ) begin
	                // Respective byte enables are asserted as per write strobes 
	                // Slave register 3
	                slv_reg7[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
	              end 
	          4'h8:
	            for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
	              if ( S_AXI_WSTRB[byte_index] == 1 ) begin
	                // Respective byte enables are asserted as per write strobes 
	                // Slave register 3
	                slv_reg8[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
	              end  
	          4'h9:
	            for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
	              if ( S_AXI_WSTRB[byte_index] == 1 ) begin
	                // Respective byte enables are asserted as per write strobes 
	                // Slave register 1
	                slv_reg9[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
	              end  
	          4'ha:
	            for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
	              if ( S_AXI_WSTRB[byte_index] == 1 ) begin
	                // Respective byte enables are asserted as per write strobes 
	                // Slave register 2
	                slv_rega[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
	              end  
	          4'hb:
	            for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
	              if ( S_AXI_WSTRB[byte_index] == 1 ) begin
	                // Respective byte enables are asserted as per write strobes 
	                // Slave register 3
	                slv_regb[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
	              end  
	        //   4'hc:
	        //     for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
	        //       if ( S_AXI_WSTRB[byte_index] == 1 ) begin
	        //         // Respective byte enables are asserted as per write strobes 
	        //         // Slave register 3
	        //         slv_regc[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
	        //       end
	        //   4'hd:
	        //     for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
	        //       if ( S_AXI_WSTRB[byte_index] == 1 ) begin
	        //         // Respective byte enables are asserted as per write strobes 
	        //         // Slave register 3
	        //         slv_regd[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
	        //       end
	        //   4'he:
	        //     for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
	        //       if ( S_AXI_WSTRB[byte_index] == 1 ) begin
	        //         // Respective byte enables are asserted as per write strobes 
	        //         // Slave register 3
	        //         slv_rege[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
	        //       end
	        //   4'hf:
	        //     for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
	        //       if ( S_AXI_WSTRB[byte_index] == 1 ) begin
	        //         // Respective byte enables are asserted as per write strobes 
	        //         // Slave register 3
	        //         slv_regf[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
	        //   	end
	          default : begin
	                      slv_reg0 <= slv_reg0;
	                      slv_reg1 <= slv_reg1; // (lab10) Not use Write in 0x04 (STATUS, READ Only)
	                      slv_reg2 <= slv_reg2;
	                      slv_reg3 <= slv_reg3;
						//   slv_reg4 <= slv_reg4;
						  slv_reg5 <= slv_reg5;
						  slv_reg6 <= slv_reg6;
						  slv_reg7 <= slv_reg7;
						  slv_reg8 <= slv_reg8;
						  slv_reg9 <= slv_reg9;
						  slv_rega <= slv_rega;
						  slv_regb <= slv_regb;
						//   slv_regc <= slv_regc;
						//   slv_regd <= slv_regd;
						//   slv_rege <= slv_rege;
						//   slv_regf <= slv_regf;
	                    end
	        endcase
	      end
	  end
	end   
	//


	//
	wire clk = S_AXI_ACLK;
	wire reset_n = S_AXI_ARESETN;

	wire [C_S_AXI_ADDR_WIDTH-1:0]   reg_0_ifmap_bram_addr_clr = 'h00;
	wire [C_S_AXI_ADDR_WIDTH-1:0]   reg_1_ifmap_bram_data_push = 'h04;
	//
	wire [C_S_AXI_ADDR_WIDTH-1:0]   reg_2_weight_bram_addr_clr = 'h08;
	wire [C_S_AXI_ADDR_WIDTH-1:0]   reg_3_weight_bram_data_push = 'h0c;
	//
	wire [C_S_AXI_ADDR_WIDTH-1:0]   reg_5_ofmap_bram_addr_clr = 'h14;
	wire [C_S_AXI_ADDR_WIDTH-1:0]   reg_8_ofmap_bram_data_push = 'h20;
	wire [C_S_AXI_ADDR_WIDTH-1:0]	reg_11_ofmap_bram_data_read = 'h2c;
	//
	//
	//
	wire [IFMAP_AWIDTH-1:0]	ifmap_bram_addr_reg = slv_reg0[IFMAP_AWIDTH-1:0];  // To clear ifmap_bram_ADDR
	wire signed [IFMAP_DWIDTH-1:0]	ifmap_bram_data_reg = slv_reg1[IFMAP_DWIDTH-1:0];  // ifmap_bram_data

	wire [WEIGHT_AWIDTH-1:0] weight_bram_addr_reg = slv_reg2[WEIGHT_AWIDTH-1:0];  // To clear weight_bram_ADDR
	wire signed [WEIGHT_DWIDTH-1:0] weight_bram_data_reg = slv_reg3[WEIGHT_DWIDTH-1:0];  // weight_bram_data 

	wire [OFMAP_AWIDTH-1:0]	ofmap_bram_addr_reg = slv_reg5[OFMAP_AWIDTH-1:0];  // To clear ifmap_bram_ADDR
	wire [OFMAP_DWIDTH-1:0]	ofmap_bram_data_reg = slv_reg8[OFMAP_DWIDTH-1:0];
	// wire [C_S_AXI_DATA_WIDTH-1:0]	ofmap_bram_data_reg = S_AXI_WDATA;  // ifmap_bram_data
	//
	//
	wire ifmap_bram_addr_write_hit = slv_reg_wren && (axi_awaddr[ADDR_LSB+OPT_MEM_ADDR_BITS:ADDR_LSB] == reg_0_ifmap_bram_addr_clr[ADDR_LSB+OPT_MEM_ADDR_BITS:ADDR_LSB]);
	wire ifmap_bram_data_write_hit = slv_reg_wren && (axi_awaddr[ADDR_LSB+OPT_MEM_ADDR_BITS:ADDR_LSB] == reg_1_ifmap_bram_data_push[ADDR_LSB+OPT_MEM_ADDR_BITS:ADDR_LSB]);
	//
	wire weight_bram_addr_write_hit = slv_reg_wren && (axi_awaddr[ADDR_LSB+OPT_MEM_ADDR_BITS:ADDR_LSB] == reg_2_weight_bram_addr_clr[ADDR_LSB+OPT_MEM_ADDR_BITS:ADDR_LSB]);
	wire weight_bram_data_write_hit = slv_reg_wren && (axi_awaddr[ADDR_LSB+OPT_MEM_ADDR_BITS:ADDR_LSB] == reg_3_weight_bram_data_push[ADDR_LSB+OPT_MEM_ADDR_BITS:ADDR_LSB]);
	//
	wire ofmap_bram_data_read_hit = slv_reg_rden && (axi_araddr[ADDR_LSB+OPT_MEM_ADDR_BITS:ADDR_LSB] == reg_11_ofmap_bram_data_read[ADDR_LSB+OPT_MEM_ADDR_BITS:ADDR_LSB]);
	wire ofmap_bram_addr_write_hit = slv_reg_wren && (axi_awaddr[ADDR_LSB+OPT_MEM_ADDR_BITS:ADDR_LSB] == reg_5_ofmap_bram_addr_clr[ADDR_LSB+OPT_MEM_ADDR_BITS:ADDR_LSB]);
	wire ofmap_bram_data_write_hit = slv_reg_wren && (axi_awaddr[ADDR_LSB+OPT_MEM_ADDR_BITS:ADDR_LSB] == reg_8_ofmap_bram_data_push[ADDR_LSB+OPT_MEM_ADDR_BITS:ADDR_LSB]);	

	//
	//
	//

	// generation_i_run : reg9
	// reg [ENABLE_CNT_BITS - 1 : 0] i_run_cnt;  // ENABLE_CNT_BITS = 3
	reg i_run_cnt;
	wire [C_S_AXI_ADDR_WIDTH-1:0] reg_9_i_run_generation = 'h24;
	
	always @(posedge clk or negedge reset_n) begin
		if(!reset_n) i_run_cnt <= 1'b0;
		else if(axi_awaddr[ADDR_LSB+OPT_MEM_ADDR_BITS:ADDR_LSB] == reg_9_i_run_generation[ADDR_LSB+OPT_MEM_ADDR_BITS:ADDR_LSB]) i_run_cnt <= slv_reg9;
	end

	assign i_run = ((axi_awaddr[ADDR_LSB+OPT_MEM_ADDR_BITS:ADDR_LSB] == reg_9_i_run_generation[ADDR_LSB+OPT_MEM_ADDR_BITS:ADDR_LSB]) && i_run_cnt == 0) ? 1'b1 : 1'b0;
//
//
//
	// ifmap_bram_init_run : reg6
	wire [C_S_AXI_ADDR_WIDTH-1:0] reg_6_ifmap_bram_init_run = 'h18;
	reg	[IFMAP_AWIDTH-1:0] ifmap_addr_cnt;
	reg ifmap_addr_cnt_trig;
	//
	always @(posedge clk or negedge reset_n) begin
	    if(!reset_n) begin
	        ifmap_addr_cnt <= 0;
			ifmap_bram_init_run <= 1'b0;
			ifmap_addr_cnt_trig <= 1'b0;
		end  
		
		else if (ifmap_bram_addr_write_hit) begin
	        ifmap_addr_cnt <= ifmap_bram_addr_reg;
		end 

		else if(axi_awaddr[ADDR_LSB+OPT_MEM_ADDR_BITS:ADDR_LSB] == reg_6_ifmap_bram_init_run[ADDR_LSB+OPT_MEM_ADDR_BITS:ADDR_LSB]) begin
			ifmap_bram_init_run <= slv_reg6;
		end
		
		else if (ifmap_bram_init_run && ifmap_addr_cnt == IFMAP_MEM_DEPTH) begin
	        ifmap_bram_init_run <= 1'b0;	
	    end 
		
		else if (ifmap_bram_data_write_hit && ifmap_bram_init_run) begin
			ifmap_addr_cnt <= ifmap_addr_cnt + 1;
		end
	end
//
//
//
	// weight_bram_init_run : reg7
	wire [C_S_AXI_ADDR_WIDTH-1:0] reg_7_weight_bram_init_run = 'h1c;
	reg	[WEIGHT_AWIDTH-1:0] weight_addr_cnt;
	reg weight_addr_cnt_trig;
	//
	always @(posedge clk or negedge reset_n) begin
	    if(!reset_n) begin
	        weight_addr_cnt <= 0;  
			weight_bram_init_run <= 1'b0;
			weight_addr_cnt_trig <= 1'b0;
		end

		else if (weight_bram_addr_write_hit) begin
	        weight_addr_cnt <= weight_bram_addr_reg; 
	    end 

		else if(axi_awaddr[ADDR_LSB+OPT_MEM_ADDR_BITS:ADDR_LSB] == reg_7_weight_bram_init_run[ADDR_LSB+OPT_MEM_ADDR_BITS:ADDR_LSB]) begin
			weight_bram_init_run <= slv_reg7;
	    end 
		
		else if (weight_bram_init_run && weight_addr_cnt == WEIGHT_MEM_DEPTH) begin
	        weight_bram_init_run <= 1'b0;
		end 
		
		else if (weight_bram_data_write_hit && weight_bram_init_run) begin
			weight_addr_cnt <= weight_addr_cnt + 1;
		end
	end

	// ofmap_bram_init_run : rega
	wire [C_S_AXI_ADDR_WIDTH-1:0] reg_a_ofmap_bram_init_run = 'h28;

	reg	[OFMAP_AWIDTH-1:0] ofmap_addr_cnt;
	always @(posedge clk or negedge reset_n) begin
		if(!reset_n) ofmap_addr_cnt <= {OFMAP_AWIDTH{1'b0}};
		else if(ofmap_bram_addr_write_hit) 	ofmap_addr_cnt <= ofmap_bram_addr_reg;
		else if(ofmap_addr_cnt == OFMAP_MEM_DEPTH) ofmap_addr_cnt <= {OFMAP_AWIDTH{1'b0}};
		else if(ofmap_bram_data_write_hit && ofmap_bram_init_run) ofmap_addr_cnt <= ofmap_addr_cnt + 1;
		else if(ofmap_bram_data_read_hit && ofmap_read_run) ofmap_addr_cnt <= ofmap_addr_cnt + 1;
	end

	reg ofmap_bram_init_run_trig;
	always @(posedge clk or negedge reset_n) begin
		if(!reset_n) ofmap_bram_init_run_trig <= 1'b0;
		else if(axi_awaddr[ADDR_LSB+OPT_MEM_ADDR_BITS:ADDR_LSB] == reg_a_ofmap_bram_init_run[ADDR_LSB+OPT_MEM_ADDR_BITS:ADDR_LSB])
			ofmap_bram_init_run_trig <= 1'b1;
		else if(!ofmap_bram_init_run) ofmap_bram_init_run_trig <= 1'b0;

	end
	
	wire ofmap_read_run;
	wire ofmap_bram_init_run;
	assign ofmap_bram_init_run = ofmap_bram_init_run_trig && (ofmap_addr_cnt < OFMAP_MEM_DEPTH) ? 1'b1 : 1'b0;
	assign ofmap_read_run = CT_done;


	// (lab12) delay 1 cycle, read valid from memory
	reg slv_reg_rden_d;
	always @(posedge clk or negedge reset_n) begin
	    if(!reset_n) begin
			axi_rvalid_d	<= 'd0;
			slv_reg_rden_d	<= 'd0;
	    end else begin
			axi_rvalid_d	<= axi_rvalid;
			slv_reg_rden_d	<= slv_reg_rden;
	    end 
	end

	// (lab12) Assgin Memory I/F
	assign ifmap_bram_addr 		= ifmap_addr_cnt[IFMAP_AWIDTH-1:0]; 
	assign ifmap_bram_ce1		= ifmap_bram_data_write_hit;
	assign ifmap_bram_we1		= ifmap_bram_data_write_hit;
	// assign ifmap_bram_q1		= {IFMAP_DWIDTH{1'b0}};
	assign ifmap_bram_d1		= ifmap_bram_data_reg;

	// (lab12) Assgin Memory I/F
	assign weight_bram_addr 	= weight_addr_cnt[WEIGHT_AWIDTH-1:0]; 
	assign weight_bram_ce1		= weight_bram_data_write_hit;
	assign weight_bram_we1		= weight_bram_data_write_hit;
	// assign weight_bram_q1		= {WEIGHT_DWIDTH{1'b0}};
	assign weight_bram_d1		= weight_bram_data_reg;

	// (lab12) Assgin Memory I/F
	assign ofmap_bram_addr 		= ofmap_addr_cnt[OFMAP_AWIDTH-1:0]; 
	assign ofmap_bram_ce1		= ofmap_bram_data_read_hit || ofmap_bram_data_write_hit;
	assign ofmap_bram_we1		= ofmap_bram_data_write_hit;
	// assign ofmap_bram_q1		= reg_data_out;
	assign ofmap_bram_d1		= ofmap_bram_data_reg;

	// Implement write response logic generation
	// The write response and response valid signals are asserted by the slave 
	// when axi_wready, S_AXI_WVALID, axi_wready and S_AXI_WVALID are asserted.  
	// This marks the acceptance of address and indicates the status of 
	// write transaction.

	always @( posedge S_AXI_ACLK )
	begin
	  if ( S_AXI_ARESETN == 1'b0 )
	    begin
	      axi_bvalid  <= 0;
	      axi_bresp   <= 2'b0;
	    end 
	  else
	    begin    
	      if (axi_awready && S_AXI_AWVALID && ~axi_bvalid && axi_wready && S_AXI_WVALID)
	        begin
	          // indicates a valid write response is available
	          axi_bvalid <= 1'b1;
	          axi_bresp  <= 2'b0; // 'OKAY' response 
	        end                   // work error responses in future
	      else
	        begin
	          if (S_AXI_BREADY && axi_bvalid) 
	            //check if bready is asserted while bvalid is high) 
	            //(there is a possibility that bready is always asserted high)   
	            begin
	              axi_bvalid <= 1'b0; 
	            end  
	        end
	    end
	end   

	// Implement axi_arready generation
	// axi_arready is asserted for one S_AXI_ACLK clock cycle when
	// S_AXI_ARVALID is asserted. axi_awready is 
	// de-asserted when reset (active low) is asserted. 
	// The read address is also latched when S_AXI_ARVALID is 
	// asserted. axi_araddr is reset to zero on reset assertion.

	always @( posedge S_AXI_ACLK )
	begin
	  if ( S_AXI_ARESETN == 1'b0 )
	    begin
	      axi_arready <= 1'b0;
	      axi_araddr  <= 32'b0;
	    end 
	  else
	    begin    
	      if (~axi_arready && S_AXI_ARVALID)
	        begin
	          // indicates that the slave has acceped the valid read address
	          axi_arready <= 1'b1;
	          // Read address latching
	          axi_araddr  <= S_AXI_ARADDR;
	        end
	      else
	        begin
	          axi_arready <= 1'b0;
	        end
	    end 
	end       

	// Implement axi_arvalid generation
	// axi_rvalid is asserted for one S_AXI_ACLK clock cycle when both 
	// S_AXI_ARVALID and axi_arready are asserted. The slave registers 
	// data are available on the axi_rdata bus at this instance. The 
	// assertion of axi_rvalid marks the validity of read data on the 
	// bus and axi_rresp indicates the status of read transaction.axi_rvalid 
	// is deasserted on reset (active low). axi_rresp and axi_rdata are 
	// cleared to zero on reset (active low).  
	always @( posedge S_AXI_ACLK )
	begin
	  if ( S_AXI_ARESETN == 1'b0 )
	    begin
	      axi_rvalid <= 0;
	      axi_rresp  <= 0;
	    end 
	  else
	    begin    
	      if (axi_arready && S_AXI_ARVALID && ~axi_rvalid)
	        begin
	          // Valid read data is available at the read data bus
	          axi_rvalid <= 1'b1;
	          axi_rresp  <= 2'b0; // 'OKAY' response
	        end   
	      else if (axi_rvalid && S_AXI_RREADY)
	        begin
	          // Read data is accepted by the master
	          axi_rvalid <= 1'b0;
	        end                
	    end
	end    

	// Implement memory mapped register select and read logic generation
	// Slave register read enable is asserted when valid address is available
	// and the slave is ready to accept the read address.
	assign slv_reg_rden = axi_arready & S_AXI_ARVALID & ~axi_rvalid;
	always @(*)
	begin
	      // Address decoding for reading registers
	      case ( axi_araddr[ADDR_LSB+OPT_MEM_ADDR_BITS:ADDR_LSB] )
	        4'h0   : reg_data_out <= slv_reg0;
	        4'h1   : reg_data_out <= slv_reg1;
	        4'h2   : reg_data_out <= slv_reg2;
	        4'h3   : reg_data_out <= slv_reg3;
			4'h4   : reg_data_out <= slv_reg4;
			4'h5   : reg_data_out <= slv_reg5;
			4'h6   : reg_data_out <= slv_reg6;
			4'h7   : reg_data_out <= slv_reg7;
			4'h8   : reg_data_out <= slv_reg8;
	        4'h9   : reg_data_out <= slv_reg9;
	        4'ha   : reg_data_out <= slv_rega;
	        4'hb   : reg_data_out <= ofmap_bram_q1[OFMAP_DWIDTH-1:0];
	        4'hc   : reg_data_out <= slv_regc;
	        4'hd   : reg_data_out <= slv_regd;
	        4'he   : reg_data_out <= slv_rege;
	        4'hf   : reg_data_out <= slv_regf;
	        default : reg_data_out <= 0;
	      endcase
	end

	// Output register or memory read data
	always @( posedge S_AXI_ACLK )
	begin
	  if ( S_AXI_ARESETN == 1'b0 )
	    begin
	      axi_rdata  <= 0;
	    end 
	  else
	    begin    
	      // When there is a valid read address (S_AXI_ARVALID) with 
	      // acceptance of read address by the slave (axi_arready), 
	      // output the read dada 
	      //if (slv_reg_rden)
	      if (slv_reg_rden_d) // (lab12) 1 cycle delay, read valid from memory
	        begin
	          axi_rdata <= reg_data_out;     // register read data
	        end   
	    end
	end    

	// slv_regc,d,e,f are used for debug
	// always @(posedge S_AXI_ACLK) begin 
    // 	if ( S_AXI_ARESETN == 1'b0 ) slv_regc <= {32{1'b0}};
	// 	// else slv_regc <= ifmap_bram_init_run ? slv_regc + 1'b1 : slv_regc;
	// 	else begin
	// 		// slv_regc <= CT_load ? slv_regc + 1 : slv_regc;
	// 		slv_regc <= weight_vec_debug0;
	// 	end
	// end

	// always @(posedge S_AXI_ACLK) begin 
    // 	if ( S_AXI_ARESETN == 1'b0 ) slv_regd <= {32{1'b0}};  
	// 	// else slv_regd <= weight_bram_init_run ? slv_regd + 1'b1 : slv_regd;
	// 	else slv_regd <= weight_vec_debug3;
	// end


	// always @(posedge S_AXI_ACLK) begin 
    // 	if ( S_AXI_ARESETN == 1'b0 ) slv_rege <= {32{1'b0}};  
    // 	// else slv_rege <= CT_calc ? slv_rege + 1 : slv_rege;
	// 	// else slv_rege <= weight_vec_debug2;
	// 	else slv_rege <= ifmap_value;
	// end


	// always @(posedge S_AXI_ACLK) begin 
    // 	if ( S_AXI_ARESETN == 1'b0 ) slv_regf <= {32{1'b0}};  
	// 	// else slv_regf <= CT_save ? slv_regf + 1 : slv_regf;
	// 	// else slv_regf <= weight_vec_debug3;
	// 	else slv_regf <= weight_vec;
	// end

	always @(posedge S_AXI_ACLK) begin 
    	if ( S_AXI_ARESETN == 1'b0 ) begin // sync reset_n
    	    slv_reg4 <= {32{1'b0}};  
    	end else begin
			slv_reg4[0] <= CT_idle;
			slv_reg4[1] <= CT_load;
			slv_reg4[2] <= CT_calc;
			slv_reg4[3] <= CT_save;
			slv_reg4[4] <= CT_done;
			slv_reg4[5] <= are_all_channel_calcs_done;
			// no use [31:3]
		end 
	end

endmodule