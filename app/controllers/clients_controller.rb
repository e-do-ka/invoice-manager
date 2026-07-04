class ClientsController < ApplicationController
  before_action :set_client, only: %i[show edit update destroy]

  def index
    @clients = Client.order(:id)
    if params[:q].present?
      @clients = @clients.where("name ILIKE :q OR contact_name ILIKE :q", q: "%#{params[:q]}%")
    end
  end

  def show
    @invoices = @client.invoices.includes(:invoice_items).newest_first
  end

  def new
    @client = Client.new
  end

  def create
    @client = Client.new(client_params)
    if @client.save
      redirect_to @client, notice: "顧客「#{@client.name}」を登録しました"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @client.update(client_params)
      redirect_to @client, notice: "顧客情報を更新しました"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    if @client.destroy
      redirect_to clients_path, notice: "顧客「#{@client.name}」を削除しました"
    else
      redirect_to @client, alert: "請求書が存在する顧客は削除できません"
    end
  end

  private

  def set_client
    @client = Client.find(params[:id])
  end

  def client_params
    params.require(:client).permit(:name, :contact_name, :email, :postal_code, :address, :notes)
  end
end
