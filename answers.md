1. What is the difference between a function and a procedure in PostgreSQL?
Answer: a function must return a value (or void) and can be called directly within standard SQL queries using SELECT. In contrast, a procedure does not return a value via a RETURN statement, is invoked using the CALL command.
2. Can a trigger be executed manually? Why or why not?
Answer: no, it is a reactive database object designed to automatically fire only in response to a specific data modification event on its assosiated table. To activate it, you must perform the action on thet table, as the database completely controls its execution lifecycle.
3. What are the advantages and disadvantages of storing business logic inside the database?
Answer: advantages: high performance, security, data integrity.
        disadvantages: difficult testing and debugging.
