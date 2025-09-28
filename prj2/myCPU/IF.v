module IF(
    input wire clk,
    input wire reset,

    input wire id_allowin,

    input wire [32:0] branch_reg,
    input wire br_taken_cancel,

    output wire if_to_id_valid,
    output wire [63:0] if_reg,

    output wire inst_sram_en,
    output wire [3:0] inst_sram_we,
    output wire [31:0] inst_sram_addr,
    output wire [31:0] inst_sram_wdata,
    input  wire [31:0] inst_sram_rdata
);

reg         if_valid;
wire        if_ready_go;
wire        if_allowin;
wire        pre_to_if_valid;

wire [31:0] seq_pc;
wire [31:0] nextpc;

wire         br_taken;
wire [ 31:0] br_target;
assign {br_taken, br_target} = branch_reg;

wire [31:0] if_inst;
reg  [31:0] if_pc;
assign  if_reg = {if_inst, if_pc};

// pre-if
assign pre_to_if_valid  = ~reset;
assign seq_pc       = if_pc + 3'h4;
assign nextpc       = br_taken ? br_target : seq_pc; 

// if
assign if_ready_go    = 1'b1;
assign if_allowin     = !if_valid || if_ready_go && id_allowin;
assign if_to_id_valid =  if_valid && if_ready_go;

assign inst_sram_en    = pre_to_if_valid && if_allowin;
assign inst_sram_we   = 4'h0;
assign inst_sram_addr  = nextpc;
assign inst_sram_wdata = 32'b0;
assign if_inst         = inst_sram_rdata;

always @(posedge clk) begin
    if (reset) begin
        if_valid <= 1'b0;
    end
    else if (if_allowin) begin
        if_valid <= pre_to_if_valid;
    end
    else if (br_taken_cancel) begin
        if_valid <= 1'b0;
    end

    if (reset) begin
        if_pc <= 32'h1bfffffc;
    end
    else if (pre_to_if_valid && if_allowin) begin
        if_pc <= nextpc;
    end
end
endmodule
