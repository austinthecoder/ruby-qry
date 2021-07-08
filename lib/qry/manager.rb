Sequel.extension :migration

module Qry
  Manager = Ivo.new(:qry, :migrations_path, :schema_path, :host_whitelist) do
    def current_version?
      Sequel::Migrator.is_current?(qry.sequel_db, migrations_path)
    end

    def load_schema
      ensure_valid_host

      File.read(schema_path).split(';').map(&:strip).reject(&:empty?).each do |sql|
        qry.run(sql)
      end
    end

    def migrate(version: nil)
      version = Integer(version) if version

      if version
        puts "Migrating to version #{version}"
        Sequel::Migrator.run(qry.sequel_db, migrations_path, target: version)
      else
        puts "Migrating to latest"
        Sequel::Migrator.run(qry.sequel_db, migrations_path)
      end

      dump_schema
    end

    def drop_all_tables
      ensure_valid_host

      fetch_table_names.each do |table_name|
        qry.run('drop table ?', Sequel.identifier(table_name))
      end
    end

    private

    def ensure_valid_host
      unless host_whitelist.include?(qry.host)
        raise "Host must be one of: #{host_whitelist.join(', ')}"
      end
    end

    def fetch_table_names
      sql = <<~SQL
        select t.table_name as table_name
        from information_schema.tables t
        where t.table_schema = ?
      SQL

      qry.fetch(sql, qry.name).map(&:table_name)
    end

    def dump_schema
      sqls = fetch_table_names.map do |table_name|
        create_table_sql = qry
          .fetch('show create table ?', Sequel.identifier(table_name))
          .map { |row| row.public_send('Create Table') }[0]
        create_table_sql_without_auto_increment = create_table_sql.gsub(/AUTO_INCREMENT=\d+\s/, '')
        "#{create_table_sql_without_auto_increment};"
      end

      schema_info = qry.fetch('select si.version from schema_info si limit 1')[0]

      sqls << "insert into schema_info (version) values (#{schema_info.version});"

      schema_sql = "#{sqls.join "\n\n"}\n"

      File.open(schema_path, 'w') do |file|
        file.write(schema_sql)
      end
    end
  end
end
