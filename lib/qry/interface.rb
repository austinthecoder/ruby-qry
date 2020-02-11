module Qry
  Interface = Ivo.new(:sequel_db, :instrumenter) do
    extend Forwardable

    def_delegators(:sequel_db, :transaction, :disconnect, :url)

    def adapter
      sequel_db.opts[:adapter]
    end

    def user
      sequel_db.opts[:user]
    end

    def password
      sequel_db.opts[:password]
    end

    def host
      sequel_db.opts[:host]
    end

    def name
      sequel_db.opts[:database]
    end

    def fetch(sql, *binds)
      instrumenter.instrument('qry.fetch', qry: self) do
        sequel_db.fetch(sql, *binds).map { |row| Ivo.(row) }
      end
    end

    def insert(sql, *binds)
      instrumenter.instrument('qry.insert', qry: self) do
        sequel_db.fetch(sql, *binds).insert
      end
    end

    def update(sql, *binds)
      instrumenter.instrument('qry.update', qry: self) do
        sequel_db.fetch(sql, *binds).update
      end
    end

    def delete(sql, *binds)
      instrumenter.instrument('qry.delete', qry: self) do
        sequel_db.fetch(sql, *binds).delete
      end
    end

    def run(sql, *binds)
      sql = sequel_db.fetch(sql, *binds).sql unless binds.empty?

      instrumenter.instrument('qry.run', qry: self) do
        sequel_db.run(sql)
      end
    end

    def insert_row(table, data = nil, extra_sql = nil)
      data ||= {}

      columns = data.map { |column, _| Sequel.identifier(column.to_s) }
      values = data.map { |_, value| value }
      placeholders = data.map { '?' }.join(', ')

      sql = <<~SQL % {columns: placeholders, values: placeholders, extra: extra_sql}
        insert into ? (%{columns})
        values (%{values})
        %{extra}
      SQL

      if !table.is_a?(Sequel::SQL::Identifier) && !table.is_a?(Sequel::SQL::QualifiedIdentifier)
        table = Sequel.identifier(table)
      end

      insert(sql, table, *columns, *values)
    end

    def insert_rows(table, columns, values_lists, extra_sql = nil)
      return if values_lists.empty?

      columns = columns.map { |column| Sequel.identifier(column.to_s) }
      placeholders = columns.map { '?' }.join(', ')
      values = values_lists.map { "(%{placeholders})" }.join(', ') % {placeholders: placeholders}

      sql = <<~SQL % {columns: placeholders, values: values, extra: extra_sql}
        insert into ? (%{columns})
        values %{values}
        %{extra}
      SQL

      if !table.is_a?(Sequel::SQL::Identifier) && !table.is_a?(Sequel::SQL::QualifiedIdentifier)
        table = Sequel.identifier(table)
      end

      insert(sql, table, *columns, *values_lists.flatten)
    end

    def update_rows(table, updates, where)
      return if updates.empty?

      binds = [Sequel.identifier(table.to_s)]

      updates.each do |column, value|
        binds << Sequel.identifier(column.to_s) << value
      end

      where.each do |column, value|
        binds << Sequel.identifier(column.to_s) << value
      end

      sql = <<~SQL
        update ?
        set %{updates}
        where %{where}
      SQL

      sql = sql % {
        updates: updates.map { "? = ?" }.join(", "),
        where: where.map { "? = ?" }.join(" and "),
      }

      update(sql, *binds)
    end
  end
end
