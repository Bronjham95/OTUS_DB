/* ==================================================== */
/* Таблица Покупатели: */
/* ==================================================== */

create table consumer(
id 			INTEGER 	 not null,
first_name  VARCHAR(100) not null,
last_name   VARCHAR(100) not null,
second_name VARCHAR(100), -- может отсутствовать: например, иностранный гражданин
display     VARCHAR(300) not null,
birth_date  DATE 		 not null,
phone       VARCHAR(35)  not null,
email       VARCHAR(100) not null,
city        VARCHAR(100) not null 
);

-- Первичный ключ(PK)
alter table consumer
add constraint pk_consumer primary key (id);

-- Уникальное ограничение по номеру телефона: (телефон не должен повторяться)
alter table consumer
add constraint u_phone unique (phone);

-- Уникальное ограничение по электронной почте: (электронный ящик не должен повторяться)
alter table consumer
add constraint u_email unique (email);

/* Функциональный индекс по городу, используем функциональный, чтобы избежать проблем с регистром. */
create index idx_consumer_city 
on consumer(upper(city));

/* Функциональный индекс по ФИО, используем функциональный, чтобы избежать проблем с регистром. */
create index idx_consumer_display
on consumer(upper(display));

/* CHECK по полю BIRTH_DAY (дата рождения) 
   Покупки может совершать лицо достигшее совершенолетия */
alter table consumer
add constraint check_consumer_birth_date
check((ROUND(TO_NUMBER((TRUNC(sysdate)- birth_date))/365)) >= 18);

/* CHECK по полю PHONE (номер телефона), 
   номер телефона должен быть определенного формата: без букв и запрещенных символов. */
-- регулярка
alter table consumer 
add constraint check_consumer_phone
check(REGEXP_SUBSTR (REGEXP_REPLACE (phone,'^((8|\+7)[\- ]?)?(\(?\d{3}\)?[\- ]?)?[\d\- ]{7,10}$')));

/* CHECK по EMAIL (электронный адрес), электронный ящик должен быть определенного формата. */
-- регулярка
alter table consumer 
constraint check_consumer_email
check(REGEXP_SUBSTR (REGEXP_REPLACE (email,'/^\S+@\S+\.\S+$/')));

/* CHECK по CITY, без лишних символов. */
-- регулярка
alter table consumer 
constraint check_consumer_city
check(REGEXP_SUBSTR (REGEXP_REPLACE (city,'^([a-zA-Z\u0080-\u024F]+(?:. |-| |))*[a-zA-Z\u0080-\u024F]*$')));
/* ==================================================== */





/* ==================================================== */
/* Таблица Покупки: */
/* ==================================================== */
create table transaction(
id     		 INTEGER,
customer_id  INTEGER,
order_status NUMBER(1),
order_date   DATE,
store_id     INTEGER 
);

-- Первичный ключ(PK):
alter table transaction
add constraint pk_transaction primary key (id);

-- Внешний ключ(FK):
alter table transaction
  add constraint fk_consumer foreign key (customer_id)
  references consumer(id);

-- Внешний ключ(FK):  
alter table transaction
  add constraint fk_shop foreign key (store_id)
  references shop(id);

-- Индекс по FK(покупатель) + order_date(дата покупки)
create index idx_transaction_cus_ordate
on transaction(customer_id, trunc(order_date));

-- Индекс по FK(магазин) + order_date(дата покупки)
create index idx_transaction_st_ordate
on transaction(store_id, trunc(order_date));

/* CHECK по ORDER_STATUS: статус 0 или 1 */
alter table transaction 
constraint check_transaction_status 
check(order_status in (0,1));
/* ==================================================== */




/* ==================================================== */
/* Таблица Магазин: */
/* ==================================================== */
create table shop(
id     		 INTEGER 	  not null,
store_name   VARCHAR(150) not null,
phone        VARCHAR(35)  not null,
email        VARCHAR(100) not null,
street       VARCHAR(100) not null,
city         VARCHAR(100) not null
);

-- Первичный ключ(PK):
alter table shop
add constraint pk_shop primary key (id);

-- Функциональный составной индекс: Название магазина + название города
create index idx_shop_store_city
on shop(upper(store_name), upper(city));

-- Функциональный составной индекс: Название магазина + название улицы
create index idx_shop_store_street
on shop(upper(store_name), upper(street));

-- Функциональный составной индекс: Название магазина, название города, название улицы
create index idx_shop_stname_city_street
on shop(upper(store_name), upper(city), upper(street));

-- Индекс по названию магазина: часто будет использоваться при обращении к данным.
create index idx_shop_stname
on shop(upper(store_name));

-- Индекс по названию улицы: часто будет использоваться при обращении к данным.
create index idx_shop_city
on shop(upper(city));

-- Уникальное ограничение по номеру телефона: (телефон не должен повторяться)
alter table shop
add constraint u_phone unique (phone);

-- Уникальное ограничение по электронной почте: (электронный ящик не должен повторяться)
alter table shop
add constraint u_email unique (email);
/* ==================================================== */




/* ==================================================== */
/* Таблица Купленный товар: */
/* ==================================================== */
create table  purchgoods(
order_id      INTEGER not null,
item_id       INTEGER not null,
product_id    INTEGER,
quantity      INTEGER not null,
list_price    FLOAT   not null,
discount      INTEGER
);

-- Уникальный индекс ID товара.
alter table purchgoods
add constraint u_order_item_id unique (order_id, item_id);

-- Внешний ключ(FK):  
alter table purchgoods
  add constraint fk_product foreign key (product_id)
  references product(id);
  
-- Индекс по FK + discount(скидка)
create index idx_purchgoods_prod_disc
on purchgoods(product_id, discount);

-- Индекс по FK + list_price(стоимость)
create index idx_purchgoods_prod_lp
on purchgoods(product_id, list_price);

-- Индекс по FK + list_price(кол-во товара)
create index idx_purchgoods_prod_quan
on purchgoods(product_id, quantity);

-- CHECK: количество товара не может быть отрицательным
alter table purchgoods 
constraint check_purchgoods_quant 
check(quantity >= 0);
/* ======================================== */



/* ======================================== */
/* Таблица Товары: */
/* ======================================== */
create table product(
id   		 INTEGER 	  not null,
product_name VARCHAR(100) not null,
category_id  INTEGER	  not null,
list_price   FLOAT 		  not null,
part_id      INTEGER	  not null
);

-- Первичный ключ(PK):
alter table product
add constraint pk_product primary key (id);

-- FK от таблицы CATEGORY:
alter table product
  add constraint fk_category foreign key (category_id)
  references category (id);

-- FK от таблицы SHIPMENT:
alter table product
  add constraint fk_shipment foreign key (part_id)
  references shipment (id);
  
-- Функциональный индекс по названию, чтобы не было проблем с регистром:
create index idx_product_prodname
on product(upper(product_name));

-- Функциональный индекс по названию + цена продукта:
create index idx_product_prodname_lp
on product(upper(product_name), list_price);
/* ======================================== */




/* ======================================== */
/* Таблица Категория товара: */
/* ======================================== */
create table category(
id 			  INTEGER 	   not null
category_name VARCHAR(100) not null
);

-- Первичный ключ(PK):
alter table category
add constraint pk_category primary key (id);

-- Индекс по названию категории, при условии: что будет их много.
create index idx_category_catname
on category(upper(category_name));
/* ======================================== */




/* ======================================== */
/* Таблица Склад: */
/* ======================================== */
create table warehouse(
store_id     INTEGER not null,
product_id   INTEGER not null,
quantity     INTEGER not null,
rec_date     DATE 	 default sysdate
);

-- Уникальное ограничение по ID магазина и ID продукта, для уникальности строки
alter table warehouse
add constraint u_store_prod_date unique (store_id, product_id, rec_date);

-- FK от таблицы RLZ_PRODUCT
alter table warehouse
  add constraint fk_product foreign key (product_id)
  references product (id);

-- FK от таблицы CON_SHOP
alter table warehouse
  add constraint fk_shop foreign key (shop_id)
  references shop (id);

-- CHECK: количество товара не может быть отрицательным
alter table warehouse 
constraint check_warehouse_quant  
check(quantity >= 0);
/* ======================================== */




/* ======================================== */
/* Таблица Производитель: */
/* ======================================== */
create table manufacturer(
id   		  INTEGER 	   not null, 
producer_name VARCHAR(150) not null
);

-- Первичный ключ(PK):
alter table manufacturer
add constraint pk_manufacturer primary key (id);

-- Обычный индекс по названию производителя
create index idx_manufacturer_prodname
on manufacturer(upper(producer_name));
/* ======================================== */




/* ======================================== */
/* Таблица Поставщики: */
/* ======================================== */
create table vendor(
id 			INTEGER      not null,
vendor_name VARCHAR(150) not null,
producer_id INTEGER
);

-- Первичный ключ(PK):
alter table vendor
add constraint pk_vendor primary key (id);

-- FK от таблицы PUR_MANUFACTURER
alter table vendor
  add constraint fk_manufacturer foreign key (producer_id)
  references manufacturer (id);
  
-- Обычный индекс по названию поставщика 
create index idx_vendor_vendname
on vendor(upper(vendor_name));
/* ======================================== */




/* ======================================== */
/* Таблица Партия товара: */
/* ======================================== */
create table shipment(
id       	  INTEGER not null,
part_date     DATE 	  not null,
part_quantity INTEGER not null,
buy_price     FLOAT   not null,
prod_sum      FLOAT   not null,
vendor_id     INTEGER 
);

-- Первичный ключ(PK):
alter table shipment
add constraint pk_shipment primary key (part_id);

-- FK от таблицы PUR_SHIPMENT
alter table shipment
  add constraint fk_vendor foreign key (vendor_id)
  references vendor (id);

-- Составной индекс по ID поставщика и дате:
create index idx_shipment_vendor_date
on shipment(vendor_id, trunc(part_date));

-- Составной индекс по ID поставщика, ID партии и дате:
create index idx_shipment_vendor_part_date
on shipment(vendor_id, part_id, trunc(part_date));

-- Составной индекс по ID партии, кол-во коробок в партии и дате:
create index idx_shipment_part_quant_date
on shipment(part_id, part_quantity, trunc(part_date));

-- CHECK: Сумма закупки поставщика не может быть отрицательной
alter table shipment 
constraint check_shipment_price
check(buy_price >= 0);

-- CHECK: Сумма продажи магазинам не может быть отрицательной
alter table shipment 
constraint check_shipment_sum
check(prod_sum >= 0);
