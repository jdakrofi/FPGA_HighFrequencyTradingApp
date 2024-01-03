`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 02.01.2024 11:22:07
// Design Name: 
// Module Name: add_order
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
/*
   - This add_order module is used to add a new order to the order book.
   - It employs a ready-start protocol and when it gets a request it checks that there is sufficient space
   on the order book (size < MAX_INDEX) where MAX_INDEX == 100 and size represents the size of the order
   - If there is sufficient space on the order book, memory signals (add_mem_state and mem_start) are set and
   the order is stored. 
   - The module then waits for a signal (valid) to indicate the order has been committed before indicating
   that the next order can be written to memory.
   - This add_order module also updates the new size of the book and best buy price of the stock.
*/
// 
//////////////////////////////////////////////////////////////////////////////////

`include "constants.sv"
module add_order #(parameter IS_MAX=MAX)(
    input clk_in,
    input book_entry order,
    input start,
    input valid,
    input price_valid,
    input [QUANTITY_INDEX:0] price_distr,
    input [SIZE_INDEX:0] size,
    input [PRICE_INDEX:0] best_price,
    output logic [ADDRESS_INDEX:0] addr,
    output logic mem_start,
    output book_entry data_w,
    output logic price_update,
    output logic quantity_update,
    output quantity,
    output logic is_write,
    output logic ready,
    output logic [SIZE_INDEX:0] size_update_o,
    output logic [PRICE_INDEX:0] add_best_price);
    
    logic [1:0] add_mem_state = 0;
    logic [SIZE_INDEX:0] size_update = 0;
    
    localparam START = 0;
    localparam PROGRESS = 1;
    
    assign size_update_o = size_update;
    
    always_ff@(posedge clk_in) begin
        case(add_mem_state)
            START: begin
                ready <= 0;
                if(start) begin
                    if(size < MAX_INDEX) begin
                        addr <= size;
                        is_write <= 1;
                        size_update <= size + 1;
                        add_mem_state <= PROGRESS;
                        data_w <= order;
                        mem_start <= 1;
                        price_update <= order.price;
                        quantity_update <= order.quantity;
                        if(((!price_valid) || (order.price > best_price)) == IS_MAX) add_best_price <= order.price;
                        else add_best_price <= best_price;
                    end // if(size < MAX_INDEX)
                end // if(start)
            end// START
            PROGRESS: begin
                mem_start <= 0;
                if(valid) begin
                    ready <= 1;
                    add_mem_state <= START;
                end // if(valid)
            end // PROGRESS
        endcase
    end // always
    
    
endmodule
