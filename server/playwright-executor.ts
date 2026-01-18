import { chromium, firefox, webkit, Browser, Page, BrowserContext } from 'playwright'

export interface PlaywrightAction {
  type: string
  params: Record<string, any>
}

export interface ExecutionContext {
  browser?: Browser
  context?: BrowserContext
  pages: Page[]
  variables: Record<string, any>
  browserType?: string
}

export class PlaywrightExecutor {
  private activeBrowsers: Map<string, Browser> = new Map()

  async createExecutionContext(browserType: string = 'chromium'): Promise<ExecutionContext> {
    let browser: Browser

    switch (browserType) {
      case 'firefox':
        browser = await firefox.launch({
          headless: false
        })
        break
      case 'webkit':
        browser = await webkit.launch({
          headless: false
        })
        break
      case 'chromium':
      default:
        browser = await chromium.launch({
          headless: false,
          args: ['--start-maximized']
        })
        break
    }

    const context = await browser.newContext({
      viewport: null
    })

    const sessionId = Date.now().toString()
    this.activeBrowsers.set(sessionId, browser)

    return {
      browser,
      context,
      pages: [],
      variables: {},
      browserType
    }
  }

  async executeAction(
    action: PlaywrightAction,
    context: ExecutionContext
  ): Promise<{ success: boolean; result?: any; error?: string }> {
    try {
      switch (action.type) {
        case 'open_tabs':
          return await this.openTabs(action.params as { count: number; urls?: string[] }, context)

        case 'navigate':
          return await this.navigate(action.params as { url: string; pageIndex?: number }, context)

        case 'click':
          return await this.click(action.params as { selector: string; pageIndex?: number }, context)

        case 'fill':
          return await this.fill(action.params as { selector: string; text: string; pageIndex?: number }, context)

        case 'wait':
          return await this.wait(action.params, context)

        case 'screenshot':
          return await this.screenshot(action.params, context)

        case 'extract_text':
          return await this.extractText(action.params as { selector: string; pageIndex?: number }, context)

        case 'close_tab':
          return await this.closeTab(action.params, context)

        default:
          return {
            success: false,
            error: `Unknown action type: ${action.type}`
          }
      }
    } catch (error: any) {
      return {
        success: false,
        error: error.message
      }
    }
  }

  private async openTabs(
    params: { count: number; urls?: string[] },
    context: ExecutionContext
  ) {
    const { count, urls = [] } = params

    if (!context.context) {
      return { success: false, error: 'Browser context not initialized' }
    }

    const pagesToCreate = Math.max(count, urls.length)
    const newPages: Page[] = []

    for (let i = 0; i < pagesToCreate; i++) {
      const page = await context.context.newPage()
      newPages.push(page)

      if (urls[i]) {
        await page.goto(urls[i])
      }
    }

    context.pages.push(...newPages)

    return {
      success: true,
      result: {
        pagesCreated: newPages.length,
        totalPages: context.pages.length
      }
    }
  }

  private async navigate(
    params: { url: string; pageIndex?: number },
    context: ExecutionContext
  ) {
    const { url, pageIndex = 0 } = params
    const page = context.pages[pageIndex]

    if (!page) {
      return { success: false, error: `Page at index ${pageIndex} not found` }
    }

    await page.goto(url)
    return { success: true, result: { url, pageIndex } }
  }

  private async click(
    params: { selector: string; pageIndex?: number },
    context: ExecutionContext
  ) {
    const { selector, pageIndex = 0 } = params
    const page = context.pages[pageIndex]

    if (!page) {
      return { success: false, error: `Page at index ${pageIndex} not found` }
    }

    await page.click(selector)
    return { success: true, result: { selector, pageIndex } }
  }

  private async fill(
    params: { selector: string; text: string; pageIndex?: number },
    context: ExecutionContext
  ) {
    const { selector, text, pageIndex = 0 } = params
    const page = context.pages[pageIndex]

    if (!page) {
      return { success: false, error: `Page at index ${pageIndex} not found` }
    }

    await page.fill(selector, text)
    return { success: true, result: { selector, text, pageIndex } }
  }

  private async wait(
    params: { milliseconds?: number; selector?: string; pageIndex?: number },
    context: ExecutionContext
  ) {
    const { milliseconds, selector, pageIndex = 0 } = params
    const page = context.pages[pageIndex]

    if (!page) {
      return { success: false, error: `Page at index ${pageIndex} not found` }
    }

    if (selector) {
      await page.waitForSelector(selector)
    } else if (milliseconds) {
      await page.waitForTimeout(milliseconds)
    }

    return { success: true, result: { pageIndex } }
  }

  private async screenshot(
    params: { path?: string; fullPage?: boolean; pageIndex?: number },
    context: ExecutionContext
  ) {
    const { path, fullPage = false, pageIndex = 0 } = params
    const page = context.pages[pageIndex]

    if (!page) {
      return { success: false, error: `Page at index ${pageIndex} not found` }
    }

    const screenshot = await page.screenshot({
      path,
      fullPage
    })

    return {
      success: true,
      result: {
        path,
        size: screenshot.length,
        pageIndex
      }
    }
  }

  private async extractText(
    params: { selector: string; pageIndex?: number },
    context: ExecutionContext
  ) {
    const { selector, pageIndex = 0 } = params
    const page = context.pages[pageIndex]

    if (!page) {
      return { success: false, error: `Page at index ${pageIndex} not found` }
    }

    const text = await page.textContent(selector)
    return { success: true, result: { text, selector, pageIndex } }
  }

  private async closeTab(
    params: { pageIndex?: number },
    context: ExecutionContext
  ) {
    const { pageIndex = 0 } = params
    const page = context.pages[pageIndex]

    if (!page) {
      return { success: false, error: `Page at index ${pageIndex} not found` }
    }

    await page.close()
    context.pages.splice(pageIndex, 1)

    return {
      success: true,
      result: {
        closedPageIndex: pageIndex,
        remainingPages: context.pages.length
      }
    }
  }

  async cleanup(context: ExecutionContext) {
    try {
      if (context.browser) {
        await context.browser.close()
      }
    } catch (error) {
      console.error('Error during cleanup:', error)
    }
  }
}
