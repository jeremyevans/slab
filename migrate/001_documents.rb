Sequel.migration do
  change do
    create_table(:documents) do
      primary_key :id
      String :path, :null=>false
      File :image, :null=>false
      String :text
    end
  end
end
