create table customers (
    customer_id serial primary key,
    full_name varchar(100) not null,
    email varchar(100) unique not null,
    balance numeric(10,2) default 0
);

create table products (
    product_id serial primary key,
    product_name varchar(100) not null,
    price numeric(10,2) not null,
    stock_quantity int not null
);

create table orders (
    order_id serial primary key,
    customer_id int references customers(customer_id),
    order_date timestamp default current_timestamp,
    total_amount numeric(10,2) default 0
);

create table order_items (
    order_item_id serial primary key,
    order_id int references orders(order_id),
    product_id int references products(product_id),
    quantity int not null,
    price numeric(10,2) not null
);

create table order_log (
    log_id serial primary key,
    order_id int,
    customer_id int,
    action varchar(50),
    log_date timestamp default current_timestamp
);

''' Task 1 '''

create or replace function calculate_order_total(p_order_id int)
returns numeric(10,2) as $$
declare
    v_total numeric(10,2);
begin
    select coalesce(sum(quantity * price), 0)
    into v_total
    from order_items
    where order_id = p_order_id;

    return v_total;
end;
$$ language plpgsql;

select calculate_order_total(1)

'''Task 2'''

create or replace procedure create_order(p_customer_id int)
as $$
begin
    if not exists (select 1 from customers where customer_id = p_customer_id) then
        raise exception 'Customer with ID % does not exist.', p_customer_id;
    end if;

    insert into orders (customer_id, order_date, total_amount)
    values (p_customer_id, current_timestamp, 0.00);
end;
$$ language plpgsql;

call create_order(2)
call create_order(5)

'''Task 3'''

create or replace procedure add_product_to_order(
    p_order_id int,
    p_product_id int,
    p_quantity int
)
as $$
declare
    v_price numeric(10,2);
    v_stock int;
begin
    if p_quantity <= 0 then
        raise exception 'Quantity must be greater than zero';
    end if;

    select price, stock_quantity
    into v_price, v_stock
    from products
    where product_id = p_product_id;

    if v_price is null then
        raise exception 'Product does not exist';
    end if;

    if v_stock < p_quantity then
        raise exception 'Not enough in stock';
    end if;

    insert into order_items (order_id, product_id, quantity, price)
    values (p_order_id, p_product_id, p_quantity, v_price);

    update products
    set stock_quantity = stock_quantity - p_quantity
    where product_id = p_product_id;
end;
$$ language plpgsql;

call add_product_to_order(1, 3, 5)

'''Task 4'''

create or replace function tg_update_order_total()
returns trigger as $$
begin
    if tg_op = 'delete' then
        update orders
        set total_amount = calculate_order_total(old.order_id)
        where order_id = old.order_id;
    else
        update orders
        set total_amount = calculate_order_total(new.order_id)
        where order_id = new.order_id;

        if tg_op = 'update' and old.order_id <> new.order_id then
            update orders
            set total_amount = calculate_order_total(old.order_id)
            where order_id = old.order_id;
        end if;
    end if;
    return null;
end;
$$ language plpgsql;

create trigger trg_update_order_total
after insert or update or delete on order_items
for each row
execute function tg_update_order_total();

update order_items 
set quantity = 5 
where order_id = 1 and product_id = 2;

delete from order_items 
where order_id = 1 and product_id = 2;

'''Task 5'''

create or replace function tg_record_new_order()
returns trigger as $$
begin
    insert into order_log (order_id, customer_id, action, log_date)
    values (new.order_id, new.customer_id, 'create', current_timestamp);
    return null;
end;
$$ language plpgsql;

create trigger trg_record_new_order
after insert on orders
for each row
execute function tg_record_new_order();

