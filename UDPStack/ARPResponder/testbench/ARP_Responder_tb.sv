`timescale 1ns/1ns
module ARP_Responder_tb;

localparam   [31:0]  P_DUT_IPV4   = 'h11223344;
localparam   [47:0]  P_DUT_MAC    = 'hAABBCCDD;
localparam   [47:0]  TB_MAC         = 'hEEEEFFFF;
localparam   [31:0]  TB_IPV4   = 'hAABBCCdd;
localparam  [15:0]   ETHER_TYPE     = 'h0806;
localparam  [15:0]   HTYPE          = 1;
localparam  [15:0]   PTYPE          = 'h0800;
localparam  [7:0]   HLEN            = 6;   
localparam  [7:0]   PLEN            = 4; 
localparam  [15:0]  REQ_OPER        = 1; 
localparam  [15:0]  REPLY_OPER      = 1; 

//AXI STREAM INTERFACE SLAVE
logic S_AXIS_TREADY;
logic S_AXIS_TVALID;
logic S_AXIS_TUSER ;
logic [7:0]   S_AXIS_TDATA;

//AXI STREAM INTERFACE MASTER
logic M_AXIS_TREADY;
logic M_AXIS_TVALID;
logic M_AXIS_TUSER ;
logic [7:0]  M_AXIS_TDATA;


logic I_CLK = 0;
logic I_RESET;

logic [335:0]           ARP_REQUEST_MESSAGE;



assign  transmit_buffer[47:0]       = P_DUT_MAC;
assign  transmit_buffer[95:48]      = TB_MAC;
assign  transmit_buffer[111:96]     = ETHER_TYPE;
assign  transmit_buffer[127:112]    = HTYPE;
assign  transmit_buffer[143:128]    = PTYPE;
assign  transmit_buffer[151:144]    = HLEN;
assign  transmit_buffer[159:152]    = PLEN;
assign  transmit_buffer[175:160]    = REQ_OPER;
assign  transmit_buffer[223:176]    = TB_MAC;
assign  transmit_buffer[255:224]    = TB_IPV4;
assign  transmit_buffer[303:256]    = P_DUT_MAC ;
assign  transmit_buffer[335:304]    = P_DUT_IPV4    ;


localparam ARP_OCTECT_LENGTH = 42;
logic [335:0]           transmit_buffer;
logic [$clog2(336):0]   octect_count;



ARP_Responder
#(
    .P_DUT_IPV4   (P_DUT_IPV4),
    .P_DUT_MAC    (P_DUT_MAC)
)
DUT
(
    .I_CLK  (I_CLK),
    .I_RESET(I_RESET),

//AXI STREAM INTERFACE SLAVE
    .S_AXIS_TREADY(M_AXIS_TREADY),
    .S_AXIS_TVALID(M_AXIS_TVALID),
    .S_AXIS_TUSER (M_AXIS_TUSER ),
    .S_AXIS_TDATA (M_AXIS_TDATA ),

//AXI STREAM INTERFACE MASTER
    .M_AXIS_TREADY(S_AXIS_TREADY),
    .M_AXIS_TVALID(S_AXIS_TVALID),
    .M_AXIS_TUSER (S_AXIS_TUSER ),
    .M_AXIS_TDATA (S_AXIS_TDATA )
);

always #5 I_CLK = ~I_CLK;

initial begin
  I_RESET       = 1;
  #10 I_RESET   = 0;
  #10
  transmit_msg = 1; 
  @(posedge I_CLK);
  transmit_msg = 0;
  #500;
  $stop;
  
end


logic transmit_msg;
always_ff @ (posedge I_CLK) begin 
    if(I_RESET == 1) begin 
        octect_count    <= ARP_OCTECT_LENGTH-1;
    end else begin 
        if(transmit_msg == 1 ) begin 
            octect_count                <= 0;
            
        end 
    
        if(octect_count != ARP_OCTECT_LENGTH-1) begin 
            //[start+:increment width] 
            M_AXIS_TUSER    <= transmit_buffer[7:0];
            transmit_buffer[327:0] <= transmit_buffer[335:8];
            M_AXIS_TVALID   <= 1; 
            octect_count    <= octect_count + 1; 
        end
        
    
    end 
end


















endmodule;