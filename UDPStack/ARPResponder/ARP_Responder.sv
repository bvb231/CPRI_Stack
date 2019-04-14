module ARP_Responder
#(
    parameter   [47:0]  P_LOCAL_MAC = 'hAABBCCDD

)
(
input I_CLK,
input I_RESET,

//AXI STREAM INTERFACE SLAVE
output  S_AXIS_TREADY,
input   S_AXIS_TVALID,
input   S_AXIS_TUSER ,
input   [7:0]   S_AXIS_TDATA ,




//AXI STREAM INTERFACE MASTER
input   M_AXIS_TREADY,
output  M_AXIS_TVALID,
output  M_AXIS_TUSER ,
output  [7:0]  M_AXIS_TDATA


);
//All of these are assuming we are using IPV4

localparam  [15:0]   ETHER_TYPE  = 'h0806;

//Hardware Type
localparam  [15:0]   HTYPE   = 1;
//Protocol Type
localparam  [15:0]   PTYPE   = 'h0800;
//Hardware Length
localparam  [7:0]   HLEN    = 6;   
//Protocol Length
localparam  [7:0]   PLEN    = 4; 
//Request Operation
localparam  [15:0]  REQ_OPER    = 1; 
//Reply Operation
localparam  [15:0]  REPLY_OPER    = 1; 




logic [239:0]    pattern_buffer;


logic ethertype_match;
logic htype_match;
logic ptype_match;
logic hlen_match;
logic plen_match;
logic oper_match;

logic [47:0]    senders_mac_addr
logic [47:0]    recv_mac_addr

logic [31:0]    senders_ip_addr 
logic [31:0]    recv_ip_addr

//Receive Logic
always_ff @ (posedge CLK) begin 
    if(I_RESET == 1) begin 
    
    
    end else begin 
        if(S_AXIS_TVALID == 1) begin 
            pattern_buffer  <= {pattern_buffer[231:0], S_AXIS_TDATA};
        
        //We throw away the begninning local mac address because that field will be checked later on
        //within the ARP packet 
            if(pattern_buffer[239:224] = ETHER_TYPE) begin
                ethertype_match <= 1; 
            end
            if(pattern_buffer[223:208] = HTYPE) begin
                htype_match     <= 1; 
            end
            if(pattern_buffer[207:192] = PTYPE) begin
                ptype_match <= 1; 
            end
            if(pattern_buffer[191:184] = HLEN) begin
                hlen_match  <= 1; 
            end
            if(pattern_buffer[183:176] = PLEN) begin
                plen_match  <= 1; 
            end
            if(pattern_buffer[175:160] = REQ_OPER) begin
                oper_match  <= 1; 
            end
            senders_mac_addr    <= pattern_buffer[159:114];
            senders_ip_addr     <= pattern_buffer[159:128];
        
            //ignored
            recv_mac_addr       <= pattern_buffer[79:32];
            //ignored
            recv_ip_addr        <= pattern_buffer[31:0];
            
        
        end
    
    end
end

localparam ARP_OCTECT_LENGTH = 42;
logic [335:0]    transmit_buffer;

//Transmit Logic
always_ff @ (posedge CLK) beign 
    if(I_RESET == 1) begin 
        octect_count <= ARP_OCTECT_LENGTH-1;
    end else begin 
        if(ethertype_match == 1 && htype_match == 1 && ptype_match == 1 && hlen_match == 1 && plen_match == 1 && oper_match == 1) begin 
            octect_count                <= 0;
            transmit_buffer[47:0]       <= senders_mac_addr;
            transmit_buffer[95:48]      <= P_LOCAL_MAC;
            transmit_buffer[111:96]     <= ETHER_TYPE;
            transmit_buffer[127:112]    <= HTYPE;
            transmit_buffer[143:128]    <= PTYPE;
            transmit_buffer[151:144]    <= HLEN;
            transmit_buffer[159:152]    <= PLEN;
            transmit_buffer[175:160]    <= REPLY_OPER;
            transmit_buffer[223:176]    <= P_LOCAL_MAC;
            transmit_buffer[255:224]    <= P_LOCAL_IPV4;
            transmit_buffer[303:256]    <= senders_mac_addr;
            transmit_buffer[335:304]    <= senders_ip_addr;
        end 
    
        if(octect_count != ARP_OCTECT_LENGTH-1) begin 
            //[start+:increment width] 
            M_AXIS_TUSER    <= transmit_buffer[octect_count*8:+8];
            M_AXIS_TVALID   <= 1; 
            octect_count    <= octect_count + 1; 
        end
        
    
    end 
end

endmodule