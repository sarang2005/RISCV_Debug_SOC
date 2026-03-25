module cv32e40p_data2axi (
 input  logic        clk,
  input  logic        rst_n,

  // =========================
  // Core Data Interface (MASTER ? SLAVE)
  // =========================
  input  logic         data_req,
  input  logic         data_we,
  input  logic [3:0]   data_be,
  input  logic [31:0]  data_addr,
  input  logic [31:0]  data_wdata,
  output logic         data_gnt,
  output logic         data_rvalid,
  output logic [31:0]  data_rdata,

  // =========================
  // AXI SLAVE Interface (Debug MASTER)
  // =========================
  input  logic         axi_awvalid,
  output logic         axi_awready,
  input  logic [31:0]  axi_awaddr,

  input  logic         axi_wvalid,
  output logic         axi_wready,
  input  logic [31:0]  axi_wdata,
  input  logic [3:0]   axi_wstrb,

  output logic         axi_bvalid,
  input  logic         axi_bready,

  input  logic         axi_arvalid,
  output logic         axi_arready,
  input  logic [31:0]  axi_araddr,

  output logic         axi_rvalid,
  input  logic         axi_rready,
  output logic [31:0]  axi_rdata
);

  typedef enum logic [1:0] {
    IDLE,
    DEBUG_WRITE,
    DEBUG_READ
  } state_t;

  state_t state, next_state;

  // =========================
  // State register
  // =========================
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n)
      state <= IDLE;
    else
      state <= next_state;
  end

  // =========================
  // Next-state logic
  // =========================
  always_comb begin
    next_state = state;

    case (state)
      IDLE: begin
        if (axi_awvalid && axi_wvalid)
          next_state = DEBUG_WRITE;
        else if (axi_arvalid)
          next_state = DEBUG_READ;
      end

      DEBUG_WRITE: begin
        if (axi_bready)
          next_state = IDLE;
      end

      DEBUG_READ: begin
        if (axi_rready)
          next_state = IDLE;
      end
    endcase
  end

  // =========================
  // Output logic (ONE DRIVER)
  // =========================
  always_comb begin
    // Defaults
    data_gnt    = 1'b0;
    data_rvalid = 1'b0;
    data_rdata  = 32'b0;

    axi_awready = 1'b0;
    axi_wready  = 1'b0;
    axi_bvalid  = 1'b0;

    axi_arready = 1'b0;
    axi_rvalid  = 1'b0;
    axi_rdata   = 32'b0;

    case (state)
      IDLE: begin
        // Core access only when debug is idle
        data_gnt = data_req;

        axi_awready = 1'b1;
        axi_wready  = 1'b1;
        axi_arready = 1'b1;
      end

      DEBUG_WRITE: begin
        axi_bvalid  = 1'b1;
        data_rvalid = 1'b1; // write complete
      end

      DEBUG_READ: begin
        axi_rvalid  = 1'b1;
        axi_rdata   = data_rdata;
        data_rvalid = 1'b1;
      end
    endcase
  end

endmodule 
