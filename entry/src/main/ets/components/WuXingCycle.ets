import { COLORS, ELEMENT_COLORS, ELEMENT_ORDER, OP } from '../common/constants'

interface Point {
  x: number
  y: number
}

@Component
export struct WuXingCycle {
  @Prop elements: Map<string, number>
  @Prop strengths: Map<string, string>

  private settings: RenderingContextSettings = new RenderingContextSettings(true)
  private context: CanvasRenderingContext2D = new CanvasRenderingContext2D(this.settings)

  build() {
    Stack() {
      Canvas(this.context).width('100%').height('100%').onReady(() => { this.drawCycle() })
    }
    .width('100%').aspectRatio(1).constraintSize({ maxWidth: 400 })
    .backgroundColor(COLORS.WHITE + OP.X_LOW).borderRadius('50%')
    .border({ width: 1, color: COLORS.INK_BLACK + OP.X_FAINT }).padding(16)
  }

  drawCycle() {
    const ctx = this.context
    const width = ctx.width
    const height = ctx.height
    const centerX = width / 2
    const centerY = height / 2
    const radius = Math.min(centerX, centerY) * 0.6

    ctx.clearRect(0, 0, width, height)

    const elementCount = ELEMENT_ORDER.length
    const positions: Point[] = []
    for (let i = 0; i < elementCount; i++) {
      const angle = (i * 72 - 90) * Math.PI / 180
      positions.push({ x: centerX + radius * Math.cos(angle), y: centerY + radius * Math.sin(angle) })
    }

    // Generative cycle (outer arcs)
    for (let i = 0; i < elementCount; i++) {
      const next = (i + 1) % elementCount
      const color = ELEMENT_COLORS.get(ELEMENT_ORDER[i]) || COLORS.INK_BLACK
      ctx.beginPath()
      ctx.arc(centerX, centerY, radius, (i * 72 - 90) * Math.PI / 180, (next * 72 - 90) * Math.PI / 180, false)
      ctx.strokeStyle = color; ctx.lineWidth = 1.5; ctx.setLineDash([4, 2]); ctx.globalAlpha = 0.2; ctx.stroke()
      ctx.setLineDash([]); ctx.globalAlpha = 1
    }

    // Overcoming cycle (inner lines)
    for (let i = 0; i < elementCount; i++) {
      const target = (i + 2) % elementCount
      ctx.beginPath()
      ctx.moveTo(positions[i].x, positions[i].y); ctx.lineTo(positions[target].x, positions[target].y)
      ctx.strokeStyle = COLORS.INK_BLACK; ctx.lineWidth = 0.5; ctx.setLineDash([1, 4]); ctx.globalAlpha = 0.15; ctx.stroke()
      ctx.setLineDash([]); ctx.globalAlpha = 1
    }

    // Element nodes
    for (let i = 0; i < elementCount; i++) {
      const elem = ELEMENT_ORDER[i]
      const pos = positions[i]
      const count = this.elements.get(elem) || 0
      const size = 22 + (count / 8) * 18
      const color = ELEMENT_COLORS.get(elem) || COLORS.INK_BLACK
      const strengthText = this.strengths.get(elem)

      // Glow halo
      if (strengthText === '旺' || strengthText === '相') {
        ctx.beginPath(); ctx.arc(pos.x, pos.y, size + 12, 0, Math.PI * 2)
        ctx.fillStyle = strengthText === '旺' ? 'rgba(194, 59, 34, 0.15)' : 'rgba(0, 0, 0, 0.05)'; ctx.fill()
      }

      ctx.beginPath(); ctx.arc(pos.x, pos.y, size, 0, Math.PI * 2)
      ctx.fillStyle = COLORS.WHITE; ctx.fill()
      ctx.strokeStyle = color; ctx.lineWidth = strengthText === '旺' ? 3 : 2; ctx.stroke()

      ctx.beginPath(); ctx.arc(pos.x, pos.y, size - 4, 0, Math.PI * 2)
      ctx.fillStyle = color; ctx.globalAlpha = 0.1; ctx.fill(); ctx.globalAlpha = 1

      ctx.font = '16px sans-serif'; ctx.fillStyle = color; ctx.textAlign = 'center'; ctx.textBaseline = 'middle'
      ctx.fillText(elem, pos.x, pos.y)

      if (strengthText) {
        ctx.font = '9px sans-serif'
        const textWidth = ctx.measureText(strengthText).width
        const labelBgColor = strengthText === '旺' ? color : (strengthText === '相' ? COLORS.WOOD : 'gray')
        ctx.fillStyle = labelBgColor; ctx.globalAlpha = 0.8
        ctx.fillRect(pos.x - textWidth / 2 - 3, pos.y + size + 2, textWidth + 6, 14)
        ctx.globalAlpha = 1; ctx.fillStyle = COLORS.WHITE; ctx.fillText(strengthText, pos.x, pos.y + size + 9)
      }
    }
  }
}
