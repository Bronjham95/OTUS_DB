# Homework #3. DDL.

### 1. Создание БД.

_Откроем терминал __linux__, cоздадим дирректорию для дальнейшего использования в __tablespace__._

```bash
\sudo mkdir /home/postgres/ts_store
```
_Расшарим права на созданную дирректорию пользователю Postgres (мне потребовалось воспользоваться __chown__). Сменил владельца дирректории __varefyev__ на __postgres__, чтобы получилось создать __tablespace__._

> Без смены владельца дирректории создание __tablespace__ падало с ошибкой о том, что недостаточно прав.

_Далее, потребуется войти под пользователем postgres в psql._

```bash
sudo -i -u postgres
psql
```
_Создадим tablespace:_

```bash
CREATE TABLESPACE ts LOCATION '/home/postgres/ts_dir';
```

_Далее, создадим БД и свяжем с созданным tablespace:_

```bash
CREATE DATABASE store TABLESPACE ts;
```
### 2. Табличное простарснтво и роли.
> __Табличное простарнство было создано в п.1.__

_В рамках д/з создам два пользователя "админ" и "покупатель"._

```sql
CREATE USER admin    WITH PASSWORD '¯\_(ツ)_/¯';
CREATE USER customer WITH PASSWORD '¯\_(ツ)_/¯';
```

_Дадим пользователю admin права на все действия с БД, а пользователю customer права только на чтение БД._

```sql
-- для админа:	
GRANT ALL privileges ON DATABASE store to admin;

-- для пользователя:
-- ----------------
-- подключение к БД:
GRANT CONNECT ON DATABASE store TO customer;
-- далее: дадим грант на схемы и таблицы (для чтения)
```
### 3. Схемы данных.
_Создадим схемы по имеющейся БД __store__:_

```sql
-- схема для потребителей:
CREATE SCHEMA consumer;
-- схема для реализации товара:
CREATE SCHEMA supply;
-- схема для возобновления товаров:
CREATE SCHEMA purchase;
```
_Дадим пользователю consumer гранты на схемы и чтение всех таблиц в схемах._

```sql
-- потребители:
GRANT USAGE ON SCHEMA consumer TO customer;
GRANT SELECT ON ALL TABLES IN SCHEMA consumer TO customer;

-- реализация:
GRANT USAGE ON SCHEMA supply   TO customer;
GRANT SELECT ON ALL TABLES IN SCHEMA supply TO customer;

-- возобновление:
GRANT USAGE ON SCHEMA purchase TO customer;
GRANT SELECT ON ALL TABLES IN SCHEMA purchase TO customer;
```
### 4. Распределение таблиц проекта по схемам и пространствам.

> В схему __consumer__ пойдут следующие таблицы:

* customer
* sales_item
* store
* user_transaction
----
```sql
-- CUSTOMER
CREATE TABLE consumer.customer (
	id int4 NOT NULL,
	first_name varchar(100) NOT NULL,
	last_name varchar(100) NOT NULL,
	second_name varchar(100) NULL,
	alias varchar(300) NOT NULL,
	phone varchar(35) NOT NULL,
	email varchar(100) NOT NULL,
	city varchar(100) NOT NULL,
	is_company numeric(1) NULL,
	CONSTRAINT pk_customer PRIMARY KEY (id),
	CONSTRAINT u_email UNIQUE (email),
	CONSTRAINT u_phone UNIQUE (phone)
);
CREATE INDEX idx_customer_city ON consumer.customer USING btree (upper((city)::text));
CREATE INDEX idx_customer_display ON consumer.customer USING btree (upper((alias)::text));

-- SALES_ITEM
CREATE TABLE consumer.sales_item (
	id int4 NOT NULL,
	order_id int4 NOT NULL,
	item_id int4 NOT NULL,
	product_id int4 NULL,
	quantity int4 NOT NULL,
	list_price float8 NOT NULL,
	discount int4 NULL,
	CONSTRAINT check_sales_item_quant CHECK ((quantity >= 0)),
	CONSTRAINT pk_sales_item PRIMARY KEY (id),
	CONSTRAINT u_order_item_id UNIQUE (order_id, item_id)
);
CREATE INDEX idx_sales_item_prod_disc ON consumer.sales_item USING btree (product_id, discount);
CREATE INDEX idx_sales_item_prod_lp ON consumer.sales_item USING btree (product_id, list_price);
CREATE INDEX idx_sales_item_prod_quan ON consumer.sales_item USING btree (product_id, quantity);

ALTER TABLE consumer.sales_item ADD CONSTRAINT fk_sales_item FOREIGN KEY (product_id) REFERENCES supply.product(id);

-- STORE
CREATE TABLE consumer.store (
	id int4 NOT NULL,
	store_name varchar(150) NOT NULL,
	phone varchar(35) NOT NULL,
	email varchar(100) NOT NULL,
	street varchar(100) NOT NULL,
	city varchar(100) NOT NULL,
	warehouse_id int4 NOT NULL,
	CONSTRAINT pk_store PRIMARY KEY (id),
	CONSTRAINT u_storeemail UNIQUE (email),
	CONSTRAINT u_storephone UNIQUE (phone)
);
CREATE INDEX idx_store_city ON consumer.store USING btree (upper((city)::text));
CREATE INDEX idx_store_stname ON consumer.store USING btree (upper((store_name)::text));
CREATE INDEX idx_store_stname_city_street ON consumer.store USING btree (upper((store_name)::text), upper((city)::text), upper((street)::text));
CREATE INDEX idx_store_store_city ON consumer.store USING btree (upper((store_name)::text), upper((city)::text));
CREATE INDEX idx_store_store_street ON consumer.store USING btree (upper((store_name)::text), upper((street)::text));

ALTER TABLE consumer.store ADD CONSTRAINT fk_whstore FOREIGN KEY (warehouse_id) REFERENCES supply.warehouse(id);

-- USER_TRANSATCTION
CREATE TABLE consumer.user_transaction (
	id int4 NOT NULL,
	customer_id int4 NULL,
	order_status numeric(1) NULL,
	order_date date NULL,
	store_id int4 NULL,
	CONSTRAINT check_transaction_status CHECK ((order_status = ANY (ARRAY[(0)::numeric, (1)::numeric]))),
	CONSTRAINT pk_transaction PRIMARY KEY (id)
);

ALTER TABLE consumer.user_transaction ADD CONSTRAINT fk_customer FOREIGN KEY (customer_id) REFERENCES consumer.customer(id);
ALTER TABLE consumer.user_transaction ADD CONSTRAINT fk_store FOREIGN KEY (store_id) REFERENCES consumer.store(id);

```
---

> В схему __supply__ пойдут следующие таблицы:

* category
* product
* warehouse
---
```sql
-- CATEGORY
CREATE TABLE supply.category (
	id int4 NOT NULL,
	category_name varchar(100) NOT NULL,
	CONSTRAINT pk_category PRIMARY KEY (id)
);
CREATE INDEX idx_category_catname ON supply.category USING btree (upper((category_name)::text));

-- PRODUCT
CREATE TABLE supply.product (
	id int4 NOT NULL,
	product_name varchar(100) NOT NULL,
	category_id int4 NOT NULL,
	list_price float8 NOT NULL,
	part_id int4 NOT NULL,
	CONSTRAINT pk_product PRIMARY KEY (id)
);
CREATE INDEX idx_product_prodname ON supply.product USING btree (upper((product_name)::text));
CREATE INDEX idx_product_prodname_lp ON supply.product USING btree (upper((product_name)::text), list_price);

ALTER TABLE supply.product ADD CONSTRAINT fk_category FOREIGN KEY (category_id) REFERENCES supply.category(id);
ALTER TABLE supply.product ADD CONSTRAINT fk_shipment FOREIGN KEY (part_id) REFERENCES purchase.shipment(id);

-- WAREHOUSE
CREATE TABLE supply.warehouse (
	id int4 NOT NULL,
	product_id int4 NOT NULL,
	quantity int4 NOT NULL,
	city varchar(100) NULL,
	address varchar(100) NULL,
	arr_date date NOT NULL,
	rec_date date NOT NULL,
	CONSTRAINT check_warehouse_quant CHECK ((quantity >= 0)),
	CONSTRAINT pk_warehouse PRIMARY KEY (id)
);

ALTER TABLE supply.warehouse ADD CONSTRAINT fk_warehouse FOREIGN KEY (product_id) REFERENCES supply.product(id);

```
---
> В схему __purchase__ пойдут следующие таблицы:

* manufacturer
* shipment 
* vendor 

```sql
-- MANUFACTURER
CREATE TABLE purchase.manufacturer (
	id int4 NOT NULL,
	producer_name varchar(150) NOT NULL,
	CONSTRAINT pk_manufacturer PRIMARY KEY (id)
);
CREATE INDEX idx_manufacturer_prodname ON purchase.manufacturer USING btree (upper((producer_name)::text));

-- SHIPMENT
CREATE TABLE purchase.shipment (
	id int4 NOT NULL,
	part_date date NOT NULL,
	part_quantity int4 NOT NULL,
	buy_price float8 NOT NULL,
	prod_sum float8 NOT NULL,
	vendor_id int4 NULL,
	CONSTRAINT check_shipment_price CHECK ((buy_price >= (0)::double precision)),
	CONSTRAINT check_shipment_sum CHECK ((prod_sum >= (0)::double precision)),
	CONSTRAINT pk_shipment PRIMARY KEY (id)
);

ALTER TABLE purchase.shipment ADD CONSTRAINT fk_vendor FOREIGN KEY (vendor_id) REFERENCES purchase.vendor(id);

-- VENDOR
CREATE TABLE purchase.vendor (
	id int4 NOT NULL,
	vendor_name varchar(150) NOT NULL,
	producer_id int4 NULL,
	CONSTRAINT pk_vendor PRIMARY KEY (id)
);
CREATE INDEX idx_vendor_vendname ON purchase.vendor USING btree (upper((vendor_name)::text));

ALTER TABLE purchase.vendor ADD CONSTRAINT fk_manufacturer FOREIGN KEY (producer_id) REFERENCES purchase.manufacturer(id);

```
### _Выполнено:_

1. Создана база данных.
2. Создано табличное пространство и роли.
3. Созданы схемы данных.
4. Таблицы проекта распределены по схемам и табличному пространству.
