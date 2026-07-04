class Invoice < ApplicationRecord
  belongs_to :client
  has_many :invoice_items, dependent: :destroy

  enum :status, { draft: 0, sent: 1, paid: 2 }

  accepts_nested_attributes_for :invoice_items, allow_destroy: true,
    reject_if: ->(attrs) { attrs["description"].blank? }

  validates :invoice_number, presence: true, uniqueness: true
  validates :issue_date, :due_date, presence: true
  validates :tax_rate, numericality: { only_integer: true,
                                       greater_than_or_equal_to: 0,
                                       less_than_or_equal_to: 100 }
  validate :due_date_not_before_issue_date
  validate :must_have_at_least_one_item

  before_validation :assign_invoice_number, on: :create

  scope :newest_first, -> { order(issue_date: :desc, id: :desc) }
  scope :overdue, -> { sent.where(due_date: ...Date.current) }
  scope :issued_in, ->(month) { where(issue_date: month.beginning_of_month..month.end_of_month) }

  STATUS_LABELS = { "draft" => "下書き", "sent" => "送付済", "paid" => "入金済" }.freeze

  def subtotal
    invoice_items.reject(&:marked_for_destruction?).sum(&:amount)
  end

  # 消費税は端数切り捨て（適格請求書では税率ごとに1回の端数処理）
  def tax_amount
    (subtotal * tax_rate / 100.0).floor
  end

  def total_amount
    subtotal + tax_amount
  end

  def overdue?
    sent? && due_date < Date.current
  end

  def status_label
    overdue? ? "期限超過" : STATUS_LABELS[status]
  end

  # バッジ表示用のキー（期限超過は sent の派生状態として扱う）
  def status_key
    overdue? ? "overdue" : status
  end

  private

  def assign_invoice_number
    return if invoice_number.present?

    prefix = "INV-#{(issue_date || Date.current).strftime('%Y%m')}-"
    last_number = Invoice.where("invoice_number LIKE ?", "#{prefix}%").maximum(:invoice_number)
    sequence = last_number ? last_number.split("-").last.to_i + 1 : 1
    self.invoice_number = "#{prefix}#{format('%03d', sequence)}"
  end

  def due_date_not_before_issue_date
    return if issue_date.blank? || due_date.blank?

    errors.add(:due_date, "は発行日以降の日付にしてください") if due_date < issue_date
  end

  def must_have_at_least_one_item
    if invoice_items.reject(&:marked_for_destruction?).empty?
      errors.add(:base, "明細を1行以上入力してください")
    end
  end
end
