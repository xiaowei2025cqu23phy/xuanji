import http from '@ohos.net.http'
import { TEN_STEMS_ANALYSIS } from '../model/bazi-data'
import { GET_HEX_BY_BINARY } from '../model/iching-data'

export type AIProvider = string

export interface AIConfig {
  provider: AIProvider
  apiKey: string
  model: string
  baseUrl?: string
}

export interface ProviderInfo {
  id: string
  label: string
  defaultModel: string
  baseUrl: string
}

export interface CategoryInfo {
  id: string
  label: string
  icon: string
}

function makeAIConfig(provider: AIProvider, apiKey: string, model: string): AIConfig {
  let config: AIConfig = { provider: provider, apiKey: apiKey, model: model }
  return config
}
export const DEFAULT_AI_CONFIG: AIConfig = makeAIConfig('gemini', '', 'gemini-1.5-flash')

function makeProviderInfo(id: string, label: string, defaultModel: string, baseUrl: string): ProviderInfo {
  let info: ProviderInfo = { id: id, label: label, defaultModel: defaultModel, baseUrl: baseUrl }
  return info
}

function buildProviders(): ProviderInfo[] {
  let providers: ProviderInfo[] = []
  providers.push(makeProviderInfo('gemini', 'Google Gemini', 'gemini-1.5-flash', ''))
  providers.push(makeProviderInfo('openai', 'ChatGPT (OpenAI)', 'gpt-4o-mini', 'https://api.openai.com/v1'))
  providers.push(makeProviderInfo('deepseek', 'DeepSeek', 'deepseek-chat', 'https://api.deepseek.com'))
  providers.push(makeProviderInfo('qwen', '阿里通义千问 (Qwen)', 'qwen-plus', 'https://dashscope.aliyuncs.com/compatible-mode/v1'))
  providers.push(makeProviderInfo('zhipu', '智谱清言 (GLM)', 'glm-4-flash', 'https://open.bigmodel.cn/api/paas/v4'))
  providers.push(makeProviderInfo('custom', '自定义 (OpenAI兼容)', '', ''))
  return providers
}
export const AI_PROVIDERS: ProviderInfo[] = buildProviders()

function makeCategoryInfo(id: string, label: string, icon: string): CategoryInfo {
  let cat: CategoryInfo = { id: id, label: label, icon: icon }
  return cat
}

function buildCategories(): CategoryInfo[] {
  let cats: CategoryInfo[] = []
  cats.push(makeCategoryInfo('general', '综合运势 General', '?'))
  cats.push(makeCategoryInfo('career', '事业前程 Career', '?'))
  cats.push(makeCategoryInfo('love', '情感婚姻 Love', '?'))
  cats.push(makeCategoryInfo('wealth', '财运求财 Wealth', '?'))
  cats.push(makeCategoryInfo('health', '身体健康 Health', '?'))
  return cats
}
export const QUESTION_CATEGORIES: CategoryInfo[] = buildCategories()

export type QuestionCategory = string

export interface ChatMessage {
  role: string
  content: string
}

export function makeChatMessage(role: string, content: string): ChatMessage {
  let msg: ChatMessage = { role: role, content: content }
  return msg
}

const SYSTEM_PROMPT = '你是一位深谙中华传统易经与八字命理的命理大师，人称"天道先生"。\n' +
  '你说话富有哲理，温婉含蓄，又不失威严。\n' +
  '请根据用户提供的八字格局或卦象结果，给出兼具文学美感与生活指导意义的深度解析。\n' +
  '语气要平和、慈悲。使用中文。'

// In-memory config storage (no @ohos.data.preferences dependency)
let savedConfig: AIConfig = DEFAULT_AI_CONFIG

export function loadAIConfig(): AIConfig {
  return savedConfig
}

export function saveAIConfig(config: AIConfig): void {
  savedConfig = config
}

export async function interpretMetaphysics(
  promptOrMessages: string | ChatMessage[],
  config: AIConfig = DEFAULT_AI_CONFIG
): Promise<string> {
  let messages: ChatMessage[] = []
  if (typeof promptOrMessages === 'string') {
    let msg: ChatMessage = makeChatMessage('user', promptOrMessages)
    messages = [msg]
  } else {
    messages = promptOrMessages
  }

  if (config.provider === 'gemini') {
    return await callGeminiAPI(messages, config)
  }

  return await callOpenAICompatibleAPI(messages, config)
}

async function callOpenAICompatibleAPI(messages: ChatMessage[], config: AIConfig): Promise<string> {
  if (config.apiKey.length === 0) {
    return '未设置 API 密钥。请在设置中配置。'
  }

  const baseUrl = config.baseUrl || getDefaultBaseUrl(config.provider)
  const modelName = config.model || getDefaultModel(config.provider)

  // Build messages array with system prompt prepended
  let allMessages: ChatMessage[] = []
  let sysMsg: ChatMessage = makeChatMessage('system', SYSTEM_PROMPT)
  allMessages.push(sysMsg)
  for (let i = 0; i < messages.length; i++) {
    allMessages.push(messages[i])
  }

  const httpRequest = http.createHttp()
  let result: string = 'API 请求失败，请检查网络连接和API配置。'
  try {
    const url: string = baseUrl + '/chat/completions'
    const body: string = JSON.stringify({
      model: modelName,
      messages: allMessages
    })
    const response = await httpRequest.request(
      url,
      {
        method: http.RequestMethod.POST,
        header: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ' + config.apiKey
        },
        extraData: body
      }
    )

    if (response.responseCode === 200) {
      const respStr: string = response.result as string
      const data: Object = JSON.parse(respStr) as Object
      const dataObj: Record<string, Object> = data as Record<string, Object>
      const choices: Object[] = dataObj['choices'] as Object[]
      if (choices && choices.length > 0) {
        const firstChoice: Record<string, Object> = choices[0] as Record<string, Object>
        const msgObj: Record<string, Object> = firstChoice['message'] as Record<string, Object>
        const content: string = msgObj['content'] as string
        if (content && content.length > 0) {
          result = content
        }
      }
    }
  } catch (e) {
    // Return error message
  } finally {
    httpRequest.destroy()
  }
  return result
}

async function callGeminiAPI(messages: ChatMessage[], config: AIConfig): Promise<string> {
  if (config.apiKey.length === 0) {
    return '未设置 Gemini API 密钥。请在设置中配置并保存。'
  }

  const modelName = config.model || 'gemini-2.0-flash'

  // Build contents array for Gemini
  let contents: ChatMessage[] = []
  for (let i = 0; i < messages.length; i++) {
    const m = messages[i]
    const geminiRole: string = m.role === 'user' ? 'user' : 'model'
    let contentObj: ChatMessage = makeChatMessage(geminiRole, m.content)
    contents.push(contentObj)
  }

  const httpRequest = http.createHttp()
  let result: string = 'Gemini API 请求失败。'

  try {
    const url: string = 'https://generativelanguage.googleapis.com/v1beta/models/' + modelName + ':generateContent?key=' + config.apiKey
    let sysPart: ChatMessage = makeChatMessage('system', SYSTEM_PROMPT)
    let sysParts: ChatMessage[] = []
    sysParts.push(sysPart)
    let bodyRecord: Record<string, Object> = {} as Record<string, Object>
    bodyRecord['contents'] = contents as Object
    let siObj: Record<string, Object> = {} as Record<string, Object>
    siObj['parts'] = sysParts as Object
    bodyRecord['systemInstruction'] = siObj as Object
    const body: string = JSON.stringify(bodyRecord)

    const response = await httpRequest.request(
      url,
      {
        method: http.RequestMethod.POST,
        header: {
          'Content-Type': 'application/json',
        },
        extraData: body
      }
    )

    if (response.responseCode === 200) {
      const respStr: string = response.result as string
      const data: Object = JSON.parse(respStr) as Object
      const dataObj: Record<string, Object> = data as Record<string, Object>
      const candidates: Object[] = dataObj['candidates'] as Object[]
      if (candidates && candidates.length > 0) {
        const first: Record<string, Object> = candidates[0] as Record<string, Object>
        const content: Record<string, Object> = first['content'] as Record<string, Object>
        const parts: Object[] = content['parts'] as Object[]
        if (parts && parts.length > 0) {
          const part: Record<string, Object> = parts[0] as Record<string, Object>
          const text: string = part['text'] as string
          if (text && text.length > 0) {
            result = text
          }
        }
      }
    }
  } catch (e) {
    // Return error message
  } finally {
    httpRequest.destroy()
  }
  return result
}

function getDefaultBaseUrl(provider: AIProvider): string {
  for (let i = 0; i < AI_PROVIDERS.length; i++) {
    if (AI_PROVIDERS[i].id === provider) {
      return AI_PROVIDERS[i].baseUrl || 'https://api.openai.com/v1'
    }
  }
  return 'https://api.openai.com/v1'
}

function getDefaultModel(provider: AIProvider): string {
  for (let i = 0; i < AI_PROVIDERS.length; i++) {
    if (AI_PROVIDERS[i].id === provider) {
      return AI_PROVIDERS[i].defaultModel || ''
    }
  }
  return ''
}

export function getOfflineBaziAnalysis(dayMaster: string): string {
  let val = TEN_STEMS_ANALYSIS.get(dayMaster)
  return val !== undefined ? val : '天机自得，顺应自然。'
}

export function getOfflineIChingAnalysis(binary: string): string {
  const hex = GET_HEX_BY_BINARY(binary)
  return hex.name + '：' + hex.judgement + '\n' + hex.meaning
}
