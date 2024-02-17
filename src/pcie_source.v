`define S_AXI_ADDR_WIDTH 64
`define S_AXI_DATA_WIDTH 512
    
module pcie_source
(
    input   clk, resetn,
    
    //======================  An AXI Slave Interface  =========================
    
    // "Specify write address"         -- Master --    -- Slave --
    input[`S_AXI_ADDR_WIDTH-1:0]      S_AXI_AWADDR,
    input                             S_AXI_AWVALID,
    input[2:0]                        S_AXI_AWPROT,
    input[3:0]                        S_AXI_AWID,
    input[7:0]                        S_AXI_AWLEN,
    input[2:0]                        S_AXI_AWSIZE,
    input[1:0]                        S_AXI_AWBURST,
    input                             S_AXI_AWLOCK,
    input[3:0]                        S_AXI_AWCACHE,
    input[3:0]                        S_AXI_AWQOS,
    output                                              S_AXI_AWREADY,
    
    
    // "Write Data"                    -- Master --    -- Slave --
    input[`S_AXI_DATA_WIDTH-1:0]      S_AXI_WDATA,
    input                             S_AXI_WVALID,
    input[(`S_AXI_DATA_WIDTH/8)-1:0]  S_AXI_WSTRB,
    input                             S_AXI_WLAST,
    output                                              S_AXI_WREADY,
    
    
    // "Send Write Response"           -- Master --    -- Slave --
    output [1:0]                                        S_AXI_BRESP,
    output                                              S_AXI_BVALID,
    input                             S_AXI_BREADY,
    
    // "Specify read address"          -- Master --    -- Slave --
    input[`S_AXI_ADDR_WIDTH-1:0]      S_AXI_ARADDR,
    input                             S_AXI_ARVALID,
    input[2:0]                        S_AXI_ARPROT,
    input                             S_AXI_ARLOCK,
    input[3:0]                        S_AXI_ARID,
    input[7:0]                        S_AXI_ARLEN,
    input[2:0]                        S_AXI_ARSIZE,
    input[1:0]                        S_AXI_ARBURST,
    input[3:0]                        S_AXI_ARCACHE,
    input[3:0]                        S_AXI_ARQOS,
    output reg                                          S_AXI_ARREADY,
    
    // "Read data back to master"      -- Master --    -- Slave --
    output reg [`S_AXI_DATA_WIDTH-1:0]                 S_AXI_RDATA,
    output reg                                         S_AXI_RVALID,
    output[1:0]                                        S_AXI_RRESP,
    output                                             S_AXI_RLAST,
    input                             S_AXI_RREADY
    //==========================================================================
    
);

reg[31:0] delay;
reg[63:0] araddr;
reg[ 7:0] arlen;
reg[ 3:0] fsm_state;

assign S_AXI_RLAST = S_AXI_RVALID & (arlen == 0);
assign S_AXI_RRESP = 0;

always @(posedge clk) begin
    
    if (delay) delay <= delay - 1;
    
    if (resetn == 0) begin
        fsm_state     <= 0;
        S_AXI_ARREADY <= 0;
        S_AXI_RVALID  <= 0;
    end else case(fsm_state)

        0:   begin
                S_AXI_ARREADY <= 1;
                fsm_state     <= fsm_state + 1;
            end

        1:  if (S_AXI_ARREADY & S_AXI_ARVALID) begin
                araddr        <= S_AXI_ARADDR;
                arlen         <= S_AXI_ARLEN;
                S_AXI_ARREADY <= 0;
                delay         <= 0;
                fsm_state     <= fsm_state + 1;
            end

        2:  if (delay == 0) begin
                S_AXI_RDATA  <= araddr;
                S_AXI_RVALID <= 1;
                fsm_state    <= fsm_state + 1;
            end

        3:  if (S_AXI_RREADY & S_AXI_RVALID) begin
                if (arlen) begin
                    S_AXI_RDATA <= araddr + 64;
                    araddr      <= araddr + 64;
                    arlen       <= arlen - 1;
                end else begin
                    S_AXI_RVALID  <= 0;
                    S_AXI_ARREADY <= 1;
                    fsm_state     <= 1;
                end
            end

    endcase
end
    
endmodule
    