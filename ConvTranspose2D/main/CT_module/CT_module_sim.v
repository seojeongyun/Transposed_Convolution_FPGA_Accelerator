`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04/02/2025 02:13:03 PM
// Design Name: 
// Module Name: CT_module
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module CT_module#
(
    parameter   FW = 3,
    parameter   FH = 3,
    //
    parameter   IW = 2,
    parameter   IH = 2,
    //
    parameter   S = 1,
    parameter   PAD = 0,
    parameter   IN_C = 1,
    parameter   OUT_C = 1,
    //
    parameter IDX_BITS = 10,
    parameter ENABLE_CNT_BITS = 3,
    //
    parameter BITS     = 8,
    parameter SIGNED_BITS = 9,
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
    parameter IFMAP_AWIDTH = 10,
    //
    parameter WEIGHT_AWIDTH = 10,
    //
    parameter OFMAP_AWIDTH = 12,
    parameter OFMAP_DWIDTH = OFMAP_BITS,
    parameter OFMAP_MEM_DEPTH = PAD ? PADDED_OW * PADDED_OH * OUT_C : ORIG_OW * ORIG_OH * OUT_C
)
(
    input   i_run,
    input   clk,
    input   reset_n,
    //
    input   is_save_done,
    //
    input   signed [SIGNED_BITS -1 : 0] ifmap_value,
    input   signed [BITS * FW - 1 : 0] weight_vec,
    //
    input   i_idle_from_SAVE,
    input   i_read_from_SAVE,
    input   i_accum_from_SAVE,
    input   i_write_from_SAVE,
    input   i_done_from_SAVE,    
    //
    input   [IDX_BITS -1 : 0] mem_access_cnt,
    //
    output  [IDX_BITS -1 : 0] row_idx,
    output  [IDX_BITS -1 : 0] col_idx,
    output  [IDX_BITS -1 : 0] in_channel_idx,
    output  [IDX_BITS -1 : 0] out_channel_idx,
    //
    output  [FW * FH * MULT_BITS -1 : 0]  intermediate,
    output  [FH -1 : 0] o_valid,
    //
    output  o_idle,
    output  o_load,
    output  o_calc,
    output  o_save,
    output  o_done,
    //
    output  wegt_ce0,
    output  ifmap_ce0,
    //
    output  [IDX_BITS -1 : 0] captured_ifmap_row,
    output  [IDX_BITS -1 : 0] captured_ifmap_col,
    output  [IDX_BITS -1 : 0] captured_ifmap_in_channel,
    output  [IDX_BITS -1 : 0] captured_ifmap_out_channel,
    //
    output  [IDX_BITS -1 : 0] wegt_addr, // IDX_BITS << ??????????
    output  [IDX_BITS -1 : 0] ifmap_addr,
    //
    output  [OW * OH * OUT_C * OFMAP_BITS -1 : 0] ofmap,
    output  ofmap_generate_success,
    //
    output  are_all_channel_calcs_done 
);

    localparam IDLE = 3'b000, LOAD = 3'b001, CALC = 3'b010, SAVE = 3'b011, DONE = 3'b100;
    
    // -*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*
    //
    reg [IDX_BITS -1 : 0] save_cnt_for_all_channels;
    reg [IDX_BITS -1 : 0] save_cnt_for_a_channel;
    //
    always @(posedge clk or negedge reset_n) begin
        if(!reset_n) begin
            save_cnt_for_all_channels <= {IDX_BITS{1'b0}};
            save_cnt_for_a_channel <= {IDX_BITS{1'b0}};
        end
        //
        else if(is_save_done) begin 
            if(save_cnt_for_all_channels == (IH * IW * IN_C * OUT_C) -1) save_cnt_for_all_channels <= {IDX_BITS{1'b0}};
            else save_cnt_for_all_channels <= save_cnt_for_all_channels + 1'b1;
            //
            if(save_cnt_for_a_channel == (IH * IW) -1) save_cnt_for_a_channel <= {IDX_BITS{1'b0}};
            else save_cnt_for_a_channel <= save_cnt_for_a_channel + 1'b1;
        end
    end
    
    
    
    // -*-*-*-*-*-*-* STATE CONTROL SIGNAL -*-*-*-*-*-*-*
    wire is_load_done;
    wire is_calc_done;
    wire go_to_calc;
    wire is_single_out_channel;
    wire are_all_channel_calcs_done;
    
    assign is_load_done = enable[FW-1];
    assign is_calc_done = o_calc && &o_valid;
    assign go_to_calc = o_save && is_save_done && save_cnt_for_a_channel != (IW * IH) -1;
    assign is_single_out_channel = OUT_C == 1;
    assign are_all_channel_calcs_done = o_save && is_save_done && (save_cnt_for_all_channels == IW * IH * IN_C * OUT_C - 1);
    //
    assign wegt_ce0 = o_load && (enable_delay[0] || (shift_trigger && enable_cnt < FW-1));
    assign ifmap_ce0 = enable[FW-2] || go_to_calc;
    
    
    
    // -*-*-*-*-*-*-* FSM -*-*-*-*-*-*-*
    reg [2:0] c_state;
    reg [2:0] n_state;
    
    always @(posedge clk or negedge reset_n) begin
        if(!reset_n) c_state <= IDLE;
        else c_state <= n_state;
    end
    
    always @(*) begin
        case(c_state)
            IDLE : n_state = i_run        ? LOAD : IDLE;
            LOAD : n_state = is_load_done ? CALC : LOAD;
            CALC : n_state = is_calc_done ? SAVE : CALC;
            SAVE : n_state = is_save_done ? 
                             (go_to_calc  ? CALC : 
                             are_all_channel_calcs_done ? DONE : LOAD) : SAVE;
            DONE : n_state = IDLE;
        endcase
    end
    
    
    
    // -*-*-*-*-*-*-* STATE SIGNAL -*-*-*-*-*-*-*
    wire o_idle;
    wire o_load;
    wire o_calc;
    wire o_save;
    wire o_done;
    
    assign o_idle = c_state == IDLE;
    assign o_load = c_state == LOAD;
    assign o_calc = c_state == CALC;
    assign o_save = c_state == SAVE;
    assign o_done = c_state == DONE;
    
    
    
    // -*-*-*-*-*-*-* ENABLE GENERATOR -*-*-*-*-*-*-*
    reg     [FH -1 : 0] enable;
    reg     [ENABLE_CNT_BITS -1 : 0] enable_cnt;    // this cnt uses for wegt_ce0.
    reg     [ENABLE_DELAY -1 : 0] enable_delay;
    reg     shift_trigger;                                // this signal uses for shift of enable.
    //
    always @(posedge clk or negedge reset_n) begin
        if(!reset_n) begin
            enable <= {FH{1'b0}};
        end
        
        else if(o_load && &enable_delay) enable <= {{FH-1{1'b0}}, &enable_delay};
        
        else if(o_calc) begin
            enable <= {FH{1'b0}};         
        end
        
        else if(shift_trigger)begin
            enable <= enable << 1;
        end
        
//        else if (&enable_delay || enable!=0) enable_cnt <= enable_cnt + 1'b1;
    end
    //
    always @(posedge clk or negedge reset_n) begin
        if(!reset_n) enable_cnt <= {ENABLE_CNT_BITS{1'b0}};
        
        else if (&enable_delay || enable!=0) enable_cnt <= enable_cnt + 1'b1;
        
        else if(o_calc) enable_cnt <= {ENABLE_CNT_BITS{1'b0}};
    end
    //
    always @(posedge clk or negedge reset_n) begin
        if(!reset_n) begin
            enable_delay <= {ENABLE_DELAY{1'b0}};
            shift_trigger <= 1'b0;
        end
        
        else if(o_load && &enable_delay) begin
            shift_trigger <= 1'b1;
            enable_delay <= {ENABLE_DELAY{1'b0}};
        end
        
        else if(!o_load) begin
            enable_delay <= {ENABLE_DELAY{1'b0}};
            shift_trigger <= 1'b0;
        end
        
        else if(o_load && !shift_trigger) enable_delay <= {enable_delay[ENABLE_DELAY -1 : 0], o_load};
    end
    
    
    // -*-*-*-*-*-*-* CORE_RUN_GENERATOR -*-*-*-*-*-*-*
    reg core_run;
    reg core_run_delay;
    //
    always @(posedge clk or negedge reset_n) begin
        if(!reset_n) begin
            core_run <= 1'b0;
            core_run_delay <= 1'b0;
        end
        // a core_run signal remains during one cycle.
        // a calculation of ifmap value * wegt spends only one cycle. 
        else if(enable[FH -1] == 1'b1) core_run <= 1'b1;
        //
        else if(go_to_calc) core_run_delay <= 1'b1;
        //
        else if(core_run_delay) begin
            core_run_delay <= 1'b0;
            core_run <= 1'b1;
        end
        //
        else core_run <= 1'b0;
    end
    
    
    
    // -*-*-*-*-*-*-* ifmap mem addr -*-*-*-*-*-*-*
    reg [IDX_BITS -1 : 0] row_idx;
    reg [IDX_BITS -1 : 0] col_idx;
    reg [IDX_BITS -1 : 0] in_channel_idx;
    reg [IDX_BITS -1 : 0] out_channel_idx;
    
    always @(posedge clk or negedge reset_n) begin
        if(!reset_n) begin
            row_idx <= {IDX_BITS{1'b0}};
            col_idx <= {IDX_BITS{1'b0}};
            in_channel_idx <= {IDX_BITS{1'b0}};
            out_channel_idx <= {IDX_BITS{1'b0}};
        end
        
        else if(core_run) begin////////////////////////////////////////////////////////////////
            if(col_idx == IW-1) begin
                col_idx <= {IDX_BITS{1'b0}};
                
                if(row_idx == IH-1) begin
                    row_idx <= {IDX_BITS{1'b0}};
                    
                    if(out_channel_idx == OUT_C-1) begin
                        out_channel_idx <= {IDX_BITS{1'b0}};
                        in_channel_idx <= in_channel_idx + 1'b1;
                    end
                    
                    else out_channel_idx <= out_channel_idx + 1'b1;
                    
                end
                else row_idx <= row_idx + 1'b1;
            
            end
            else col_idx <= col_idx + 1'b1;
        end
    end
    
    
    
    // -*-*-*-*-*-*-* idx capture -*-*-*-*-*-*-*
    reg [DELAY * IDX_BITS -1 : 0] captured_ifmap_col;
    reg [DELAY * IDX_BITS -1 : 0] captured_ifmap_row;
    reg [DELAY * IDX_BITS -1 : 0] captured_ifmap_in_channel;
    reg [DELAY * IDX_BITS -1 : 0] captured_ifmap_out_channel;
    //
    always @(posedge clk or negedge reset_n) begin
        if(!reset_n) begin
            captured_ifmap_col <= {DELAY * IDX_BITS{1'b0}};
            captured_ifmap_row <= {DELAY * IDX_BITS{1'b0}};
            captured_ifmap_in_channel <= {DELAY * IDX_BITS{1'b0}};
            captured_ifmap_out_channel <= {DELAY * IDX_BITS{1'b0}};
        end
        
        else if(i_accum_from_SAVE && mem_access_cnt == (FW * FH -1)) begin
            if(DELAY == 1) begin
                captured_ifmap_col <= col_idx;
                captured_ifmap_row <= row_idx;
                captured_ifmap_in_channel <= in_channel_idx;
                captured_ifmap_out_channel <= out_channel_idx;         
            end
            
            else begin
                captured_ifmap_col <= {captured_ifmap_col[(DELAY-1) * IDX_BITS -1 : 0], col_idx};
                captured_ifmap_row <= {captured_ifmap_row[(DELAY-1) * IDX_BITS -1 : 0], row_idx};
                captured_ifmap_in_channel <= {captured_ifmap_in_channel[(DELAY-1) * IDX_BITS -1 : 0], in_channel_idx};
                captured_ifmap_out_channel <= {captured_ifmap_out_channel[(DELAY-1) * IDX_BITS -1 : 0], out_channel_idx};
            end
        end
    end
    
    
    
    // -*-*-*-*-*-*-* WEIGHT & IFMAP ADDR -*-*-*-*-*-*-*
    reg [WEIGHT_AWIDTH - 1 : 0] wegt_addr;
    reg [IFMAP_AWIDTH - 1 : 0] ifmap_addr;
    
    always @(posedge clk or negedge reset_n) begin
        if(!reset_n) wegt_addr <= {IDX_BITS{1'b0}};
        else if(wegt_ce0) wegt_addr <= wegt_addr + 1'b1;
    end
    
    always @(posedge clk or negedge reset_n) begin
        if(!reset_n) ifmap_addr <={IDX_BITS{1'b0}};
        
        else ifmap_addr <= IW * IH * in_channel_idx + IH * row_idx + col_idx;
    end
    
    
    
    // -*-*-*-*-*-*-* instantiation of core cluster -*-*-*-*-*-*-*
    core_cluster#
    (
        .FW         (FW),
        .FH         (FH),
        //
        .BITS       (BITS),
        .SIGNED_BITS(SIGNED_BITS),
        .MULT_BITS  (MULT_BITS)
    )
    u0_core_cluster
    (
        .clk            (clk),
        .reset_n        (reset_n),
        //
        .enable         (enable),
        .core_run       (core_run),
        //
        .ifmap_value    (ifmap_value),
        .weight_vec     (weight_vec),
        //
        .o_valid        (o_valid),
        .intermediate   (intermediate)
    );
    
    
    
    // -*-*-*-*-*-*-* instantiation of SAVE_module -*-*-*-*-*-*-*
    SAVE_module#
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
        .ORIG_OW            (ORIG_OW),
        .ORIG_OH            (ORIG_OH),
        //
        .PADDED_OW          (PADDED_OW),
        .PADDED_OH          (PADDED_OH),  
        //
        .OW                 (OW),
        .OH                 (OH),
        //
        .MULT_BITS          (MULT_BITS),
        .OFMAP_BITS         (OFMAP_BITS),
        //
        .IDX_BITS           (IDX_BITS),
        //
        .IN_PAD_REGION_DELAY(IN_PAD_REGION_DELAY),
        //
        .OFMAP_AWIDTH       (OFMAP_AWIDTH),
        .OFMAP_DWIDTH       (OFMAP_DWIDTH),
        .OFMAP_MEM_DEPTH    (OFMAP_MEM_DEPTH) 
    )
    u0_SAVE_module
    (
        .clk                    (clk),
        .reset_n                (reset_n),
        //
        .captured_ifmap_row         (captured_ifmap_row[(DELAY) * IDX_BITS -1 -: IDX_BITS]),
        .captured_ifmap_col         (captured_ifmap_col[(DELAY) * IDX_BITS -1 -: IDX_BITS]),
        .captured_ifmap_in_channel  (captured_ifmap_in_channel[(DELAY) * IDX_BITS -1 -: IDX_BITS]),
        .captured_ifmap_out_channel (captured_ifmap_out_channel[(DELAY) * IDX_BITS -1 -: IDX_BITS]),
        //
        .o_valid                (o_valid),
        .intermediate           (intermediate),
        //
        .i_idle_from_CT         (o_idle),
        .i_load_from_CT         (o_load),
        .i_calc_from_CT         (o_calc),
        .i_save_from_CT         (o_save),
        .i_done_from_CT         (o_done),
        //
        .o_idle                 (i_idle_from_SAVE),
        .o_read                 (i_read_from_SAVE),
        .o_accum                (i_accum_from_SAVE),
        .o_write                (i_write_from_SAVE),
        .o_done                 (i_done_from_SAVE),        
        //
        .is_save_done           (is_save_done),
        //
        .mem_access_cnt         (mem_access_cnt),
        .ofmap                  (ofmap),
        .ofmap_generate_success (ofmap_generate_success)
    );
endmodule
