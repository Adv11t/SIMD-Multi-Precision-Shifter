`timescale 1ns / 1ps

module eight_bit_precision(
input [7:0] in, 
output reg [7:0] out, 
input clk,
input[2:0] shift_amount, 
input dir);
// dir = 0 => left shift & dir = 1 => right shift
always@(posedge clk) begin
    out <= (dir) ? in >> shift_amount : in << shift_amount;
end
endmodule

module multi_precision(
input [31:0] in, 
input dir, 
input clk,
output reg [31:0] out, 
input [4:0] shift_amount, 
input [1:0] mode);
// mode = 00 => 8 bit precision
// mode = 01 => 16 bit precision
// mode = 10 => 32 bit precision
// dir = 0 => left shift & dir = 1 => right shift
wire [7:0] p0 = in[7:0];
wire [7:0] p1 = in[15:8];
wire [7:0] p2 = in[23:16];
wire [7:0] p3 = in[31:24];
wire [7:0] p0_updated,p1_updated,p2_updated,p3_updated;
eight_bit_precision u0(.in(p0), .dir(dir), .out(p0_updated), .shift_amount(shift_amount[2:0]),.clk(clk));
eight_bit_precision u1(.in(p1), .dir(dir), .out(p1_updated), .shift_amount(shift_amount[2:0]),.clk(clk));
eight_bit_precision u2(.in(p2), .dir(dir), .out(p2_updated), .shift_amount(shift_amount[2:0]),.clk(clk));
eight_bit_precision u3(.in(p3), .dir(dir), .out(p3_updated), .shift_amount(shift_amount[2:0]),.clk(clk));
always @(posedge clk) begin
case(mode)
// 8 bit precision
2'b00: out <= {p3_updated,p2_updated,p1_updated,p0_updated}; 
//16 bit precision
2'b01: begin
// left
if(dir == 1'b0) begin
    if(shift_amount<8) begin
        out[15:0] <= {p1_updated|(p0>>(8-shift_amount)), p0_updated};
        out[31:16] <= {p3_updated|(p2>>(8-shift_amount)), p2_updated};        
    end
    else begin
        out[15:0] <= {p0<<(shift_amount-8),8'd0};
        out[31:16] <= {p2<<(shift_amount-8),8'd0};
    end
end
// right
else begin
    if(shift_amount<8) begin
        out[15:0] <= {p1_updated,(p1<<(8-shift_amount))|p0_updated};
        out[31:16] <= {p3_updated,(p3<<(8-shift_amount))|p2_updated};     
    end
    else begin
        out[15:0] <= {8'd0,p1>>(shift_amount-8)};
        out[31:16] <= {8'd0,p3>>(shift_amount-8)};
    end    
end
end
// 32 bit precision
2'b10: begin
//left
if(dir == 1'b0) begin
    if(shift_amount<8) begin
        out[31:0] <= {p3_updated|(p2>>(8-shift_amount)), p2_updated|(p1>>(8-shift_amount)),p1_updated|(p0>>(8-shift_amount)), p0_updated};
    end
    else if(shift_amount<16) begin 
        out[31:0] <= {p2_updated|(p1>>(16-shift_amount)),p1_updated|(p0>>(16-shift_amount)),p0_updated,8'd0};
    end
    else if(shift_amount<24) begin 
        out[31:0] <= {p1_updated|(p0>>(24-shift_amount)),p0_updated,16'd0};
    end
    else begin 
        out[31:0] <= {p0_updated,24'd0};
    end
end
//right
else begin
    if(shift_amount<8) begin
        out[31:0] <= {p3_updated,(p3<<(8-shift_amount))|p2_updated,(p2<<(8-shift_amount))|p1_updated,(p1<<(8-shift_amount))|p0_updated};
    end
    else if(shift_amount<16) begin 
        out[31:0] <= {8'd0,p3_updated,(p3<<(16-shift_amount))|p2_updated,(p2<<(16-shift_amount))|p1_updated};
    end
    else if(shift_amount<24) begin 
        out[31:0] <= {16'd0,p3_updated,(p3<<(24-shift_amount))|p2_updated};
    end
    else begin 
        out[31:0] <= {24'd0,p3_updated};
    end
end
end
endcase
end
endmodule
