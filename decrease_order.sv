`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 02.01.2024 14:28:24
// Design Name: 
// Module Name: decrease_order
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
   - This decrease_order module executes the  cancellation of orders and reduction the quantities on the
   order book when a stock is sold.
   - It takes the order id of the order to be modified as an input as well as the quantity to modify it by 
   - It outputs signals via the order_book module which effect the requisite changes in the memory_manager 
   module.
*/ 
// 
//////////////////////////////////////////////////////////////////////////////////

`include "constants.sv"
module decrease_order #(parameter SIDE=BUY_SIDE)(
    input clk_in,
    input logic [ORDER_INDEX:0] id,
    input [QUANTITY_INDEX:0] quantity,
    input [PRICE_INDEX:0] best_price,
    input delete,
    input mem_valid,
    input [SIZE_INDEX:0] size,
    input start,
    input read_result data_r,
    output mem_struct mem_control,
    output book_entry data_w,
    output logic ready,
    output logic [SIZE_INDEX:0] size_update_o,
    output logic [CANCEL_UPDATE_INDEX:0] update 
    );
    
    localparam WAITING = 3'b000;
    localparam FIND = 3'b001;
    localparam DELETE = 3'b010;
    localparam UPDATE = 3'b110;
    localparam DONE = 3'b011;
    localparam NOT_FOUND = 3'b111;
    localparam COPY = 2'b00;
    localparam MOVE = 2'b01;
    localparam MEM_IDLE = 0;
    localparam MEM_PROGRESS = 1;
    
    logic [SIZE_INDEX:0] index;
    logic [SIZE_INDEX:0] size_latched;
    logic [SIZE_INDEX:0] update_index;
    logic [QUANTITY_INDEX:0] quantity_latched;
    logic [2:0] mem_state = MEM_IDLE;
    logic [2:0] state = WAITING;
    logic [2:0] delete_state;
    logic delete_latched;
    book_entry copy_entry;
    
    assign size_update_o = size_latched;
    
/*
-  This state machine that scans memory_manager from 0 to the size of the current book,
looking for the order ID. 
- If the order ID is not found then the order must not have been stored thus, updates are not necessary.
- If the order is found, the quantity on the memory_manager is updated and checked to see if its still
 non zero.
- To delete an order after we identify its index (i) , the state machine that grabs the element at
 index i + 1 and moves it to index i, and repeats this operation for all other orders after index i+1 
*/
    
    always_ff@(posedge clk_in)begin
    case(state) 
        WAITING: begin
            data_w <= 0;
            update <= WAITING;
            if(start) begin
                index <= 0;
                state <= FIND;
                mem_state <= MEM_IDLE;
                size_latched <= size;
                quantity_latched <= quantity;
                delete_latched <= delete;
                ready <= 0;
            end //start
            else ready <= 0;
        end// WAITING
        UPDATE:begin
            case(mem_state)
                MEM_IDLE:begin
                    mem_control.addr <= update_index;
                    mem_control.is_write <= 1;
                    mem_control.start <= 1;
                    data_w <= '{price:copy_entry.price, order_id:copy_entry.order_id,
                    quantity:copy_entry.quantity-quantity_latched};
                    mem_state <= MEM_PROGRESS;
                end// MEM_IDLE 
                MEM_PROGRESS: begin
                    mem_control.start <= 0;
                    if(mem_valid) begin
                        mem_state <= MEM_IDLE;
                        state <= WAITING;
                        update <= UPDATE;
                        ready <= 1;
                    end //if(mem_valid)
                end// MEM_PROGRESS
            endcase
        end //UPDATE 
        FIND:begin
            case(mem_state)
                MEM_IDLE: begin
                    if(index < size_latched)begin
                        mem_control <= '{addr: index, is_write:0, start:1};
                        mem_state <= MEM_PROGRESS;
                    end //if(index < size_latched)
                    else begin
                        state <= WAITING;
                        update <= NOT_FOUND;
                        ready <= 1;
                    end // else to if(index < size_latched)
                end //MEM_IDLE
                MEM_PROGRESS: begin
                    mem_control.start <= 0;
                    if(mem_valid) begin
                        mem_state <= MEM_IDLE;
                        if(data_r.first.order_id == id) begin
                            update_index <= index;
                            if(data_r.first.quantity <= quantity || delete_latched) begin
                                state <= DELETE;
                                delete_state <= COPY;
                            end// del_la
                            else begin
                                state <= UPDATE;
                                copy_entry <= data_r.first;
                            end //else
                        end //if(data_r.first.order_id == id)
                        else index <=index +1;
                        
                    end//if(mem_valid)
                end //MEM_PROGRESS
            endcase
        end //FIND
        
        DELETE: begin
        case(delete_state)
            COPY:begin
                case(mem_state)
                    MEM_IDLE: begin
                        if(update_index +1 < size_latched) begin
                            mem_control.addr <= update_index + 1;
                            mem_control.is_write <= 0;
                            mem_control.start <= 1;
                            mem_state <= MEM_PROGRESS;
                        end //if 
                        else begin
                            size_latched <= size_latched - 1;
                            state <= WAITING;
                            ready <= 1;
                            update <= DELETE;
                         end// else
                    end//MEM_IDLE
                    
                    MEM_PROGRESS: begin
                        mem_control.start <= 0;
                        if(mem_valid) begin
                            copy_entry <= data_r.first;
                            delete_state <= MOVE;
                            mem_state <= MEM_IDLE;
                        end // if(mem_valid)
                    end// MEM_PROGRESS
                endcase
            end //COPY
            MOVE: begin
                case(mem_state)
                    MEM_IDLE: begin
                        mem_control.addr <= update_index;
                        mem_control.is_write <= 1;
                        mem_control.start <= 1;
                        data_w <= copy_entry;
                        mem_state <= MEM_PROGRESS;
                    end //MEM_IDLE
                    MEM_PROGRESS: begin
                        mem_control.start <= 0;
                        if(mem_valid) begin
                            mem_state <= MEM_IDLE;
                            delete_state <= COPY;
                            update_index <= update_index + 1;
                        end // if
                    end// MEM_PROGRESS   
                endcase
                
            end// MOVe
        endcase
       end 
     endcase
     end
    //endcase
    //end//always
endmodule
