

package pkg_instruction_decoding;

    import top_tb_typedef_pkg::*;

    typedef enum {SC_X0_ZERO, SC_X1_ONE, SC_X2_ALL_ONES, SC_X3_INT_MIN, SC_X4_INT_MAX,
                  SC_X5_SMALL_POS, SC_RANDOM} sc_operand_bin_e;

    typedef enum {VC_V0_UNUSED, VC_V1_RAGGED, VC_V2_5_RESERVED_UNUSED, VC_RANDOM} vc_operand_bin_e;


    function automatic instr_e classify_instr(
        signal_pkg::chip_select_e cs, logic [3:0] op, logic read_src2, logic is_branch, logic src1_vector
    );
        case(cs)
            signal_pkg::CS_SALU: begin
                if(read_src2) begin
                    case(op)
                        signal_pkg::ALU_ADD:  return I_ADD;
                        signal_pkg::ALU_SLL:  return I_SLL;
                        signal_pkg::ALU_SLT:  return I_SLT;
                        signal_pkg::ALU_SLTU: return I_SLTU;
                        signal_pkg::ALU_XOR:  return I_XOR;
                        signal_pkg::ALU_SRL:  return I_SRL;
                        signal_pkg::ALU_OR:   return I_OR;
                        signal_pkg::ALU_AND:  return I_AND;
                        signal_pkg::ALU_SUB:  return I_SUB;
                        default: return UNKNOWN;
                    endcase
                end else begin
                    case(op)
                        signal_pkg::ALU_ADD:  return I_ADDI;
                        signal_pkg::ALU_SLL:  return I_SLLI;
                        signal_pkg::ALU_SLT:  return I_SLTI;
                        signal_pkg::ALU_SLTU: return I_SLTIU;
                        signal_pkg::ALU_XOR:  return I_XORI;
                        signal_pkg::ALU_SRL:  return I_SRLI;
                        signal_pkg::ALU_OR:   return I_ORI;
                        signal_pkg::ALU_AND:  return I_ANDI;
                        default: return UNKNOWN;
                    endcase
                end
            end
            signal_pkg::CS_MULDIV: begin
                case(op)
                    signal_pkg::MULDIV_MUL:    return M_MUL;
                    signal_pkg::MULDIV_MULH:   return M_MULH;
                    signal_pkg::MULDIV_MULHSU: return M_MULHSU;
                    signal_pkg::MULDIV_MULHU:  return M_MULHU;
                    signal_pkg::MULDIV_DIV:    return M_DIV;
                    signal_pkg::MULDIV_DIVU:   return M_DIVU;
                    signal_pkg::MULDIV_REM:    return M_REM;
                    signal_pkg::MULDIV_REMU:   return M_REMU;
                    default: return UNKNOWN;
                endcase
            end
            signal_pkg::CS_SLSU: begin
                case(op)
                    signal_pkg::LSU_LW: return I_LW;
                    signal_pkg::LSU_SW: return I_SW;
                    default: return UNKNOWN;
                endcase
            end
            signal_pkg::CS_BRANCH: begin
                case(op)
                    signal_pkg::BR_BEQ:  return I_BEQ;
                    signal_pkg::BR_BNE:  return I_BNE;
                    signal_pkg::BR_BLT:  return I_BLT;
                    signal_pkg::BR_BGE:  return I_BGE;
                    signal_pkg::BR_BLTU: return I_BLTU;
                    signal_pkg::BR_BGEU: return I_BGEU;
                    default: return UNKNOWN;
                endcase
            end
            signal_pkg::CS_VALU: begin
                if(src1_vector) begin // funct3==000 -> .vv
                    case(op)
                        signal_pkg::VALU_ADD:  return V_ADD_VV;
                        signal_pkg::VALU_SUB:  return V_SUB_VV;
                        signal_pkg::VALU_RSUB: return UNKNOWN; // no V_RSUB_VV member — see note above
                        signal_pkg::VALU_AND:  return V_AND_VV;
                        signal_pkg::VALU_OR:   return V_OR_VV;
                        signal_pkg::VALU_XOR:  return V_XOR_VV;
                        default: return UNKNOWN;
                    endcase
                end else begin // funct3==100 -> .vx
                    case(op)
                        signal_pkg::VALU_ADD:  return V_ADD_VX;
                        signal_pkg::VALU_SUB:  return V_SUB_VX;
                        signal_pkg::VALU_RSUB: return V_RSUB_VX;
                        signal_pkg::VALU_AND:  return V_AND_VX;
                        signal_pkg::VALU_OR:   return V_OR_VX;
                        signal_pkg::VALU_XOR:  return V_XOR_VX;
                        default: return UNKNOWN;
                    endcase
                end
            end
            signal_pkg::CS_VLSU: begin
                case(op)
                    signal_pkg::VLSU_VLE32: return V_LE32;
                    signal_pkg::VLSU_VSE32: return V_SE32;
                    default: return UNKNOWN;
                endcase
            end
            signal_pkg::NONE: begin
                if(is_branch) return I_JAL;
                else          return I_LUI; // LUI/AUIPC indistinguishable — always call it I_LUI
            end
            default: return UNKNOWN;
        endcase
    endfunction : classify_instr

    function automatic sc_operand_bin_e classify_sc_operand(signal_pkg::arf_address_t addr);
        case(addr)
            5'd0: return SC_X0_ZERO;
            5'd1: return SC_X1_ONE;
            5'd2: return SC_X2_ALL_ONES;
            5'd3: return SC_X3_INT_MIN;
            5'd4: return SC_X4_INT_MAX;
            5'd5: return SC_X5_SMALL_POS;
            default: return SC_RANDOM;
        endcase
    endfunction

    function automatic vc_operand_bin_e classify_vc_operand(signal_pkg::arf_address_t addr);
        case(addr)
            5'd0: return VC_V0_UNUSED;
            5'd1: return VC_V1_RAGGED;
            5'd2, 5'd3, 5'd4, 5'd5: return VC_V2_5_RESERVED_UNUSED;
            default: return VC_RANDOM;
        endcase
    endfunction

    function automatic bit src2_valid(
        signal_pkg::chip_select_e cs,
        signal_pkg::operations_e op,
        logic read_src2
    );

        case(cs)
            signal_pkg::CS_SALU, signal_pkg::CS_MULDIV, signal_pkg::CS_VALU: return read_src2;
            signal_pkg::CS_BRANCH: return 1'b1;
            signal_pkg::CS_SLSU, signal_pkg::CS_VLSU: return op[3];
            default: return 1'b0;
        endcase

    endfunction


endpackage;