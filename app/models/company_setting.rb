# 請求書の発行者情報（自社情報）。1レコードのみ保持するシングルトン。
class CompanySetting < ApplicationRecord
  validates :name, presence: true

  def self.current
    first_or_create!(name: "自社名（設定画面で変更してください）")
  end
end
