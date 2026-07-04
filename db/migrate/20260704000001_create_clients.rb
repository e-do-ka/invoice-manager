class CreateClients < ActiveRecord::Migration[7.2]
  def change
    create_table :clients do |t|
      t.string :name, null: false
      t.string :contact_name
      t.string :email
      t.string :postal_code
      t.string :address
      t.text :notes

      t.timestamps
    end
  end
end
