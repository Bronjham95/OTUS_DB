/* ==================================================== */

/* Таблица Покупатели: */
create table CON_CONSUMER(
customer_id INTEGER not null,
first_name  VARCHAR(100 CHAR) not null,
last_name   VARCHAR(100 CHAR) not null,
second_name VARCHAR(100 CHAR), -- может отсутствовать: например, иностранный гражданин
display     VARCHAR(300 CHAR) not null,
birth_date  DATE not null,
phone       VARCHAR(35  CHAR) not null,
email       VARCHAR(100 CHAR) not null,
city        VARCHAR(100 CHAR) not null 
);

-- Первичный ключ(PK)
alter table CON_CONSUMER
add constraint PK_CON_CONSUMER primary key (CUSTOMER_ID);

-- Уникальный индекс по номеру телефона: (телефон не должен повторяться)
ALTER TABLE CON_CONSUMER
ADD CONSTRAINT U_PHONE UNIQUE (phone);

-- Уникальный индекс по электронной почте: (электронный ящик не должен повторяться)
ALTER TABLE CON_CONSUMER
ADD CONSTRAINT U_EMAIL UNIQUE (email);

/* Функциональный индекс по городу, используем функциональный, чтобы избежать проблем с регистром. */
create index IDX_CON_CONSUMER_CITY 
on CON_CONSUMER(UPPER(CITY));

/* Функциональный индекс по ФИО, используем функциональный, чтобы избежать проблем с регистром. */
create index IDX_CON_CONSUMER_DISPLAY
on CON_CONSUMER(UPPER(DISPLAY));

/* CHECK по полю BIRTH_DAY (дата рождения) 
   Покупки может совершать лицо достигшее совершенолетия */
alter table CON_CONSUMER
add constraint CHECK_CON_CONSUMER_BIRTH_DAY
check((ROUND(TO_NUMBER((TRUNC(SYSDATE)- BIRTH_DATE))/365)) >= 18);

/* CHECK по полю PHONE (номер телефона), 
   номер телефона должен быть определенного формата: без букв и запрещенных символов. */
-- регулярка
alter table CON_CONSUMER 
add constraint CHECK_CON_CONSUMER_PHONE 
check(REGEXP_SUBSTR (REGEXP_REPLACE (PHONE,'^((8|\+7)[\- ]?)?(\(?\d{3}\)?[\- ]?)?[\d\- ]{7,10}$')));

/* CHECK по EMAIL (электронный адрес), электронный ящик должен быть определенного формата. */
-- регулярка
alter table CON_CONSUMER 
constraint CHECK_CON_CONSUMER_EMAIL 
check(REGEXP_SUBSTR (REGEXP_REPLACE (EMAIL,'/^\S+@\S+\.\S+$/')));

/* CHECK по CITY, без лишних символов. */
-- регулярка
alter table CON_CONSUMER 
constraint CHECK_CON_CONSUMER_CITY
check(REGEXP_SUBSTR (REGEXP_REPLACE (CITY,'^([a-zA-Z\u0080-\u024F]+(?:. |-| |))*[a-zA-Z\u0080-\u024F]*$')));
/* ==================================================== */

/* ==================================================== */
/* Таблица Покупки: */
create table CON_TRANSACTION(
order_id     INTEGER,
customer_id  INTEGER,
order_status NUMBER(1),
order_date   DATE,
store_id     INTEGER 
);

-- Первичный ключ(PK):
alter table CON_TRANSACTION
add constraint PK_CON_TRANSACTION primary key (ORDER_ID);

-- Внешний ключ(FK):
alter table CON_TRANSACTION
  add constraint FK_CUSTOMER_TRANS foreign key (CUSTOMER_ID)
  references CON_CONSUMER (CUSTOMER_ID);

-- Внешний ключ(FK):  
alter table CON_TRANSACTION
  add constraint FK_SHOP_TRAN foreign key (store_id)
  references CON_SHOP (store_id);

-- Индекс по FK(покупатель) + order_date(дата покупки)
create index IDX_CON_TRANSACTION_CUS_DATE
on CON_TRANSACTION(customer_id, trunc(order_date));

-- Индекс по FK(магазин) + order_date(дата покупки)
create index IDX_CON_TRANSACTION_DISPLAY
on CON_TRANSACTION(store_id, trunc(order_date));

-- Индекс по FK(покупатель) + order_status(0/1 - не успешно/успешно)
create index IDX_CON_TRANSACTION_DISPLAY
on CON_TRANSACTION(customer_id, order_status);

-- Индекс по FK(магазин) + order_status(0/1 - не успешно/успешно)
create index IDX_CON_TRANSACTION_DISPLAY
on CON_TRANSACTION(store_id, order_status);

/* CHECK по ORDER_STATUS: статус 0 или 1 */
alter table CON_TRANSACTION 
constraint CHECK_CON_TRAN_STATUS 
check(ORDER_STATUS 0 between 1);
/* ==================================================== */

/* ==================================================== */

/* Таблица Магазин: */
create table CON_SHOP(
store_id     INTEGER not null,
store_name   VARCHAR(150 CHAR) not null,
phone        VARCHAR(35  CHAR) not null,
email        VARCHAR(100 CHAR) not null,
street       VARCHAR(100 CHAR) not null,
city         VARCHAR(100 CHAR) not null
);

-- Первичный ключ(PK):
alter table CON_SHOP
add constraint PK_CON_SHOP primary key (STORE_ID);

-- Функциональный составной индекс: Название магазина + название города
create index IDX_CON_TRANS_STORE_CITY
on CON_SHOP(UPPER(store_name), UPPER(city));

-- Функциональный составной индекс: Название магазина + название улицы
create index IDX_CON_TRANS_STORE_STREET
on CON_SHOP(UPPER(store_name), UPPER(street));

-- Функциональный составной индекс: Название магазина, название города, название улицы
create index IDX_CON_TRANS_ST_CIT_STR
on CON_SHOP(UPPER(STORE_NAME), UPPER(CITY), UPPER(STREET));

-- Индекс по названию магазина: часто будет использоваться при обращении к данным.
create index IDX_CON_TRANS_STORE_NAME
on CON_SHOP(UPPER(STORE_NAME));

-- Индекс по названию улицы: часто будет использоваться при обращении к данным.
create index IDX_CON_TRANS_STREET
on CON_SHOP(UPPER(STREET));

-- Индекс по названию улицы: часто будет использоваться при обращении к данным.
create index IDX_CON_TRANS_CITY
on CON_SHOP(UPPER(CITY));

-- Уникальный индекс по номеру телефона: (телефон не должен повторяться)
ALTER TABLE CON_SHOP
ADD CONSTRAINT U_PHONE UNIQUE (phone);

-- Уникальный индекс по электронной почте: (электронный ящик не должен повторяться)
ALTER TABLE CON_SHOP
ADD CONSTRAINT U_EMAIL UNIQUE (email);
/* ==================================================== */

/* ==================================================== */

/* Таблица Купленный товар: */
create table  CON_PURCHGOODS(
order_id      INTEGER not null,
item_id       INTEGER not null,
product_id    INTEGER,
quantity      INTEGER not null,
list_price    FLOAT not null,
discount      INTEGER
);

-- Первичный ключ(PK):
alter table CON_PURCHGOODS
add constraint PK_CON_SHOP primary key (ORDER_ID);

-- Уникальный индекс ID товара.
ALTER TABLE CON_PURCHGOODS
ADD CONSTRAINT U_ITEM_ID UNIQUE (ITEM_ID);

-- Внешний ключ(FK):  
alter table CON_PURCHGOODS
  add constraint FK_SHOP_TRAN foreign key (PRODUCT_ID)
  references RLZ_PRODUCT (PRODUCT_ID);
  
-- Индекс по FK + discount(скидка)
create index IDX_CON_PURCH_PROD_DIS
on CON_PURCHGOODS(PRODUCT_ID, DISCOUNT);

-- Индекс по FK + list_price(стоимость)
create index IDX_CON_PURCH_PROD_LP
on CON_PURCHGOODS(PRODUCT_ID, LIST_PRICE);

-- Индекс по FK + list_price(кол-во товара)
create index IDX_CON_PURCH_PROD_QUAN
on CON_PURCHGOODS(PRODUCT_ID, QUANTITY);

-- CHECK: количество товара не может быть отрицательным
alter table CON_PURCHGOODS 
constraint CHECK_CON_PURCHGOODS_QUANT 
check(quantity >= 0);

/* ======================================== */

/* Таблица Товары: */
create table RLZ_PRODUCT(
product_id   INTEGER not null,
product_name VARCHAR(100 CHAR) not null,
category_id  INTEGER,
list_price   FLOAT not null,
part_id      INTEGER
);

-- Первичный ключ(PK):
alter table RLZ_PRODUCT
add constraint PK_RLZ_PRODUCT primary key (PRODUCT_ID);

-- FK от таблицы CON_SHOP:
alter table RLZ_PRODUCT
  add constraint FK_RLZ_PRODUCT_PART foreign key (part_id)
  references PUR_SHIPMENT (part_id);
  
-- Функциональный индекс по названию, чтобы не было проблем с регистром:
create index IDX_RLZ_PRODUCT_PROD
on RLZ_PRODUCT(UPPER(PRODUCT_NAME));

-- Функциональный индекс по названию + цена продукта:
create index IDX_RLZ_PRODUCT_PROD_LIST
on RLZ_PRODUCT(UPPER(PRODUCT_NAME), LIST_PRICE);
/* ======================================== */

/* ======================================== */

/* Таблица Категория товара: */
create table RLZ_CATEGORY(
category_id not null
category_name not null
);

-- Первичный ключ(PK):
alter table RLZ_CATEGORY
add constraint PK_RLZ_CATEGORY primary key (CATEGORY_ID);

-- Индекс по названию категории, при условии: что будет их много.
create index IDX_RLZ_CATEGORY_CATEGORY_NAME
on RLZ_CATEGORY(CATEGORY_NAME);
/* ======================================== */

/* ======================================== */

/* Таблица Склад: */
create table RLZ_WAREHOUSE(
store_id     INTEGER not null,
product_id   INTEGER not null,
quantity     INTEGER not null,
rec_date     DATE default sysdate
);

-- Уникальный индекс по ID магазина и ID продукта, для уникальности строки
ALTER TABLE RLZ_WAREHOUSE
ADD CONSTRAINT U_STORE_PRODUCT_DATE UNIQUE (STORE_ID, PRODUCT_ID, rec_date);

-- FK от таблицы RLZ_PRODUCT
alter table RLZ_WAREHOUSE
  add constraint FK_RLZ_WAREHOUSE_STOR foreign key (store_id)
  references RLZ_PRODUCT (store_id);

-- FK от таблицы CON_SHOP
alter table RLZ_WAREHOUSE
  add constraint FK_RLZ_WAREHOUSE_PROD foreign key (product_id)
  references CON_SHOP (product_id);

-- CHECK: количество товара не может быть отрицательным
alter table RLZ_WAREHOUSE 
constraint CHECK_RLZ_WAREHOUSE_QUANT 
check(quantity >= 0);
/* ======================================== */

/* ======================================== */

/* Таблица Производитель: */
create table PUR_PRODUCER(
producer_id   INTEGER not null, 
producer_name VARCHAR(150 CHAR) not null
);

-- Первичный ключ(PK):
alter table PUR_PRODUCER
add constraint PK_PUR_PRODUCER primary key (producer_id);

-- Обычный индекс по названию производителя
create index IDX_PUR_PRODUCER_PROD_NAME
on PUR_PRODUCER(UPPER(producer_name));
/* ======================================== */

/* ======================================== */

/* Таблица Поставщики: */
create table PUR_VENDOR(
vendor_id INTEGER not null,
vendor_name VARCHAR(150 CHAR) not null,
producer_id INTEGER
);

-- Первичный ключ(PK):
alter table PUR_VENDOR
add constraint PK_PUR_VENDOR primary key (vendor_id);

-- Обычный индекс по названию поставщика 
create index IDX_PUR_VENDOR_VENDOR_NAME
on PUR_VENDOR(UPPER(vendor_name));
/* ======================================== */

/* ======================================== */

/* Таблица Партия товара: */
create table PUR_SHIPMENT(
part_id       INTEGER not null,
part_date     DATE not null,
part_quantity INTEGER not null,
buy_price     FLOAT not null,
prod_sum      FLOAT not null,
vendor_id     INTEGER 
);

-- Первичный ключ(PK):
alter table PUR_SHIPMENT
add constraint PK_PUR_SHIPMENT primary key (part_id);

-- Составной индекс по ID поставщика и дате:
create index IDX_PUR_SHIPMENT_VENDOR_DATE
on PUR_SHIPMENT(vendor_id, part_date);

-- Составной индекс по ID поставщика, ID партии и дате:
create index IDX_PUR_SHIPMENT_VENDOR_DATE
on PUR_SHIPMENT(vendor_id, part_id, part_date);

-- Составной индекс по ID партии, кол-во коробок в партии и дате:
create index IDX_PUR_SHIPMENT_VENDOR_DATE
on PUR_SHIPMENT(part_id, part_quantity, part_date);

-- CHECK: Сумма закупки поставщика не может быть отрицательной
alter table PUR_SHIPMENT 
constraint CHECK_PUR_SHIPMENT_PRICE
check(buy_price >= 0);

-- CHECK: Сумма продажи магазинам не может быть отрицательной
alter table PUR_SHIPMENT 
constraint CHECK_PUR_SHIPMENT_SUM
check(prod_sum >= 0);
