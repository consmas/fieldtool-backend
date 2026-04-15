namespace :db do
  desc "Purge all application data except users"
  task purge_except_users: :environment do
    confirmation = ENV["CONFIRM"]
    expected = "PURGE_ALL_EXCEPT_USERS"

    if confirmation != expected
      abort "Refusing to run. Re-run with CONFIRM=#{expected}"
    end

    connection = ActiveRecord::Base.connection
    excluded_tables = %w[users schema_migrations ar_internal_metadata]
    tables_to_purge = connection.tables - excluded_tables

    if tables_to_purge.empty?
      puts "No tables to purge."
      next
    end

    quoted_tables = tables_to_purge.map { |table| connection.quote_table_name(table) }

    puts "Purging #{tables_to_purge.size} tables."
    puts "Preserving: #{excluded_tables.join(', ')}"

    case connection.adapter_name.downcase
    when /postgres/
      connection.execute("TRUNCATE TABLE #{quoted_tables.join(', ')} RESTART IDENTITY CASCADE")
    else
      connection.disable_referential_integrity do
        tables_to_purge.each do |table|
          connection.execute("DELETE FROM #{connection.quote_table_name(table)}")
          connection.reset_pk_sequence!(table) if connection.respond_to?(:reset_pk_sequence!)
        end
      end
    end

    puts "Database purge complete."
  end
end
