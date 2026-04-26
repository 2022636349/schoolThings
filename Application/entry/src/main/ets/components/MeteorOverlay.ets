import { mediaquery } from '@kit.ArkUI';

interface MeteorParticle {
  x: number;
  y: number;
  vx: number;
  vy: number;
  len: number;
  alpha: number;
  width: number;
  hue: number;
}

@Component
export struct MeteorOverlay {
  @Prop suppressInTablet: boolean = false;
  @StorageProp('isTabletMode') isTablet: boolean = false;
  @StorageProp('meteorEnabled') @Watch('onCondChange') meteorEnabled: boolean = true;
  @StorageProp('darkModeForced') @Watch('onCondChange') darkModeForced: boolean = false;
  @StorageProp('appInBackground') @Watch('onCondChange') appInBackground: boolean = false;
  @State @Watch('onCondChange') isDark: boolean = false;
  @State canvasReady: boolean = false;

  private settings: RenderingContextSettings = new RenderingContextSettings(true);
  private ctx: CanvasRenderingContext2D = new CanvasRenderingContext2D(this.settings);
  private particles: MeteorParticle[] = [];
  private timer: number = -1;
  private listener: mediaquery.MediaQueryListener | null = null;
  private canvasW: number = 0;
  private canvasH: number = 0;
  private readonly PARTICLE_COUNT: number = 26;

  aboutToAppear(): void {
    try {
      this.listener = mediaquery.matchMediaSync('(dark-mode: true)');
      this.isDark = this.listener.matches;
      this.listener.on('change', (result: mediaquery.MediaQueryResult) => {
        this.isDark = result.matches;
      });
    } catch (e) {
      console.error('[MeteorOverlay] mediaquery init failed:', JSON.stringify(e));
    }
  }

  aboutToDisappear(): void {
    this.stopAnim();
    try {
      if (this.listener) {
        this.listener.off('change');
        this.listener = null;
      }
    } catch (e) {
    }
  }

  private shouldRender(): boolean {
    if (this.suppressInTablet && this.isTablet) return false;
    return (this.isDark || this.darkModeForced) && this.meteorEnabled && !this.appInBackground;
  }

  onCondChange(): void {
    if (this.shouldRender() && this.canvasReady) {
      this.startAnim();
    } else {
      this.stopAnim();
    }
  }

  private spawn(initialOffscreen: boolean): MeteorParticle {
    const angle = Math.PI * 0.30 + (Math.random() - 0.5) * 0.08;
    const speed = 2.6 + Math.random() * 2.6;
    const w = this.canvasW > 0 ? this.canvasW : 360;
    const h = this.canvasH > 0 ? this.canvasH : 720;
    return {
      x: Math.random() * (w + 240) - 60,
      y: initialOffscreen ? Math.random() * h - h * 0.6 : -30 - Math.random() * 120,
      vx: -speed * Math.cos(angle),
      vy: speed * Math.sin(angle),
      len: 70 + Math.random() * 80,
      alpha: 0.32 + Math.random() * 0.55,
      width: 0.9 + Math.random() * 1.1,
      hue: Math.random() < 0.18 ? 1 : 0
    };
  }

  private startAnim(): void {
    if (this.timer !== -1) return;
    if (this.canvasW === 0 || this.canvasH === 0) return;
    if (this.particles.length === 0) {
      for (let i = 0; i < this.PARTICLE_COUNT; i++) {
        this.particles.push(this.spawn(true));
      }
    }
    this.timer = setInterval(() => { this.tick(); }, 33);
  }

  private stopAnim(): void {
    if (this.timer !== -1) {
      clearInterval(this.timer);
      this.timer = -1;
    }
    try {
      if (this.canvasReady) {
        this.ctx.clearRect(0, 0, this.canvasW, this.canvasH);
      }
    } catch (e) {
    }
  }

  private tick(): void {
    const w = this.canvasW;
    const h = this.canvasH;
    this.ctx.clearRect(0, 0, w, h);
    for (let i = 0; i < this.particles.length; i++) {
      const p = this.particles[i];
      p.x += p.vx;
      p.y += p.vy;
      if (p.y > h + 30 || p.x < -160) {
        const np = this.spawn(false);
        p.x = np.x; p.y = np.y;
        p.vx = np.vx; p.vy = np.vy;
        p.len = np.len; p.alpha = np.alpha;
        p.width = np.width; p.hue = np.hue;
      }
      const tailX = p.x - p.vx * (p.len / 6);
      const tailY = p.y - p.vy * (p.len / 6);
      const headColor = p.hue === 1
        ? `rgba(255,225,180,${p.alpha})`
        : `rgba(190,215,255,${p.alpha})`;
      const tailColor = p.hue === 1
        ? 'rgba(255,225,180,0)'
        : 'rgba(190,215,255,0)';
      const grad = this.ctx.createLinearGradient(p.x, p.y, tailX, tailY);
      grad.addColorStop(0, headColor);
      grad.addColorStop(1, tailColor);
      this.ctx.strokeStyle = grad;
      this.ctx.lineWidth = p.width;
      this.ctx.lineCap = 'round';
      this.ctx.beginPath();
      this.ctx.moveTo(p.x, p.y);
      this.ctx.lineTo(tailX, tailY);
      this.ctx.stroke();

      this.ctx.fillStyle = `rgba(255,255,255,${p.alpha * 0.85})`;
      this.ctx.beginPath();
      this.ctx.arc(p.x, p.y, p.width * 0.9, 0, Math.PI * 2);
      this.ctx.fill();
    }
  }

  build() {
    Canvas(this.ctx)
      .width('100%')
      .height('100%')
      .hitTestBehavior(HitTestMode.Transparent)
      .opacity(this.shouldRender() ? 1 : 0)
      .onReady(() => {
        this.canvasW = this.ctx.width;
        this.canvasH = this.ctx.height;
        this.canvasReady = true;
        if (this.shouldRender()) {
          this.startAnim();
        }
      })
  }
}
