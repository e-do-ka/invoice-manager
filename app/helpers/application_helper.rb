module ApplicationHelper
  def yen(amount)
    "¥#{number_with_delimiter(amount)}"
  end

  def status_badge(invoice)
    tag.span(invoice.status_label, class: "badge badge-#{invoice.status_key}")
  end
end
