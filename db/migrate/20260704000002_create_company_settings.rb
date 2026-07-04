class CreateCompanySettings < ActiveRecord::Migration[7.2]
  def change
    create_table :company_settings do |t|
      t.string :name, null: false
      t.string :postal_code
      t.string :address
      t.string :tel
      t.string :email
      t.string :registration_number
      t.text :bank_info

      t.timestamps
    end
  end
end
