import {focusTrap} from '@primer/behaviors'
import {getFocusableChild} from '@primer/behaviors/utils'

const observer = new IntersectionObserver(entries => {
  for (const entry of entries) {
    const {isIntersecting, target} = entry
    if (target instanceof FocusTrapElement && target.active !== 'never') {
      isIntersecting ? target.trapFocus() : target.untrapFocus()
    }
  }
})

export class FocusTrapElement extends HTMLElement {
  #trapFocusController?: AbortController

  get active(): 'never' | 'when-visible' {
    const value = this.getAttribute('active')
    if (value === 'when-visible') return value
    return 'never'
  }

  set active(value: 'never' | 'when-visible') {
    this.setAttribute('active', value)
  }

  connectedCallback(): void {
    observer.observe(this)
  }

  trapFocus(): void {
    this.#trapFocusController?.abort()
    if (this.active === 'never') return
    const {signal} = (this.#trapFocusController = new AbortController())
    focusTrap(this, undefined, signal)
  }

  untrapFocus(): void {
    this.#trapFocusController?.abort()
  }

  static observedAttributes = ['active']
  attributeChangedCallback(name: 'active', oldValue: string | null, newValue: string | null): void {
    if (this.active === 'never') this.untrapFocus()
  }
}

declare global {
  interface Window {
    FocusTrapElement: typeof FocusTrapElement
  }
  interface HTMLElementTagNameMap {
    'focus-trap': FocusTrapElement
  }
}

if (!window.customElements.get('focus-trap')) {
  window.FocusTrapElement = FocusTrapElement
  window.customElements.define('focus-trap', FocusTrapElement)
}
