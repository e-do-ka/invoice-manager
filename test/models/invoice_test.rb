require "test_helper"

# 各テストの No は docs/テストパターン.md の表と対応している。
class InvoiceTest < ActiveSupport::TestCase
  setup do
    # 時刻を固定する。固定しないと、下の build_invoice の既定の支払期限
    # （2026-07-31）を実時間が追い越した時点で「期限超過」に変わり、
    # コードを一切変えていないのに No.10 が落ちる。
    travel_to Date.new(2026, 7, 15)
    @client = Client.create!(name: "テスト商事")
  end

  def build_invoice(items: [ { description: "作業A", quantity: 2, unit_price: 1000 } ], **attrs)
    Invoice.new({
      client: @client,
      issue_date: Date.new(2026, 7, 1),
      due_date: Date.new(2026, 7, 31),
      tax_rate: 10,
      invoice_items_attributes: items
    }.merge(attrs))
  end

  # No.1 金額計算（正常系: 小計・消費税・合計）
  test "小計・消費税・合計が明細から正しく計算される" do
    invoice = build_invoice(items: [
      { description: "作業A", quantity: 2, unit_price: 1000 },
      { description: "作業B", quantity: 3, unit_price: 500 }
    ])
    assert_equal 3500, invoice.subtotal
    assert_equal 350, invoice.tax_amount
    assert_equal 3850, invoice.total_amount
  end

  # No.2 金額計算（境界値: 消費税の端数は切り捨て）
  test "消費税の端数は切り捨てられる" do
    invoice = build_invoice(items: [ { description: "作業A", quantity: 1, unit_price: 335 } ])
    # 335 × 10% = 33.5 → 33（適格請求書では税率ごとに1回の端数処理）
    assert_equal 33, invoice.tax_amount
    assert_equal 368, invoice.total_amount
  end

  # No.3 採番（正常系: INV-YYYYMM-001 形式で発行月ごとに連番）
  test "請求書番号が発行月ごとの連番で自動採番される" do
    first = build_invoice
    first.save!
    assert_equal "INV-202607-001", first.invoice_number

    second = build_invoice
    second.save!
    assert_equal "INV-202607-002", second.invoice_number
  end

  # No.4 採番（境界値: 月が変わると連番が001に戻る）
  test "発行月が変わると連番は001から始まる" do
    build_invoice.save!
    other_month = build_invoice(issue_date: Date.new(2026, 8, 1), due_date: Date.new(2026, 8, 31))
    other_month.save!
    assert_equal "INV-202608-001", other_month.invoice_number
  end

  # No.5 バリデーション（異常系: 支払期限が発行日より前）
  test "支払期限が発行日より前だと登録できない" do
    invoice = build_invoice(due_date: Date.new(2026, 6, 30))
    assert_not invoice.valid?
    assert_includes invoice.errors[:due_date], "は発行日以降の日付にしてください"
  end

  # No.6 バリデーション（異常系: 明細が0行）
  test "明細が1行もないと登録できない" do
    invoice = build_invoice(items: [])
    assert_not invoice.valid?
    assert_includes invoice.errors[:base], "明細を1行以上入力してください"
  end

  # No.7 バリデーション（境界値: 税率は0〜100のみ）
  test "税率は0と100は有効で範囲外は無効" do
    assert build_invoice(tax_rate: 0).valid?
    assert build_invoice(tax_rate: 100).valid?
    assert_not build_invoice(tax_rate: 101).valid?
    assert_not build_invoice(tax_rate: -1).valid?
  end

  # No.8 明細の空行除外（正常系: 品目が空の行は無視される）
  test "品目が空の明細行は保存対象から除外される" do
    invoice = build_invoice(items: [
      { description: "作業A", quantity: 1, unit_price: 1000 },
      { description: "", quantity: 1, unit_price: 999 }
    ])
    invoice.save!
    assert_equal 1, invoice.invoice_items.count
    assert_equal 1000, invoice.subtotal
  end

  # No.9 期限超過（状態: 送付済＋期限切れのみ期限超過になる）
  test "送付済かつ期限を過ぎた請求書だけが期限超過になる" do
    overdue = build_invoice(status: :sent,
                            issue_date: Date.current - 60,
                            due_date: Date.current - 30)
    assert overdue.overdue?
    assert_equal "期限超過", overdue.status_label

    paid = build_invoice(status: :paid,
                         issue_date: Date.current - 60,
                         due_date: Date.current - 30)
    assert_not paid.overdue?
    assert_equal "入金済", paid.status_label
  end

  # No.10 ステータス表示（正常系: 日本語ラベル）
  test "ステータスの日本語ラベルが正しい" do
    assert_equal "下書き", build_invoice(status: :draft).status_label
    assert_equal "送付済", build_invoice(status: :sent).status_label
  end
end
