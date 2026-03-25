// Project: APB Slave
// Company: ACL Digital
// Domain : RTL Design
// Author : Vinay Chowdary
// File   : apb_slave module
// VErsion: 1.0
`timescale 1ns/1ps

module apb_slave 
    #(
     parameter ADDR_WIDTH = 32,                         // 32 bit address width
     parameter DATA_WIDTH = 32                          // 32 bit data width
     )
     (
     //APB Interface
     input                        pclock                     ,
     input                        presetn                    ,
     input                        psel                       ,
     input                        pwrite                     ,
     input                        penable                    ,
     input [ADDR_WIDTH-1:0]       paddr                      ,
     input [DATA_WIDTH-1:0]       pwdata                     ,
     output reg  [DATA_WIDTH-1:0] prdata                     ,
     output reg                   pready                     , 
     output reg                   pslverr                    , 
    
     //Signals to/from DM Module
     input  [DATA_WIDTH-1:0]      apb_rdata                  ,
     output reg                   apb_read                   ,
     output reg                   apb_write                  ,
     output reg [ADDR_WIDTH-1:0]  apb_addr                   ,
     input wire                   data_rd_valid              ,
     output reg [DATA_WIDTH-1:0]  apb_wdata                 );


   always@(posedge pclock or negedge presetn)
      begin
         if(!presetn)
            begin
               apb_write <= 1'b0;
               apb_read  <= 1'b0;
               apb_addr  <= {ADDR_WIDTH{1'b0}};
               apb_wdata <= {DATA_WIDTH{1'b0}};
               prdata    <= {DATA_WIDTH{1'b0}};
            end
         else
            begin
               if(psel && penable)
                  begin
                     if(pwrite)
                        begin
                           apb_write <= 1'b1;
                           apb_read  <= 1'b0;
                           apb_wdata <= pwdata;
                           apb_addr  <= paddr;
                           prdata    <= {DATA_WIDTH{1'b0}};
                        end
                     else
                        begin 
                           apb_write <= 1'b0;
                           apb_read  <= 1'b1;
                           apb_addr  <= paddr;
                           apb_wdata <= {DATA_WIDTH{1'b0}};
                           prdata    <= apb_rdata; 
                        end
                  end
               else
                  begin
                     apb_write <= 1'b0;
                     apb_read  <= 1'b0;
                     apb_addr  <= {ADDR_WIDTH{1'b0}};
                     apb_wdata <= {DATA_WIDTH{1'b0}};
                     prdata    <= {DATA_WIDTH{1'b0}};
                  end
            end
      end 
     
   //pslverr logic           
   always@(posedge pclock or negedge presetn)
      begin
         if(!presetn)
            begin
               pslverr <= 1'b0;
            end
         else
            begin
               if(psel && penable)
                  begin
                     if(paddr  < 32'h00000004 ||
                        paddr  > 32'h00000017 ||
                        paddr == 32'h00000012 ||
                        paddr == 32'h00000013 ||
                        paddr == 32'h00000014 ||
                        paddr == 32'h00000015  )
                        begin
                           pslverr <= 1'b1;
                        end
                     else
                        begin
                           pslverr <= 1'b0;
                        end
                  end
               else
                  begin
                     pslverr <= 1'b0;
                  end
            end
      end

   //pready logic
   always@(posedge pclock or negedge presetn)
      begin
         if(!presetn)
            begin
               pready <= 1'b0;
            end
         else
            begin
               if(psel && penable && data_rd_valid)
                     pready <= 1'b1;
               else
                     pready <= 1'b0;
            end
      end 



endmodule    
