class CompanySettingsController < ApplicationController
  before_action :set_company_setting

  def edit
  end

  def update
    if @company_setting.update(company_setting_params)
      redirect_to edit_company_setting_path, notice: "自社情報を更新しました"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def set_company_setting
    @company_setting = CompanySetting.current
  end

  def company_setting_params
    params.require(:company_setting).permit(
      :name, :postal_code, :address, :tel, :email, :registration_number, :bank_info
    )
  end
end
