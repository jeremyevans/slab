require 'bcrypt'
require 'securerandom'

Sequel.migration do
  up do
    create_table(:accounts) do
      primary_key :id
      String :email, :null=>false
      String :password_hash, :null=>false
      String :token, :null=>false

      constraint :valid_email, :email=>/^[^,;@ \r\n]+@[^,@; \r\n]+\.[^,@; \r\n]+$/
      index :email, :unique=>true
    end

    alter_table(:documents) do
      add_foreign_key :account_id, :accounts
    end

    from(:accounts).insert(:email=>'slab@example.com', :password_hash=>BCrypt::Password.create('slab'), :token=>SecureRandom.hex(20))
    from(:documents).update(:account_id=>1)

    alter_table(:documents) do
      set_column_not_null :account_id
    end
  end
  
  down do
    alter_table(:documents) do
      drop_column :account_id
    end
    
    drop_table(:accounts)
  end
end
