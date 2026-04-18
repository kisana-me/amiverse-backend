import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    // すでにラップされている場合は何もしない
    if (this.element.closest(".ctmf-password-wrap")) return

    // ラップを生成
    const wrapper = document.createElement("div")
    wrapper.classList.add("ctmf-password-wrap")

    // 要素をラップで囲む
    this.element.parentNode.insertBefore(wrapper, this.element)
    wrapper.appendChild(this.element)

    // トグルボタン作成
    const button = document.createElement("button")
    button.type = "button"
    button.className = "ctmf-password-toggle"
    button.innerHTML = "👁"
    wrapper.appendChild(button)

    // クリックで表示切り替え
    button.addEventListener("click", () => {
      const isPassword = this.element.type === "password"
      this.element.type = isPassword ? "text" : "password"
      button.innerHTML = isPassword ? "🙈" : "👁"
    })
  }
}
