`ifndef _lab1_
`define _lab1_

localparam opcode_R = 51;
localparam opcode_I = 19;
localparam opcode_I_load = 3;
localparam opcode_I_jalr = 103;
localparam opcode_I_misc = 15;
localparam opcode_I_system = 115;
localparam opcode_S = 35;
localparam opcode_B = 99;
localparam opcode_U = 55;
localparam opcode_U_PC = 23;
localparam opcode_J = 111;

function automatic void print_instruction(logic [31:0] pc, logic [31:0] instruction);
    // start output string
    string out;
    
    //get opcode for instruction type
    logic [6:0] opc;
    
    //common instruction components
    logic [4:0] rd, rs1, rs2;
    logic [2:0] func3;
    logic [6:0] func7;

    out = $sformatf("%08x: %08x   ", pc, instruction);
    opc = instruction[6:0]; 
    

    if (opc == opcode_R) begin
        func7 = instruction[31:25];
        rs2 = instruction[24:20]; // second register input
        rs1 = instruction[19:15]; //first register input
        func3 = instruction[14:12]; 
        rd = instruction[11:7]; //register where result goes
        case (func3)
            3'b000: out = {out, (func7 == 7'b0000000)? "add     ": "sub     "};
            3'b001: out = {out, "sll     "};
            3'b010: out = {out, "slt     "};
            3'b011: out = {out, "sltu    "};
            3'b100: out = {out, "xor     "};
            3'b101: out = {out, (func7 == 7'b0000000)? "srl     ": "sra     "};
            3'b110: out = {out, "or      "};
            3'b111: out = {out, "and     "};
            default: out = {out, "NULL    "};
        endcase
        out = {out, reg_name(rd), ",", reg_name(rs1), ",", reg_name(rs2)};
    end
    else if (opc == opcode_I) begin
        logic [11:0] imm; // 12-bit immediate
        func7 = instruction[31:25]; // for shifts
        imm   = instruction[31:20]; 
        rs1   = instruction[19:15]; 
        func3 = instruction[14:12]; 
        rd    = instruction[11:7]; 
        case (func3)
            3'b000: out = {out, "addi    "};
            3'b001: out = {out, "slli    "};
            3'b010: out = {out, "slti    "};
            3'b011: out = {out, "sltiu   "};
            3'b100: out = {out, "xori    "};
            3'b101: out = {out, (func7 == 7'b0000000)? "srli    ": "srai    "};
            3'b110: out = {out, "ori     "};
            3'b111: out = {out, "andi    "};
            default: out = {out, "NULL    "};
        endcase
        if (func3 == 3'b001 || func3 == 3'b101) begin
            out = {out, reg_name(rd), ",", reg_name(rs1), $sformatf(",%0d", imm[4:0])};
        end
        else begin
            out = {out, reg_name(rd), ",", reg_name(rs1), $sformatf(",%0d", sign_extend(imm))};
        end
    end
    else if (opc == opcode_I_load) begin
        logic [11:0] imm;
        imm = instruction[31:20];
        rs1 = instruction[19:15];
        func3 = instruction[14:12];
        rd = instruction[11:7];
        case(func3)
            3'b000: out = {out, "lb      "};
            3'b001: out = {out, "lh      "};
            3'b010: out = {out, "lw      "};
            3'b100: out = {out, "lbu     "};
            3'b101: out = {out, "lhu     "};
            default: out = {out, "NULL    "};
        endcase
        out = {out, reg_name(rd), ",", $sformatf("%0d(%s)", sign_extend(imm), reg_name(rs1))};
    end
    else if (opc == opcode_I_jalr) begin
        logic [11:0] imm;
        imm   = instruction[31:20];
        rs1   = instruction[19:15];
        func3 = instruction[14:12]; //always 000
        rd    = instruction[11:7];
        out = {out, "jalr    ", reg_name(rd), ",", reg_name(rs1), $sformatf(",%0d", sign_extend(imm))};
    end
    // strange opcode likely not used    
    else if (opc == opcode_I_misc) begin
        logic [11:0] imm;
        imm   = instruction[31:20];
        func3 = instruction[14:12];
        case(func3)
            3'b000: out = {out, "fence    "};
            3'b001: out = {out, "fence.i  "};
            default: out = {out, "NULL     "};
        endcase
        out = {out, $sformatf("0x%03x", imm)};
    end
    // strange opcode likely not used
    else if (opc == opcode_I_system) begin
        logic [11:0] imm;   
        imm   = instruction[31:20];
        rs1   = instruction[19:15];
        func3 = instruction[14:12];
        rd    = instruction[11:7];
        case(func3)
            3'b000: out = (imm == 12'd0) ? "ecall    " : "ebreak   ";
            3'b001: out = {out, "csrrw    "};
            3'b010: out = {out, "csrrs    "};
            3'b011: out = {out, "csrrc    "};
            3'b101: out = {out, "csrrwi   "};
            3'b110: out = {out, "csrrsi   "};
            3'b111: out = {out, "csrrci   "};
            default: out = {out, "NULL     "};
        endcase
        if (func3 == 3'b000) begin
            out = out;
        end
        else if (func3[2] == 1'b1) begin
            out = {out, reg_name(rd), ",", $sformatf("%0d,", imm[4:0]), $sformatf("0x%03x", imm)};
        end
        else begin
            out = {out, reg_name(rd), ",", reg_name(rs1), $sformatf(",0x%03x", imm)};
        end
    end
    else if (opc == opcode_S) begin
        logic [11:0] imm;
        imm = {instruction[31:25], instruction[11:7]}; //split and must be rejoined
        rs1   = instruction[19:15];
        rs2   = instruction[24:20];
        func3 = instruction[14:12];
        case(func3)
            3'b000: out = {out, "sb      "};
            3'b001: out = {out, "sh      "};
            3'b010: out = {out, "sw      "};
            default: out = {out, "NULL    "};
        endcase
        out = {out, reg_name(rs2), ",", $sformatf("%0d(%s)", sign_extend(imm), reg_name(rs1))};
    end    
    else if (opc == opcode_B) begin
        logic [12:0] imm;
        rs1 = instruction[19:15];
        rs2 = instruction[24:20];
        func3 = instruction[14:12];
        imm = {instruction[31], instruction[7], instruction[30:25], instruction[11:8], 1'b0};

        case (func3)
            3'b000: out = {out, "beq     "};
            3'b001: out = {out, "bne     "};
            3'b100: out = {out, "blt     "};
            3'b101: out = {out, "bge     "};
            3'b110: out = {out, "bltu    "};
            3'b111: out = {out, "bgeu    "};
            default: out = {out, "NULL    "};
        endcase

        out = {out, reg_name(rs1), ",", reg_name(rs2), $sformatf(",0x%08x", sign_extend_13(imm) + pc)};
    end
    else if (opc == opcode_U) begin
        logic [31:0] imm;
        rd  = instruction[11:7];
        imm = {instruction[31:12], 12'b0};
        out = {out, "lui     ", reg_name(rd), ",", $sformatf("0x%08x", imm)};
    end
    else if (opc == opcode_U_PC) begin
        logic [31:0] imm;
        rd  = instruction[11:7];
        imm = {instruction[31:12], 12'b0};
        out = {out, "auipc   ", reg_name(rd), ",", $sformatf("0x%08x", imm)};
    end
    else if (opc == opcode_J) begin
        logic [20:0] imm;
        rd = instruction[11:7];
        imm = {instruction[31], instruction[19:12], instruction[20], instruction[30:21], 1'b0};
        out = {out, "jal     ", reg_name(rd), $sformatf(",0x%08x", sign_extend_21(imm) + pc)};
    end


    out = {out, "\n"};
    $write(out);
endfunction

function automatic string reg_name(input logic [4:0] reg_num);
    case (reg_num)
        5'd0:  return "x0"; // zero
        5'd1:  return "ra"; // return address
        5'd2:  return "sp"; // stack pointer
        5'd3:  return "gp"; // global pointer
        5'd4:  return "tp"; // thread pointer
        5'd5:  return "t0"; // temporary 0
        5'd6:  return "t1"; // temporary 1
        5'd7:  return "t2"; // temporary 2
        5'd8:  return "s0"; // saved / frame pointer
        5'd9:  return "s1"; // saved register 1
        5'd10: return "a0"; // function arg / return val 0
        5'd11: return "a1"; // function arg / return val 1
        5'd12: return "a2"; // function arg 2
        5'd13: return "a3"; // function arg 3
        5'd14: return "a4"; // function arg 4
        5'd15: return "a5"; // function arg 5
        5'd16: return "a6"; // function arg 6
        5'd17: return "a7"; // function arg 7
        5'd18: return "s2"; // saved register 2
        5'd19: return "s3"; // saved register 3
        5'd20: return "s4"; // saved register 4
        5'd21: return "s5"; // saved register 5
        5'd22: return "s6"; // saved register 6
        5'd23: return "s7"; // saved register 7
        5'd24: return "s8"; // saved register 8
        5'd25: return "s9"; // saved register 9
        5'd26: return "s10"; // saved register 10
        5'd27: return "s11"; // saved register 11
        5'd28: return "t3"; // temporary 3
        5'd29: return "t4"; // temporary 4
        5'd30: return "t5"; // temporary 5
        5'd31: return "t6"; // temporary 6
        default: return "x?"; // invalid register
    endcase
endfunction

function automatic logic signed [31:0] sign_extend(input logic [11:0] imm);
    return {{20{imm[11]}}, imm};
endfunction
function automatic logic signed [31:0] sign_extend_13(input logic [12:0] imm);
    return {{19{imm[12]}}, imm};
endfunction
function automatic logic signed [31:0] sign_extend_21(input logic [20:0] imm);
    return {{11{imm[20]}}, imm};
endfunction

`endif