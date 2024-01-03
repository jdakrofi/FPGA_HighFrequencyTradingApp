`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03.01.2024 09:41:48
// Design Name: 
// Module Name: order_book_wrapper
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
    This module creates an instance of the order_book module for each stock that is 
    to me traded.
    
    It is resposible for taking in a request to update the order book for 
    a particular stock and outputting the releveant market events (best prices of all 
    stock and the sizes) to the training module. 
    
    It also outputs a valid signal per stock to indicate if the best price of the stock is valid.
    
    It outputs the current best price for all the stocks and the size of the book for the 
    different stocks. The protocol for communication is as follows: if the order_book_wrapper
    is not busy,and the start signal is asserted, this module will latch on to the request that is incoming,
    and the signal is_busy goes high after the cycle. When the request is completed the is_busy
    signal goes low.
*/
//////////////////////////////////////////////////////////////////////////////////

`include "constants.sv"
module order_book_wrapper #(parameter N=4)(
    input clk_in,
    input rst_in,
    input [STOCK_INDEX:0]stock_to_add,
    input book_entry order_to_add,
    input start,
    input delete,
    input [QUANTITY_INDEX:0] quantity,
    input [2:0] request,
    input [ORDER_INDEX:0] order_id,
    output logic is_busy,
    output logic best_price_valid,
    output logic [CANCEL_UPDATE_INDEX:0] cancel_update,
    output logic [PRICE_INDEX:0] best_price_stocks [0:NUM_STOCK_INDEX],
    output logic [0:NUM_STOCK_INDEX] best_prices_valid,
    output logic [SIZE_INDEX:0] size_of_stocks [0:NUM_STOCK_INDEX]
 );
 
 logic [NUM_STOCK_INDEX:0] order_book_start;
 logic [NUM_STOCK_INDEX:0] book_busy;
 logic [STOCK_INDEX:0] stock_latched;
 
 localparam WAITING = 2'b00;
 localparam INITIATE = 2'b01;
 localparam PROGRESS = 2'b10;
 
 assign best_price_valid = &best_prices_valid;
 
 logic [2:0] state = WAITING;
 assign is_busy = (state != WAITING); 
 
 genvar i;
 generate for(i=0; i<N; i=i+1) begin 
 // in orginal tutorial N was hard coded as 4.
 // 4 stocks were initially created.
    order_book #(.IS_MAX(MAX)) book(.clk_in(clk_in), .rst_in(rst_in), .order_to_add(order_to_add),
    .request(request), .start_book(order_book_start[i]), .order_id(order_id), .delete(delete), 
    .quantity(quantity), .is_busy_o(book_busy[i]), .best_price_o(best_price_stocks[i]),
    .best_price_valid(best_prices_valid[i]), .size_book(size_of_stocks[i]));
 end // generate
 endgenerate
 
 always_ff @(posedge clk_in) begin
    case(state)
        WAITING: begin
            if(start) begin
                if(stock_to_add < NUM_STOCKS) begin
                    state <= INITIATE;
                    stock_latched <= stock_to_add;
                    order_book_start[stock_to_add] <= 1;
                end // if(stock_to_add < NUM_STOCKS)
            end// if(start)
        end// WAITING
        INITIATE: begin
            state <= PROGRESS;
            order_book_start[stock_to_add] <= 0;
        end //INITIATE
        PROGRESS:begin
            if(!book_busy[stock_latched]) state <= WAITING;
        end
    endcase
 end // always_ff
 
endmodule
