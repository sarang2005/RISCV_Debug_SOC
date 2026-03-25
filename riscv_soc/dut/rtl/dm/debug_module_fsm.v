// Project: RISC-V Debug
// Company: ACL Digital
// Domain : RTL Design
// Author : Vinay Chowdary
// File   : Debug Module FSM
// Version: 1.0

`timescale 1ns/1ps
module debug_module_fsm (
    input       clock                   ,
    input       resetn                  ,
    input       dmactive                ,
    input       hartreset               ,
    input       haltreq                 ,
    input       resumereq               ,
    input       setresethaltreq         ,
    input       clrresethaltreq         ,
    input [2:0] cmderr                  ,
    input       access_reg_cmd          ,
    input       access_mem_cmd          ,
    input       access_reg_command_done ,
    input       access_mem_command_done ,

    output wire halted                  ,
    output wire running                 ,
    output wire hreset                 );


    // local parameter declaration for FSM states
    localparam  NORMAL_EXECUTION         = 3'b000;
    localparam  HART_RESET               = 3'b001; 
    localparam  HALTED                   = 3'b010;
    localparam  COMMAND_RUNNING          = 3'b011;
    localparam  ERROR_BUSY               = 3'b100;
    localparam  ERROR_WAIT               = 3'b101;

    // internal registers declarations
    reg [2:0]   present_state           ;
    reg [2:0]   next_state              ;
    reg         resethaltreq            ; //internal bit for resethaltreq feature

    //resethaltreq internal bit logic 
    always@(*)
       begin
          if(clrresethaltreq == 1'b1)
             resethaltreq <= 1'b0;
          else if(setresethaltreq == 1'b1)
             resethaltreq <= 1'b1;
          else
             resethaltreq <= resethaltreq;
       end

    //present state logic
    always@(posedge clock or negedge resetn)
       begin
          if(!resetn)
             begin
                present_state <= NORMAL_EXECUTION ;
             end
          else
             begin
                present_state <= next_state ;
             end
       end
 
    //next state logic
    always@(*)
       begin
          case(present_state)
             NORMAL_EXECUTION: begin
                                  if(hartreset)
                                     begin
                                        next_state <= HART_RESET ;
                                     end
                                  else if(haltreq)
                                     begin
                                        next_state <= HALTED ;
                                     end
                                  else 
                                     begin
                                        next_state <= NORMAL_EXECUTION ;
                                     end
                               end
             HART_RESET:      begin
                                 if(!dmactive)
                                     begin
                                        next_state <= HART_RESET ;
                                     end
                                  else if(hartreset == 1'b0 && resethaltreq == 1'b1)
                                     begin
                                        next_state <= HALTED ;
                                     end
                                  else if(hartreset == 1'b0 && resethaltreq == 1'b0)
                                     begin
                                        next_state <= NORMAL_EXECUTION ;
                                     end
                                  else 
                                     begin
                                        next_state <= HART_RESET ;
                                     end
                               end   
             HALTED:           begin
                                  if(!dmactive)
                                     begin
                                        next_state <= HART_RESET ;
                                     end
                                  else if(hartreset)
                                     begin
                                        next_state <= HART_RESET ;
                                     end
                                  else if(haltreq == 1'b0 && resumereq == 1'b1)
                                     begin
                                        next_state <= NORMAL_EXECUTION ;
                                     end
                                  else if(access_reg_cmd || access_mem_cmd)
                                     begin
                                        next_state <= COMMAND_RUNNING ;
                                     end

                                  else
                                     begin
                                        next_state <= HALTED ;
                                     end
                               end
             COMMAND_RUNNING:  begin
                                  if(!dmactive)
                                     begin
                                        next_state <= HART_RESET ;
                                     end
                                  else if(cmderr==3'b001)
                                     begin
                                        next_state <= ERROR_BUSY ;
                                     end
                                  else if (cmderr ==3'b010)
                                     begin
                                        next_state <= ERROR_WAIT ;
                                     end
                                  else if(access_reg_command_done || access_mem_command_done)
                                     begin
                                        next_state <= HALTED ;
                                     end
                                  else
                                     begin
                                        next_state <= COMMAND_RUNNING ;
                                     end
                               end
             ERROR_BUSY:       begin
                                  if(!dmactive)
                                     begin
                                        next_state <= HART_RESET ;
                                     end
                                  else if(access_reg_command_done || access_mem_command_done)
                                     begin
                                        next_state <= ERROR_WAIT ;
                                     end
                                  else
                                     begin
                                        next_state <= ERROR_BUSY ;
                                     end
                               end
             ERROR_WAIT:       begin
                                  if(!dmactive)
                                     begin
                                        next_state <= HART_RESET ;
                                     end
                                  else if(cmderr == 3'b000)
                                     begin
                                        next_state <= HALTED ;
                                     end
                                  else 
                                     begin
                                        next_state <= ERROR_WAIT ;
                                     end
                               end
             default:          begin
                                  next_state <= NORMAL_EXECUTION ;
                               end
          endcase
       end

    //output logic
    assign running = (present_state == NORMAL_EXECUTION) ? 1'b1 : 1'b0 ;
    assign hreset  = (present_state == HART_RESET) ? 1'b1 : 1'b0 ;
    assign halted  = (present_state == HALTED || present_state==COMMAND_RUNNING || present_state==ERROR_BUSY || present_state==ERROR_WAIT ) ? 1'b1 : 1'b0;

endmodule 
 
