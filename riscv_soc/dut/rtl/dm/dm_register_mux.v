// Project: RISC-V Debug
// Company: ACL Digital
// Domain : RTL Design
// Author : Vinay Chowdary
// File   : dm_register_mux read file
// VErsion: 1.0 

`timescale 1ns/1ps
module dm_register_mux 
     #(  
      parameter ADDR_WIDTH = 32,                         // 32 bit address width
      parameter DATA_WIDTH = 32                          // 32 bit data width
      )
      (

      //DMI AMBA APB Interface signals
      input                              clock          ,
      input                              resetn         ,
      input                              apb_read       ,
      input [ADDR_WIDTH-1 : 0]           apb_addr       ,

      input [DATA_WIDTH-1:0]             dmstatus_reg   ,
      input [DATA_WIDTH-1:0]             dmcontrol_reg  ,
      input [DATA_WIDTH-1:0]             command_reg    ,
      input [DATA_WIDTH-1:0]             abstractcs_reg ,
      input [DATA_WIDTH-1:0]             data0_reg      ,
      input [DATA_WIDTH-1:0]             data1_reg      ,
      input [DATA_WIDTH-1:0]             data2_reg      ,
      input [DATA_WIDTH-1:0]             data3_reg      ,
      input [DATA_WIDTH-1:0]             data4_reg      ,
      input [DATA_WIDTH-1:0]             data5_reg      ,
      input [DATA_WIDTH-1:0]             data6_reg      ,
      input [DATA_WIDTH-1:0]             data7_reg      ,
      input [DATA_WIDTH-1:0]             data8_reg      ,
      input [DATA_WIDTH-1:0]             data9_reg      ,
      input [DATA_WIDTH-1:0]             data10_reg     ,
      input [DATA_WIDTH-1:0]             data11_reg     ,

      output reg                         data_rd_valid  ,
      output reg [DATA_WIDTH-1:0]        reg_data_out  );

        
      always@(posedge clock or negedge resetn)
         begin
            if(!resetn)
               begin
                  reg_data_out <= 32'b0;
                  data_rd_valid <= 1'b0;
               end
            else
               begin
                  if(apb_read)
                     begin
                        data_rd_valid <= 1'b1;
                        case(apb_addr[7:0])
                        8'h04 :   reg_data_out <= data0_reg  ;
                        8'h05 :   reg_data_out <= data1_reg  ;
                        8'h06 :   reg_data_out <= data2_reg  ;
                        8'h07 :   reg_data_out <= data3_reg  ;
                        8'h08 :   reg_data_out <= data4_reg  ;
                        8'h09 :   reg_data_out <= data5_reg  ;
                        8'h0a :   reg_data_out <= data6_reg  ;
                        8'h0b :   reg_data_out <= data7_reg  ;
                        8'h0c :   reg_data_out <= data8_reg  ;
                        8'h0d :   reg_data_out <= data9_reg  ;
                        8'h0e :   reg_data_out <= data10_reg ;
                        8'h0f :   reg_data_out <= data11_reg ;
                        8'h10 :   reg_data_out <= {2'b0,dmcontrol_reg[29],2'b0,dmcontrol_reg[26:6],4'b0,dmcontrol_reg[1:0]} ;
                        8'h11 :   reg_data_out <= dmstatus_reg ;
                        8'h16 :   reg_data_out <= abstractcs_reg ;
                        8'h17 :   reg_data_out <= 32'b0;
                        default : reg_data_out <= 32'b0;
                        endcase
                     end
                  else
                     begin
                        reg_data_out <= 32'b0 ;
                        data_rd_valid <= 1'b0;
                     end
               end
         end

    
 endmodule


                                 
