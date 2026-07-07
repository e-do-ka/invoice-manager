require "test_helper"

# 各テストの No は docs/テストパターン.md の表と対応している。
class InvoicesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @client = Client.create!(name: "テスト商事")
    @invoice = Invoice.create!(
      client: @client,
      issue_date: Date.current,
      due_date: Date.current + 30,
      tax_rate: 10,
      invoice_items_attributes: [ { description: "作業A", quantity: 1, unit_price: 1000 } ]
    )
  end

  # No.15 ダッシュボード（正常系）
  test "ダッシュボードが表示される" do
    get root_path
    assert_response :success
  end

  # No.16 請求書一覧（正常系: 絞り込み込み）
  test "請求書一覧が表示され絞り込みも動く" do
    get invoices_path
    assert_response :success
    get invoices_path, params: { status: "draft", q: "INV" }
    assert_response :success
  end

  # No.17 請求書作成（正常系）
  test "請求書を作成できる" do
    assert_difference("Invoice.count", 1) do
      post invoices_path, params: {
        invoice: {
          client_id: @client.id,
          issue_date: Date.current,
          due_date: Date.current + 30,
          tax_rate: 10,
          invoice_items_attributes: {
            "0" => { description: "新規作業", quantity: 2, unit_price: 5000 }
          }
        }
      }
    end
    assert_redirected_to invoice_path(Invoice.newest_first.first)
  end

  # No.18 請求書作成（異常系: 明細なしは422で再表示）
  test "明細なしでは作成できずフォームが再表示される" do
    assert_no_difference("Invoice.count") do
      post invoices_path, params: {
        invoice: {
          client_id: @client.id,
          issue_date: Date.current,
          due_date: Date.current + 30,
          tax_rate: 10
        }
      }
    end
    assert_response :unprocessable_entity
  end

  # No.19 請求書詳細・印刷レイアウト（正常系）
  test "詳細と印刷用レイアウトが表示される" do
    get invoice_path(@invoice)
    assert_response :success
    get print_invoice_path(@invoice)
    assert_response :success
  end

  # No.20 ステータス更新（正常系: 入金済にすると入金日が入る）
  test "ステータスを入金済に更新すると入金日が記録される" do
    patch update_status_invoice_path(@invoice), params: { to: "paid" }
    assert_redirected_to invoice_path(@invoice)
    @invoice.reload
    assert @invoice.paid?
    assert_equal Date.current, @invoice.paid_on
  end

  # No.21 ステータス更新（異常系: 不正な値は拒否）
  test "不正なステータス値は拒否される" do
    patch update_status_invoice_path(@invoice), params: { to: "hacked" }
    assert_redirected_to invoice_path(@invoice)
    assert_equal "不正なステータスです", flash[:alert]
    assert @invoice.reload.draft?
  end

  # No.22 請求書削除（正常系）
  test "請求書を削除できる" do
    assert_difference("Invoice.count", -1) do
      delete invoice_path(@invoice)
    end
    assert_redirected_to invoices_path
  end
end
