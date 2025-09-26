module mycpu_top(
    input  wire        clk,
    input  wire        resetn,
    // inst sram interface
    output wire        inst_sram_en,
    output wire [3:0]  inst_sram_we,
    output wire [31:0] inst_sram_addr,
    output wire [31:0] inst_sram_wdata,
    input  wire [31:0] inst_sram_rdata,
    // data sram interface
    output wire        data_sram_en,
    output wire [3:0]  data_sram_we,
    output wire [31:0] data_sram_addr,
    output wire [31:0] data_sram_wdata,
    input  wire [31:0] data_sram_rdata,
    // trace debug interface
    output wire [31:0] debug_wb_pc,
    output wire [ 3:0] debug_wb_rf_we,
    output wire [ 4:0] debug_wb_rf_wnum,
    output wire [31:0] debug_wb_rf_wdata
);
    reg reset;
    always @(posedge clk) reset <= ~resetn;

    // IF/ID
    wire               id_allowin;
    wire               if_to_id_valid;
    wire [63:0]        if_reg;
    wire [32:0]        branch_reg;

    // ID/EX
    wire               ex_allowin;
    wire               id_to_ex_valid;
    wire [151:0]       id_reg;
    wire [37:0]        wb_to_rf_reg;

    // EX/MEM
    wire               mem_allowin;
    wire               ex_to_mem_valid;
    wire [103:0]       ex_reg;

    // MEM/WB
    wire               wb_allowin;
    wire               mem_to_wb_valid;
    wire [69:0]        mem_reg;

    // ---------------- IF ----------------
    IF u_IF(
        .clk            (clk),
        .reset          (reset),
        .id_allowin     (id_allowin),

        .branch_reg     (branch_reg),

        .if_to_id_valid (if_to_id_valid),
        .if_reg         (if_reg),

        .inst_sram_en   (inst_sram_en),
        .inst_sram_we  (inst_sram_we),    
        .inst_sram_addr (inst_sram_addr),
        .inst_sram_wdata(inst_sram_wdata),
        .inst_sram_rdata(inst_sram_rdata)
    );

    // ---------------- ID ----------------
    ID u_ID(
        .clk            (clk),
        .reset          (reset),

        .ex_allowin     (ex_allowin),
        .id_allowin     (id_allowin),

        .if_to_id_valid (if_to_id_valid),
        .if_reg         (if_reg),

        .id_to_ex_valid (id_to_ex_valid),
        .id_reg         (id_reg),

        .branch_reg     (branch_reg),

        .wb_to_rf_reg   (wb_to_rf_reg)
    );

    // ---------------- EX ----------------
    EX u_EX(
        .clk            (clk),
        .reset          (reset),

        .mem_allowin    (mem_allowin),
        .ex_allowin     (ex_allowin),

        .id_to_ex_valid (id_to_ex_valid),
        .id_reg         (id_reg),

        .ex_to_mem_valid(ex_to_mem_valid),  
        .ex_reg         (ex_reg),

        .data_sram_en   (data_sram_en),
        .data_sram_we  (data_sram_we),     
        .data_sram_addr (data_sram_addr),
        .data_sram_wdata(data_sram_wdata)
    );

    // ---------------- MEM ----------------
    MEM u_MEM(
        .clk            (clk),
        .reset          (reset),

        .wb_allowin     (wb_allowin),
        .mem_allowin    (mem_allowin),

        .ex_to_mem_valid(ex_to_mem_valid),
        .ex_reg         (ex_reg),

        .mem_to_wb_valid(mem_to_wb_valid),
        .mem_reg        (mem_reg),

        .data_sram_rdata(data_sram_rdata)
    );

    // ---------------- WB ----------------
    WB u_WB(
        .clk            (clk),
        .reset          (reset),

        .wb_allowin     (wb_allowin),

        .mem_to_wb_valid(mem_to_wb_valid),
        .mem_reg        (mem_reg),

        .wb_to_rf_reg   (wb_to_rf_reg),

        .debug_wb_pc    (debug_wb_pc),
        .debug_wb_rf_we (debug_wb_rf_we),
        .debug_wb_rf_wnum(debug_wb_rf_wnum),
        .debug_wb_rf_wdata(debug_wb_rf_wdata)
    );

endmodule
