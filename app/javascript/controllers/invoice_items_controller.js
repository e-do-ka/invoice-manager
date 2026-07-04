import { Controller } from "@hotwired/stimulus"

// 請求書フォームの明細行を管理する。
// 行の追加・削除（保存済みの行は _destroy フラグで論理削除）と、
// 数量・単価・税率の入力に応じた金額のライブ計算を行う。
export default class extends Controller {
  static targets = ["rows", "template", "row", "taxRate", "subtotal", "tax", "total"]

  connect() {
    this.recalculate()
  }

  add() {
    const html = this.templateTarget.innerHTML.replace(/NEW_RECORD/g, Date.now().toString())
    this.rowsTarget.insertAdjacentHTML("beforeend", html)
    this.recalculate()
  }

  remove(event) {
    const row = event.target.closest("tr")
    const idInput = row.querySelector("input[name*='[id]']")
    if (idInput && idInput.value) {
      row.querySelector("input[name*='_destroy']").value = "1"
      row.hidden = true
    } else {
      row.remove()
    }
    this.recalculate()
  }

  recalculate() {
    let subtotal = 0
    this.rowTargets.forEach((row) => {
      if (row.hidden) return
      const destroyInput = row.querySelector("input[name*='_destroy']")
      if (destroyInput && destroyInput.value === "1") return

      const quantity = parseFloat(row.querySelector("input[name*='[quantity]']").value) || 0
      const unitPrice = parseInt(row.querySelector("input[name*='[unit_price]']").value, 10) || 0
      const amount = Math.floor(quantity * unitPrice)
      row.querySelector(".item-amount").textContent = this.formatYen(amount)
      subtotal += amount
    })

    const rate = this.hasTaxRateTarget ? parseInt(this.taxRateTarget.value, 10) || 0 : 10
    const tax = Math.floor(subtotal * rate / 100)
    this.subtotalTarget.textContent = this.formatYen(subtotal)
    this.taxTarget.textContent = this.formatYen(tax)
    this.totalTarget.textContent = this.formatYen(subtotal + tax)
  }

  formatYen(amount) {
    return "¥" + amount.toLocaleString("ja-JP")
  }
}
