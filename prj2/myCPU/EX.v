module EX(
    input wire clk,
    input wire reset,

    input wire mem_allowin,
    output wire ex_allowin ,

    input wire id_to_ex_valid,
    input wire [151:0] id_reg,

    output wire ex_to_mem_valid,
    output wire [103:0] ex_reg,

    output wire data_sram_en,
    output wire [ 3:0] data_sram_we,
    output wire [31:0] data_sram_addr,
    output wire [31:0] data_sram_wdata
);

reg ex_valid;
wire ex_ready_go;
wire ex_allowin;
assign ex_ready_go = 1;
assign ex_allowin = !ex_valid || ex_ready_go && mem_allowin;
assign ex_to_mem_valid = ex_valid && ex_ready_go;

reg [151:0] id_reg_r;
always @(posedge clk) begin
    if (reset) begin
        ex_valid <= 1'b0;
    end else if (ex_allowin) begin
        ex_valid <= id_to_ex_valid;
    end
    if (id_to_ex_valid && ex_allowin) begin
        id_reg_r <= id_reg;
    end
end

wire [11:0]  alu_op       = id_reg_r[151:140];
wire         res_from_mem = id_reg_r[139];
wire         need_ui5     = id_reg_r[138];
wire         src1_is_pc   = id_reg_r[137];
wire         src2_is_imm  = id_reg_r[136];
wire         src2_is_4    = id_reg_r[135];
wire         gr_we        = id_reg_r[134];
wire         mem_we       = id_reg_r[133];
wire [4:0]   dest         = id_reg_r[132:128];
wire [31:0]  imm          = id_reg_r[127:96];
wire [31:0]  rj_value     = id_reg_r[95:64];
wire [31:0]  rkd_value    = id_reg_r[63:32];
wire [31:0]  ex_pc        = id_reg_r[31:0];

wire [31:0] ex_alu_src1   ;
wire [31:0] ex_alu_src2   ;
wire [31:0] ex_alu_result ;
assign ex_alu_src1 = src1_is_pc  ? ex_pc[31:0] : rj_value;
assign ex_alu_src2 = src2_is_imm ? imm : rkd_value;

alu u_alu(
    .alu_op     (alu_op    ),
    .alu_src1   (ex_alu_src1  ),
    .alu_src2   (ex_alu_src2  ),
    .alu_result (ex_alu_result)
    );

assign ex_reg = {
    res_from_mem,   // 是否是加载指令
    mem_we,         // 是否是存储指令
    gr_we,          // 是否写回寄存器堆
    dest,           // 目标寄存器编号
    ex_alu_result,  // ALU 计算结果（访存地址或写回数据）
    rkd_value,      // 存储指令的写入数据
    ex_pc           // 当前指令的 PC 值
};

assign data_sram_en    = 1;
assign data_sram_we    = (mem_we && ex_valid) ? 4'b1111 : 4'b0000;
assign data_sram_addr  = ex_alu_result;
assign data_sram_wdata = rkd_value;
endmodule