`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 01.01.2024 18:04:53
// Design Name: 
// Module Name: memory_manager
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

`include "constants.sv"
module memory_manager(
    input clk_in,
    input logic start,
    input logic is_write,
    input logic [ADDRESS_INDEX:0] addr,
    input book_entry data_i,
    output book_entry data_o,
    output logic valid);
    
    logic [10:0] counter = 0;
    logic write;
    
    localparam WAITING = 0;
    localparam STARTED = 1;
    
    logic [2:0] state = WAITING;
    logic enable = 0;
    
    blk_mem_gen_0 mem(.clka(clk_in), .addra(addr), .douta(data_o), .dina(data_i), .ena(enable),
    .wea(write));
    
    always_ff@(posedge clk_in)begin
        case(state)
            WAITING: begin
                valid <= 0;
                if(start) begin
                    write <= is_write;
                    state <= STARTED;
                    counter <= 1;
                    enable <= 1;
                end // if
            end // WAITING
            
            STARTED: begin
                if(counter < BRAM_LATENCY) counter <= counter + 1;
                else begin
                    state <= WAITING;
                    counter <= 0;
                    valid <= 1;
                    enable <= 0;
                    write <= 0;
                end // else
            end // STARTED
        endcase // endcase
    end// always
    
endmodule
