//// Project: AXI Master
// Company: ACL Digital
// Domain : RTL Design
// Author : Vinay Chowdary
// File   : axi_master module
// Version: 1.0

`timescale 1ns/1ps
module axi_master 
    #(
     parameter ADDR_WIDTH = 64                         ,
     parameter DATA_WIDTH = 64                         )
     (
     //Global signals
     input                         aclk                , //system clock 
     input                         aresetn             , //active low reset signal
     //Write request channel signals
     input                         awready             ,
     output reg                    awvalid             ,
     output wire [3:0]             awid                , 
     output reg [ADDR_WIDTH-1:0]   awaddr              , 
     output reg [7:0]              awlen               , 
     output reg [2:0]              awsize              , 
     output reg [1:0]              awburst             , 
     output wire                   awlock              , 
     output wire [3:0]             awcache             ,
     output wire [2:0]             awprot              ,
     output wire [3:0]             awqos               ,
     //Write data channel
     input                         wready              ,
     output reg                    wvalid              ,
     output reg [DATA_WIDTH-1:0]   wdata               ,
     output reg[(DATA_WIDTH/8)-1:0]wstrb               ,
     output reg                    wlast               ,
     //Write response channel
     input [3:0]                   bid                 , 
     input [1:0]                   bresp               , 
     input                         bvalid              ,
     output reg                    bready              ,
     //Read resquest channel
     input                         arready             ,
     output reg                    arvalid             ,
     output wire [3:0]             arid                , 
     output reg [ADDR_WIDTH-1:0]   araddr              ,
     output reg [7:0]              arlen               ,
     output reg [2:0]              arsize              ,
     output reg [1:0]              arburst             ,
     output wire                   arlock              ,
     output wire [3:0]             arcache             ,
     output wire [2:0]             arprot              ,
     output wire [3:0]             arqos               ,
     //Read data channel
     input [3:0]                   rid                 , 
     input [DATA_WIDTH-1:0]        rdata               ,
     input [1:0]                   rresp               , 
     input                         rlast               ,
     input                         rvalid              ,
     output reg                    rready              ,
     //AXI Top driven Signals
     input                         transfer            , //initiates the transaction
     input                         write_en            , //indicates the write transaction
     input                         read_en             , //indicates the read transaction
     input [ADDR_WIDTH-1:0]        write_addr          , //write address
     input [ADDR_WIDTH-1:0]        read_addr           , //read address
     input [7:0]                   write_len           , //length of the data transfer
     input [2:0]                   write_size          , //size of the data transfer
     input [1:0]                   write_burst         ,
     input [DATA_WIDTH-1:0]        write_data          ,
     input [(DATA_WIDTH/8)-1:0]    write_strb          ,
     output reg [DATA_WIDTH-1:0]   read_data_out       ,
     output reg                    read_data_out_valid ,
     output reg [1:0]              error               ,
     input [7:0]                   read_len            ,
     input [2:0]                   read_size           ,
     input [1:0]                   read_burst         );

     //declaration of local parameters
     localparam IDLE    = 3'b000; //IDLE state
     localparam WR_ADDR = 3'b001; //Write Address Channel
     localparam WR_DATA = 3'b010; //Write Data Channel
     localparam WR_RESP = 3'b011; //Write Response Channel
     localparam RD_ADDR = 3'b100; //Read Address Channel
     localparam RD_DATA = 3'b101; //Read Data Channel

     //declaration of registers
     reg [1:0] present_state;
     reg [1:0] next_state;
     reg [7:0] wdata_sent;

     //unimplemented for now -- taken into consideration to match AXI slave
     assign awid    = 4'b0;      //Single threaded transaction
     assign awlock  = 1'b0;      //Exclusive access were not supported
     assign awcache = 4'b0;      //Cache not supported
     assign awprot  = 3'b0;      //Protection not implemented
     assign awqos   = 4'b0;      //Quality of service is not supported 
     assign arid    = 4'b0;      //Single threaded transaction
     assign arlock  = 1'b0;      //Exclusive access were not supported
     assign arcache = 4'b0;      //Cache not supported
     assign arprot  = 3'b0;      //Protection not implemented
     assign arqos   = 4'b0;      //Quality of service is not supported

     //present state logic
     always@(posedge aclk or negedge aresetn)
        begin
           if(!aresetn)
              begin
                 present_state <= IDLE; 
              end
           else
              begin
                 present_state <= next_state;
              end
        end

     //next state and output logic
     always@(*)
        begin
           case(present_state)
           IDLE:        begin
                           awaddr  = {ADDR_WIDTH{1'b0}};
                           awlen   = 8'b0;
                           awsize  = 3'b0;
                           awburst = 2'b0;
                           araddr  = {ADDR_WIDTH{1'b0}};
                           arlen   = 8'b0;
                           arsize  = 3'b0;
                           arburst = 2'b0;
                           error   = 2'b0;
                           wdata_sent = 8'b0;
                           read_data_out  = {DATA_WIDTH{1'b0}};
                           read_data_out_valid = 1'b0;

                           // 22-11-2024 changes(by MANOHAR REDDY A)
                           awvalid = 1'b0;
                           wvalid = 1'b0;
                           wdata = 64'h0;

                           if(transfer && write_en)
                              begin
                                 next_state = WR_ADDR ;
                                 awvalid    = 1'b1;
                                 arvalid    = 1'b0;
                              end
                           else if(transfer && read_en)
                              begin
                                 next_state = RD_ADDR ;
                                 awvalid    = 1'b0;
                                 arvalid    = 1'b1;
                              end
                           else
                              begin
                                 next_state = IDLE ;
                                 awvalid    = 1'b0;
                                 arvalid    = 1'b0;
                              end
                        end
           WR_ADDR:  begin
                           awaddr  = write_addr  ;
                           awlen   = write_len   ;
                           awsize  = write_size  ;
                           awburst = write_burst ;
                           wdata_sent = 8'b0;
                           if(awvalid && awready)
                              begin
                                 wvalid     = 1'b1;
                                 next_state = WR_DATA ;
                                 //awvalid    = 1'b0; 
                              end
                           else
                              begin
                                 next_state = WR_ADDR ;
                                 awvalid    = awvalid ;
                                 wvalid     = 1'b0;
                              end
                        end
           WR_DATA:  begin
                            if(wdata_sent < awlen)
                              begin
                                 wdata = write_data;
                                 wstrb = write_strb;
                                 wlast = 1'b0;
                                 wvalid = 1'b1;
                                 if(wvalid && wready)
                                    begin
                                       //wdata = write_data;
                                       next_state = WR_DATA;
                                       wdata_sent = wdata_sent + 1'b1;
                                    end
                                 else
                                    begin
                                       next_state = WR_DATA;
                                       wdata_sent = wdata_sent;
                                    end
                              end
                           else if(wdata_sent == awlen)
                              begin
                                 //wdata = write_data;
                                 wstrb = write_strb;
                                 wlast = 1'b1;
                                 //wvalid = 1'b1;
                                 if(wvalid && wready)
                                    begin
                                       //wdata = write_data;
                                       next_state = WR_RESP;
                                       wdata_sent = 8'b0;
                                       wvalid = 1'b0;
                                       bready = 1'b1;
                                    end
                                 else
                                    begin
                                       next_state = WR_DATA;
                                       wdata_sent = wdata_sent;
                                       wvalid = wvalid;
                                       bready = 1'b0;
                                    end
                              end
                        end
           WR_RESP:  begin
                           if(bvalid && bready)
                              begin
                                 next_state = IDLE;
                                 bready = 1'b0;
                                 error  = bresp;
                              end
                           else
                              begin
                                 next_state = WR_RESP ;
                                 bready = bready;
                                 error  = 2'b0;
                              end
                        end 
           RD_ADDR:   begin
                           araddr  = read_addr  ;
                           arlen   = read_len   ;
                           arsize  = read_size  ;
                           arburst = read_burst ;
                           read_data_out ={DATA_WIDTH{1'b0}};
                           read_data_out_valid = 1'b0;
                           if(arvalid && arready)
                              begin
                                 next_state = RD_DATA ;
                                 arvalid = 1'b0;
                                 rready  = 1'b1;
                              end
                           else
                              begin
                                 next_state = RD_ADDR ;
                                 arvalid = arvalid;
                                 rready  = 1'b0;
                              end
                        end
           RD_DATA:   begin
                           if(rvalid && rready)
                              begin
                                 if(rresp == 2'b00)
                                    begin
                                       error = 2'b00;
                                       if(rlast == 1'b1)
                                          begin
                                             next_state = IDLE;
                                             read_data_out = rdata;
                                             read_data_out_valid = 1'b1;
                                             rready = 1'b0;
                                          end
                                       else
                                          begin
                                             next_state = RD_DATA;
                                             read_data_out = rdata;
                                             read_data_out_valid = 1'b1;
                                             rready = rready;
                                          end
                                    end
                                 else
                                    begin
                                       next_state = IDLE;
                                       read_data_out = {DATA_WIDTH{1'b0}};
                                       read_data_out_valid = 1'b0;
                                       rready = 1'b0;
                                       error = rresp;
                                    end
                              end
                           else
                              begin
                                 next_state = RD_DATA ;
                                 rready = rready;
                                 read_data_out = {DATA_WIDTH{1'b0}};
                                 read_data_out_valid = 1'b0;
                                 error = 2'b00;
                              end 
                        end
           default:     begin
                           next_state = IDLE;
                        end
           endcase
        end

endmodule

