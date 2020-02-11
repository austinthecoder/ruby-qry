require 'sqlite3'
require 'sequel'
require 'logger'

RSpec.describe Qry do
  before do
    sql = <<~SQL
      create table fruits (
        id integer not null primary key autoincrement,
        name varchar(255)
      )
    SQL

    @qry = Qry.connect(adapter: :sqlite)

    @qry.run(sql)

    @qry.insert_rows(:fruits, [:name], [['Banana'], ['Apple']])
  end

  describe 'VERSION' do
    it 'is formatted correctly' do
      expect(Qry::VERSION).to match(/\d+\.\d+\.\d+/)
    end
  end

  it 'fetches' do
    fruits = @qry.fetch('select * from fruits')
    expect(fruits).to eq [
      Ivo.(id: 1, name: 'Banana'),
      Ivo.(id: 2, name: 'Apple'),
    ]

    fruits = @qry.fetch('select * from fruits where name = :name', name: 'Banana')
    expect(fruits).to eq [Ivo.(id: 1, name: 'Banana')]

    fruits = @qry.fetch('select * from fruits where name = ?', 'Banana')
    expect(fruits).to eq [Ivo.(id: 1, name: 'Banana')]

    fruits = @qry.fetch('select * from fruits where name = "Banana"')
    expect(fruits).to eq [Ivo.(id: 1, name: 'Banana')]

    fruits = @qry.fetch('select * from fruits where name in ?', ['Apple'])
    expect(fruits).to eq [Ivo.(id: 2, name: 'Apple')]
  end

  it 'inserts' do
    last_id = @qry.insert('insert into fruits (name) values (?), (?)', 'Strawberry', 'Orange')
    expect(last_id).to eq 4

    fruits = @qry.fetch('select * from fruits')
    expect(fruits).to eq rows = [
      Ivo.(id: 1, name: 'Banana'),
      Ivo.(id: 2, name: 'Apple'),
      Ivo.(id: 3, name: 'Strawberry'),
      Ivo.(id: 4, name: 'Orange'),
    ]
  end

  it 'updates' do
    rows_affected = @qry.update('update fruits set name = ? where id = ?', 'Mango', 2)
    expect(rows_affected).to eq 1

    fruits = @qry.fetch('select * from fruits')
    expect(fruits).to eq [
      Ivo.(id: 1, name: 'Banana'),
      Ivo.(id: 2, name: 'Mango'),
    ]
  end

  it 'deletes' do
    rows_affected = @qry.delete('delete from fruits where id = ?', 2)
    expect(rows_affected).to eq 1

    fruits = @qry.fetch('select * from fruits')
    expect(fruits).to eq [
      Ivo.(id: 1, name: 'Banana'),
    ]
  end

  it 'uses transactions' do
    begin
      @qry.transaction do
        @qry.insert('insert into fruits (name) values (?)', 'Strawberry')
        @qry.insert('insert into fruits (name) values (?)', 'Mango')
        raise
      end
    rescue
    end

    fruits = @qry.fetch('select * from fruits')
    expect(fruits).to eq [
      Ivo.(id: 1, name: 'Banana'),
      Ivo.(id: 2, name: 'Apple'),
    ]
  end

  it 'runs any query' do
    @qry.run('create table tmp (name varchar(255))')
    @qry.run('insert into tmp (name) values ("Austin")')

    expect(@qry.fetch('select * from tmp')).to eq [
      Ivo.(name: 'Austin'),
    ]

    @qry.run('drop table tmp')
  end

  it 'disconnects' do
    @qry.disconnect
    expect { @qry.fetch('select * from fruits') }.to raise_error Sequel::DatabaseError
  end

  it "updates rows" do
    @qry.update_rows(:fruits, {name: "Mango"}, name: "Banana")
    @qry.update_rows(:fruits, {name: "Strawberry"}, id: 2)

    fruits = @qry.fetch('select * from fruits')

    expect(fruits).to eq [
      Ivo.(id: 1, name: 'Mango'),
      Ivo.(id: 2, name: 'Strawberry'),
    ]
  end
end
