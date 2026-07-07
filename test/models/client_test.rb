require "test_helper"

# 各テストの No は docs/テストパターン.md の表と対応している。
class ClientTest < ActiveSupport::TestCase
  # No.11 バリデーション（異常系: 名前必須）
  test "名前がないと登録できない" do
    assert_not Client.new(name: "").valid?
  end

  # No.12 バリデーション（異常系: メール形式・空は許可）
  test "メールアドレスは形式チェックされ空欄は許可される" do
    assert Client.new(name: "テスト商事", email: "").valid?
    assert Client.new(name: "テスト商事", email: "info@example.com").valid?
    assert_not Client.new(name: "テスト商事", email: "不正なメール").valid?
  end

  # No.13 削除防止（状態: 請求書が紐づく顧客は削除できない）
  test "請求書が紐づく顧客は削除できない" do
    client = Client.create!(name: "テスト商事")
    Invoice.create!(
      client: client,
      issue_date: Date.current,
      due_date: Date.current + 30,
      tax_rate: 10,
      invoice_items_attributes: [ { description: "作業A", quantity: 1, unit_price: 1000 } ]
    )
    assert_not client.destroy
    assert client.errors.present?
    assert Client.exists?(client.id)
  end

  # No.14 削除（正常系: 請求書がなければ削除できる）
  test "請求書が紐づかない顧客は削除できる" do
    client = Client.create!(name: "削除できる商事")
    assert client.destroy
    assert_not Client.exists?(client.id)
  end
end
