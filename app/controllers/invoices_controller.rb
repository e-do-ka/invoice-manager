class InvoicesController < ApplicationController
  before_action :set_invoice, only: %i[show edit update destroy print update_status]

  def index
    @invoices = Invoice.includes(:client, :invoice_items).newest_first
    @invoices = @invoices.where(status: params[:status]) if params[:status].present?
    @invoices = @invoices.where(client_id: params[:client_id]) if params[:client_id].present?
    if params[:q].present?
      @invoices = @invoices.left_joins(:client)
                           .where("invoices.invoice_number ILIKE :q OR clients.name ILIKE :q",
                                  q: "%#{params[:q]}%")
    end
    @clients = Client.order(:name)
  end

  def show
  end

  def new
    @invoice = Invoice.new(issue_date: Date.current, due_date: (Date.current >> 1).end_of_month)
    3.times { @invoice.invoice_items.build }
  end

  def create
    @invoice = Invoice.new(invoice_params)
    if @invoice.save
      redirect_to @invoice, notice: "請求書 #{@invoice.invoice_number} を作成しました"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @invoice.update(invoice_params)
      redirect_to @invoice, notice: "請求書 #{@invoice.invoice_number} を更新しました"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @invoice.destroy
    redirect_to invoices_path, notice: "請求書 #{@invoice.invoice_number} を削除しました"
  end

  # 印刷用の請求書レイアウト（ブラウザの印刷機能でPDF保存可能）
  def print
    @company = CompanySetting.current
    render layout: "print"
  end

  def update_status
    case params[:to]
    when "sent"  then @invoice.update!(status: :sent)
    when "paid"  then @invoice.update!(status: :paid, paid_on: Date.current)
    when "draft" then @invoice.update!(status: :draft, paid_on: nil)
    else
      return redirect_back fallback_location: invoice_path(@invoice), alert: "不正なステータスです"
    end
    redirect_back fallback_location: invoice_path(@invoice),
                  notice: "#{@invoice.invoice_number} を「#{@invoice.status_label}」に更新しました"
  end

  private

  def set_invoice
    @invoice = Invoice.find(params[:id])
  end

  def invoice_params
    params.require(:invoice).permit(
      :client_id, :issue_date, :due_date, :tax_rate, :notes,
      invoice_items_attributes: %i[id description quantity unit_price _destroy]
    )
  end
end
