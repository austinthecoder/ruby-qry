# Qry

## Usage

### Connect

```ruby
require 'qry'

qry = Qry.connect(...) # Same arguments as Sequel gem
```

### Run

```ruby
qry.run(<<~SQL)
  create table fruits (
    id integer not null primary key autoincrement,
    name varchar(255)
  )
SQL
```

### Insert

```ruby
qry.insert('insert into fruits (name) values (?), (?)', 'Strawberry', 'Orange')
```

### Fetch

```ruby
fruits = qry.fetch('select * from fruits')
fruits.size    # 2
fruits[0].name # Strawberry
fruits[1].name # Orange
```

### Update

```ruby
qry.update('update fruits set name = ? where id = ?', 'Mango', fruits[0].id)

fruits = qry.fetch('select * from fruits')
fruits[0].name # Mango
fruits[1].name # Orange
```

### Delete

```ruby
qry.delete('delete from fruits where id = ?', fruits[1].id)

fruits = qry.fetch('select * from fruits')
fruits.size    # 1
fruits[0].name # Mango
```
