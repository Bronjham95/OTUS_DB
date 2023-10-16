# HOMEWORK #4. DML: insert, update, delete, select.

### 1. Напишите запрос по своей базе с регулярным выражением, добавьте пояснение, что вы хотите найти.
```sql
-- Обращаемся к таблице "Покупатели", которая находится в схеме "Потребители".
select * from consumer.customer c
where c.phone ~ '^[+]' -- покупатели, у которых есть "+", т.е. мобильный телефон.
```

### 2. Напишите запрос по своей базе с использованием LEFT JOIN и INNER JOIN, как порядок соединений в FROM влияет на результат? Почему?
```sql
-- Обращаемся к таблице "Покупатели"
select * from consumer.customer c
-- Объединяем с таблицей "Транзакции(Покупки)"
join consumer.user_transaction 
ut on c.id = ut.customer_id
-- Объединяем с таблицей "Магазин"
-- "Магазин" может быть не действующий, т.е. закрыться.
--  Т.о. можно добавить флаг, который бы означал: действующий (1) или нет (0).
left join consumer.store s 		  
on (s.id = ut.store_id and ut.is_work = '1')
where c.id = '1' -- по конкретному пользователю
```
> При внутреннем объединении (JOIN) порядок не важен, когда же объединение внешнее (LEFT JOIN e.t.c), то порядок важен, т.к. будут включены все строки из таблицы на указанной стороне (это ЛЕВОЕ или ПРАВОЕ объединение), в то время как из таблицы на другой стороне будут включены только строки, соответствующие критериям объединения.

### 3.Напишите запрос на добавление данных с выводом информации о добавленных строках.
```sql
insert into consumer.customer
(id, first_name, last_name, second_name, alias, phone, email, city, is_company)
values
(1, 'Victor', 'Arephev', 'Nicolaevich', null, '+79608671275', 'xoyk@yandex.ru', 'Sochi', 0),
(2, 'Darja', 'Zorina', null, null, '+79189096010', 'pupcik@mail.ru', 'Vilnuis', 0),
(3, null, null, null, 'GreatSon', '2645088', 'greatson@yahoo.com', 'Boston', 1),
(4, null, null, null, 'Google', '2456780', 'google@gmail.com', 'New-York', 1),
(5, 'Nikolay', 'Arephev', 'Victorovich', null, '+7189032013', 'kolyan@mail.ru', 'Sochi', 0)
returning id, first_name, last_name, second_name, alias;
```

### 4. Напишите запрос с обновлением данные используя UPDATE FROM.
```sql
-- Обновим таблицу "Транзакции(Покупки)"
-- Ситуация: сбой в работе приложения, пользователь купил товар не по правильной цене и хочет сделать возврат.
update consumer.user_transaction t1
-- Проставим статус order_status = 0, "аннулируем покупку":
set order_status = '0'
-- Выберем всех пользоваталей из г.Сочи (сбой по городу):
from (select id, city from consumer.customer t2
where t2.city = 'Sochi'
) as t2
where t1.customer_id = t2.id 
-- за определенную дату:
and t1.order_date > '2023-10-12';
```

### 5. Напишите запрос для удаления данных с оператором DELETE используя join с другой таблицей с помощью using.
```sql
-- Удалить данные из таблицы "Транзакции(Покупки)"
delete from consumer.user_transaction t1
-- Испольуя таблицу "Покупатели"
using consumer.customer t2
where t2.id = t1.customer_id 
-- "Неуспешные транзакции"
and t1.order_status = 0
-- Из г.Сочи
and t2.city = 'Sochi';
```
### * Приведите пример использования утилиты COPY.
```sql
-- используя утилиту copy - скопировать все подходящие записи в csv-файл из таблицы "Покупатели", которые живут в г.Сочи
copy (select * from consumer.customer c 
where c.city = 'Sochi') 
to '/test_data/test.txt';
```
> Пришлось дать права на файл .csv, чтобы сделать выгрузку.
