Maintaining an Order Book which is a succinct representation of the market is one of the most important aspexts of a trading system. Typically each order book has two sides: bid and ask. 
This project only focuses on the bid side of the book with the objective of keeping track of the best price on the market as transactions are added, cancelled and executed. 
This project assumes that there are only three types of messages that can be received from an exchange:
ADD ORDER: the exchange specifies the order id, the price, and quantity of an order. The order book should accept this as a new order and appropriately update the size and best price on the market for that stock.
CANCEL ORDER: the exchange specifies an order id, and the order should be removed from the market.
EXECUTE TRADE: the exchange specifies an order id, and a quantity to decrease the order by.
Add order messages are handled by the add_order module and Cancel and Execute messages are handled by the delete_order module.

Below is a schematic of the connections between the modules in this project

<img width="606" alt="Screenshot 2024-01-03 at 13 21 33" src="https://github.com/jdakrofi/FPGA_OrderBook/assets/110293638/8e801061-0518-46c2-83ad-db9fd5d6f493">
The code in this project is based entirely on the following tutorial (https://web.mit.edu/6.111/volume2/www/f2019/projects/endrias_Project_Final_Report.pdf)
