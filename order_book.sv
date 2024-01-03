`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 02.01.2024 06:26:31
// Design Name: 
// Module Name: order_book
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
    - In this order_book module an instance of the memory_manager module is created. 
    - All orders are store in the memory_manager.
    add_order and delete_order modules are also instantied in this order_book module
    and they are used to manipulate the contents of the memory manager module in a manner
    that only permits one operation per port at any moment in time.
    - Adding an order the order book is done through the add_order module and Cancel and Execute
    instuctions are carried out by the delete_order module
    - The order_book module also ensures that we have the best price of particular stock
    at any given time.
    - 
*/
// 
//////////////////////////////////////////////////////////////////////////////////
`include "constants.sv"

module order_book #(parameter IS_MAX = MAX)(
    input clk_in,
    input rst_in,
    input book_entry order_to_add,
    input start_book,
    input delete,
    input [2:0] request,
    input [ORDER_INDEX:0] order_id,
    input [QUANTITY_INDEX:0] quantity,
    output logic is_busy_o,
    output logic [CANCEL_UPDATE_INDEX:0] cancel_update,
    output logic [PRICE_INDEX:0] best_price_o,
    output logic best_price_valid,
    output logic [SIZE_INDEX:0] size_book);
    
    localparam MAX_INDEX = 0;
    localparam START = 0;
    localparam PROGRESS = 1;
    localparam WAITING_STATE = 2'b00;
    localparam PROGESS_STATE = 2'b01;
  
    
    book_entry data_i;
    book_entry data_o;
    book_entry add_data_w;
    book_entry decrease_w;
    
    logic start;
    logic [ADDRESS_INDEX:0] addr;
    logic [ADDRESS_INDEX:0] add_addr;
    logic [PRICE_INDEX:0] best_price = 0;
    logic [PRICE_INDEX:0] add_best_price;
    logic [PRICE_INDEX:0] decrease_best_price;
    logic mem_start;
    logic valid;
    logic is_write;
    logic is_write_add;
    logic add_start;
    logic decrease_start;
    logic add_ready;
    logic decrease_ready;
    logic add_mem_start;
    logic valid_mem;
    logic units_busy;
    logic [QUANTITY_INDEX:0] price_distr [0:MAX_INDEX];
    logic [2:0] request_latched = 0;
    logic is_busy = 0;
    logic [SIZE_INDEX:0] current_size = 0;
    logic [SIZE_INDEX:0] add_size;
    logic [SIZE_INDEX:0] decrease_size;
    
    
    assign best_price_o = best_price;
    assign is_busy_o = is_busy;
    assign size_book = current_size;
    assign best_price_valid = current_size > 0;
    
    memory_manager book_mem(.clk_in(clk_in), .start(mem_start), .is_write(is_write),
    .addr(addr), .data_i(data_i), .data_o(data_o), .valid(valid_mem));
    
    add_order order_adder(.clk_in(clk_in), .order(order_to_add), .start(add_start),
    .valid(valid_mem), .price_valid(best_price_valid), .best_price(best_price),
    .size(current_size), .addr(add_addr), .mem_start(add_mem_start), .is_write(is_write_add),
    .ready(add_ready), .size_update_o(add_size), .data_w(add_data_w), .add_best_price(add_best_price));
    
    read_result read_output;
    mem_struct mem_control;
    
    assign read_output.first = data_o;
    logic delete_actual;
    
    decrease_order order_decreaser(.clk_in(clk_in), .id(order_id), .quantity(quantity), 
    .delete(delete_actual), .best_price(best_price), .mem_valid(valid_mem), .size(current_size),
    .start(decrease_start), .data_r(read_output), .mem_control(mem_control), .data_w(decrease_w),
    .ready(decrease_ready), .size_update_o(decrease_size), .update(cancel_update));
    
/*
- Based on request, the mux determines whether output data from the add_order and delete_order modules is fed
  into the memory manager.
     
*/
    
    always_comb begin
        if(is_busy)begin
            case(request_latched)
                ADD_ORDER: begin
                    addr = add_addr;
                    is_write = is_write_add;
                    mem_start = add_mem_start;
                    data_i = add_data_w;
                    units_busy = !add_ready;
                end //ASS_ORDER
                CANCEL_ORDER, EXECUTE_ORDER:begin
                    addr = mem_control.addr;
                    is_write = mem_control.is_write;
                    mem_start = mem_control.start;
                    data_i = decrease_w;
                    units_busy = !decrease_ready;
                end //CANCEL_ORDER
                default:begin
                    addr = 0;
                    is_write = 0;
                    mem_start = 0;
                    data_i = 0;
                    units_busy = 0;
                end // DEFAULT
            endcase
        end // if
        else begin
            addr = 0;
            is_write = 0;
            mem_start = 0;
            data_i = 0;
            units_busy = 0;
        end
    end
    
    logic [3:0] add_state;
    logic [1:0] add_mem_state;
    logic [1:0] current_state = WAITING_STATE;
    
    always_ff@(posedge clk_in)begin
        if(rst_in) begin
            current_size <= 0;
            is_busy <= 0;
            for (integer i = 0; i< MAX_INDEX; i++) price_distr[i] <=0;
        end // if
        else begin
            if(is_busy) begin
                add_start <= 0;
                decrease_start <= 0;
                if(!units_busy) begin
                    is_busy <= 0;
                    case(request_latched)
                        ADD_ORDER: begin
                            current_size <= add_size;
                            best_price <= add_best_price;
                        end // ADD_ORDER
                        CANCEL_ORDER, EXECUTE_ORDER: current_size <= decrease_size;
                    endcase
                end // if(!units_busy)
            end // if(is_busy)
            else begin
                if(start_book) begin
                    request_latched <= request;
                    is_busy <= 1;
                    case(request) 
                        ADD_ORDER: begin
                            add_start <= 1;
                            price_distr[order_to_add.price] <= price_distr[order_to_add.price] +
                            order_to_add.quantity;
                        end //ADD_ORDER
                        CANCEL_ORDER:begin
                            decrease_start <= 1;
                            delete_actual <= 1;
                        end//CANCEL_ORDER
                        EXECUTE_ORDER:begin
                            decrease_start <= 1;
                            delete_actual <= 0;
                        end //EXECUTE_ORDER
                    endcase
                end // if(start_book)
            end //else to if(is_busy)
        end // else to if(rst)
    end// always
    
endmodule
