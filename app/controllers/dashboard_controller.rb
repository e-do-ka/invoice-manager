class DashboardController < ApplicationController
  def index
    invoices = Invoice.includes(:client, :invoice_items)
    today = Date.current

    @overdue_invoices = invoices.overdue.order(:due_date)
    @unpaid_total = invoices.sent.sum(&:total_amount)
    @month_sales = invoices.where.not(status: :draft).issued_in(today).sum(&:total_amount)
    @paid_count = invoices.paid.issued_in(today).count

    @monthly_sales = (0..5).map { |i|
      month = today.beginning_of_month << i
      [ month, invoices.where.not(status: :draft).issued_in(month).sum(&:total_amount) ]
    }.reverse

    @recent_invoices = invoices.newest_first.limit(5)
  end
end
