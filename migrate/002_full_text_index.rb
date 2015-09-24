Sequel.migration do
  up do
    alter_table(:documents) do
      add_full_text_index :text, :name=>'txt_idx'
    end
  end
  
  down do
    alter_table(:documents) do
      drop_index :text, :name=>'txt_idx'
    end
  end
end
