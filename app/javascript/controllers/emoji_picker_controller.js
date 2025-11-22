import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["group"]

  select(event) {
    this.groupTargets.forEach(element => {
      element.classList.remove("active")
    })
    event.currentTarget.classList.add("active")
  }
}
