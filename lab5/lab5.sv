`ifndef _core_v
`define _core_v
`include "system.sv"
`include "base.sv"
`include "memory_io.sv"
`include "memory.sv"
`include "riscv32_common.sv"

`include "lab1.sv"


/*

This is a very simple 5 stage multicycle RISC-V 32bit design.

The stages are fetch, decode, execute, memory, writeback

*/

// write-out mem: 'h0002_FFF8
// write-to halt mem: 'h0002_FFFC


module core(
    input logic       clk
    ,input logic      reset
    ,input logic      [`word_address_size-1:0] reset_pc
    ,output memory_io_req   inst_mem_req
    ,input  memory_io_rsp   inst_mem_rsp
    ,output memory_io_req   data_mem_req
    ,input  memory_io_rsp   data_mem_rsp
    );

localparam instr32 noop = 32'h00000013;

//fetch to decode buffer
typedef struct packed {
    word pc;
    instr32 inst;
    logic valid;
} buffer_fetch_to_decode;

//decode to execute buffer
typedef struct packed {
    word     pc;
    word     rd1;
    word     rd2;
    word     imm;
    tag      rd;
    opcode_q op_q;
    funct3   f3;
    funct7   f7;
    logic    writeback_valid; 
    logic    valid;
} buffer_decode_to_exec;

//exec to mem buffer
typedef struct packed {
    word     pc;
    word     exec_result;
    word     next_pc;
    word     rd2;            
    tag      rd;
    opcode_q op_q;
    funct3   f3;
    logic    writeback_valid;
    logic    valid;
} buffer_exec_to_mem;

//mem to writeback buffer
typedef struct packed {
    word     pc;
    tag      rd;
    logic    writeback_valid;
    opcode_q op_q;
    word     exec_result;
    funct3   f3;
    logic    valid;
} buffer_mem_to_writeback;

// Pipeline Stage Registers
buffer_fetch_to_decode    f_d_reg;
buffer_decode_to_exec     d_ex_reg;
buffer_exec_to_mem        ex_mem_reg;
buffer_mem_to_writeback   mem_wb_reg;

// "Next" signals (combinational logic outputs)
buffer_fetch_to_decode    f_d_next;
buffer_decode_to_exec     d_ex_next;
buffer_exec_to_mem        ex_mem_next;
buffer_mem_to_writeback   mem_wb_next;


word_address    pc;
word_address    pc_requested;
word_address    next_pc;
word            reg_file[0:31];
word            instruction_count /*verilator public*/;
word            writeback_data;

//fetch
always_comb begin
    next_pc = pc + 32'd4; 

    inst_mem_req.addr    = pc;
    inst_mem_req.valid   = !reset; 
    inst_mem_req.do_read = 4'b1111;

    f_d_next.pc    = pc_requested;
    f_d_next.inst  = (inst_mem_rsp.valid) ? inst_mem_rsp.data : noop;
    f_d_next.valid = inst_mem_rsp.valid && !reset;
end

//decode
always_comb begin
    instr32 inst = f_d_reg.inst;
    tag rs1_tag = decode_rs1(inst);
    tag rs2_tag = decode_rs2(inst);
    opcode_q op_q_dec = decode_opcode_q(inst);
    instr_format fmt  = decode_format(op_q_dec);
    d_ex_next.pc              = f_d_reg.pc;
    d_ex_next.rd1             = (rs1_tag == 5'd0) ? 32'd0 : reg_file[rs1_tag];
    d_ex_next.rd2             = (rs2_tag == 5'd0) ? 32'd0 : reg_file[rs2_tag];
    d_ex_next.imm             = decode_imm(inst, fmt);
    d_ex_next.rd              = decode_rd(inst);
    d_ex_next.op_q            = op_q_dec;
    d_ex_next.f3              = decode_funct3(inst);
    d_ex_next.f7              = decode_funct7(inst, fmt);
    d_ex_next.writeback_valid = decode_writeback(op_q_dec);
    d_ex_next.valid           = f_d_reg.valid;
end


//exec
always_comb begin
    ext_operand exec_result_comb = execute(
        cast_to_ext_operand(d_ex_reg.rd1),
        cast_to_ext_operand(d_ex_reg.rd2),
        cast_to_ext_operand(d_ex_reg.imm),
        d_ex_reg.pc,
        d_ex_reg.op_q,
        d_ex_reg.f3,
        d_ex_reg.f7
    );

    //will need to capture this later for branching
    word next_pc_comb = get_next_pc(
        d_ex_reg.pc, 
        d_ex_reg.imm, 
        d_ex_reg.rd1, 
        d_ex_reg.op_q, 
        exec_result_comb[0] 
    );

    ex_mem_next.exec_result     = exec_result_comb[`word_size-1:0];
    ex_mem_next.rd2             = d_ex_reg.rd2; 
    ex_mem_next.rd              = d_ex_reg.rd;
    ex_mem_next.op_q            = d_ex_reg.op_q;
    ex_mem_next.f3              = d_ex_reg.f3;
    ex_mem_next.writeback_valid = d_ex_reg.writeback_valid;
    ex_mem_next.next_pc         = next_pc_comb;
    ex_mem_next.pc              = d_ex_reg.pc; 
    ex_mem_next.valid           = d_ex_reg.valid;
end

//mem
always_comb begin
    data_mem_req = memory_io_no_req32;

    // 2. Outbound Request (Combinational)
    // We send a request if the instruction in EX_MEM is valid and is a Load/Store
    if (ex_mem_reg.valid && (ex_mem_reg.op_q == q_store || ex_mem_reg.op_q == q_load)) begin
        data_mem_req.valid = 1'b1;
        data_mem_req.addr  = ex_mem_reg.exec_result[`word_address_size - 1:0];
        
        if (ex_mem_reg.op_q == q_store) begin
            data_mem_req.do_write = shuffle_store_mask(memory_mask(cast_to_memory_op(ex_mem_reg.f3)), ex_mem_reg.exec_result);
            data_mem_req.data     = shuffle_store_data(ex_mem_reg.rd2, ex_mem_reg.exec_result);
        end else begin
            data_mem_req.do_read  = shuffle_store_mask(memory_mask(cast_to_memory_op(ex_mem_reg.f3)), ex_mem_reg.exec_result);
        end
    end

    // 3. Prepare WB Buffer (Pass-through)
    // We don't process the load data here because it hasn't arrived yet!
    mem_wb_next.rd              = ex_mem_reg.rd;
    mem_wb_next.writeback_valid = ex_mem_reg.writeback_valid;
    mem_wb_next.op_q            = ex_mem_reg.op_q;
    mem_wb_next.exec_result     = ex_mem_reg.exec_result; 
    mem_wb_next.f3              = ex_mem_reg.f3;
    mem_wb_next.valid           = ex_mem_reg.valid;
end

//writeback
always_comb begin
    if (mem_wb_reg.op_q == q_load) begin
        writeback_data = subset_load_data(
            shuffle_load_data(data_mem_rsp.data, mem_wb_reg.exec_result),
            cast_to_memory_op(mem_wb_reg.f3)
        );
    end else begin
        // For add, sub, etc., just pass the ALU result stored in the buffer
        writeback_data = mem_wb_reg.exec_result;
    end
end

//regfile update
always_ff @(posedge clk) begin
    if (reset) begin
    end else begin
        // ONLY write if the instruction is valid and it's a type that writes to RD
        if (mem_wb_reg.valid && mem_wb_reg.writeback_valid && mem_wb_reg.rd != 0) begin
            reg_file[mem_wb_reg.rd] <= writeback_data;
        end
    end
end


//advance stages:
always_ff @(posedge clk) begin
    if (reset) begin
        f_d_reg    <= '0;
        d_ex_reg   <= '0;
        ex_mem_reg <= '0;
        mem_wb_reg <= '0;
        pc         <= reset_pc;
        pc_requested <= reset_pc;
        instruction_count <= 0;
        for (int i = 0; i < 32; i++) begin
            reg_file[i] <= 32'd0;
        end
    end else begin
        f_d_reg    <= f_d_next;
        d_ex_reg   <= d_ex_next;
        ex_mem_reg <= ex_mem_next;
        mem_wb_reg <= mem_wb_next;

        //speculative jump
        pc <= next_pc;
        pc_requested <= pc;
        //reg_data();
        //debug();
        debug_flag();
        
        if (mem_wb_reg.valid) begin
            instruction_count <= instruction_count + 1;
        end
    end
end



function automatic void debug();
    $display("WB Stage: PC=%h, RD=%d, Op=%b, Data=%h, WB_Valid=%b", 
          mem_wb_reg.pc, mem_wb_reg.rd, mem_wb_reg.op_q, writeback_data, mem_wb_reg.writeback_valid);
endfunction

function automatic void reg_data();
    string name [32] = '{
        "zero","ra","sp","gp","tp",
        "t0","t1","t2",
        "s0","s1",
        "a0","a1","a2","a3","a4","a5","a6","a7",
        "s2","s3","s4","s5","s6","s7","s8","s9","s10","s11",
        "t3","t4","t5","t6"
    };
    $display("==== Register File Dump ====");
    for (int i = 0; i < 32; i++) begin
        $display("x%0d (%s): 0x%08x", i, name[i], reg_file[i]);
    end
    $display("============================");
endfunction

function automatic void debug_flag();
    $display("\nHERE\n");
endfunction



endmodule
`endif
