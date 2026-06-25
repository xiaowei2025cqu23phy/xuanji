import http from '@ohos.net.http'
import dataPreferences from '@ohos.data.preferences'
import { TEN_STEMS_ANALYSIS } from '../model/bazi-data'
import { GET_HEX_BY_BINARY } from '../model/iching-data'

export type AIProvider = string

interface GeminiPart { text: string }
interface GeminiSystemInstruction { parts: GeminiPart[] }
interface GeminiRequestBody {
  contents: ChatMessage[]
  systemInstruction: GeminiSystemInstruction
}

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

export const DEFAULT_AI_CONFIG: AIConfig = {
  provider: 'gemini',
  apiKey: '',
  model: 'gemini-1.5-flash'
}

export const AI_PROVIDERS: ProviderInfo[] = [
  { id: 'gemini', label: 'Google Gemini', defaultModel: 'gemini-1.5-flash', baseUrl: '' },
  { id: 'openai', label: 'ChatGPT (OpenAI)', defaultModel: 'gpt-4o-mini', baseUrl: 'https://api.openai.com/v1' },
  { id: 'deepseek', label: 'DeepSeek', defaultModel: 'deepseek-chat', baseUrl: 'https://api.deepseek.com' },
  { id: 'qwen', label: '阿里通义千问 (Qwen)', defaultModel: 'qwen-plus', baseUrl: 'https://dashscope.aliyuncs.com/compatible-mode/v1' },
  { id: 'zhipu', label: '智谱清言 (GLM)', defaultModel: 'glm-4-flash', baseUrl: 'https://open.bigmodel.cn/api/paas/v4' },
  { id: 'custom', label: '自定义 (OpenAI兼容)', defaultModel: '', baseUrl: '' },
]

export const QUESTION_CATEGORIES: CategoryInfo[] = [
  { id: 'general', label: '综合运势 General', icon: '?' },
  { id: 'career', label: '事业前程 Career', icon: '?' },
  { id: 'love', label: '情感婚姻 Love', icon: '?' },
  { id: 'wealth', label: '财运求财 Wealth', icon: '?' },
  { id: 'health', label: '身体健康 Health', icon: '?' },
]

export type QuestionCategory = string

export interface ChatMessage {
  role: string
  content: string
}

const SYSTEM_PROMPT = '你是一位深谙中华传统易经与八字命理的命理大师，人称"天道先生"。\n' +
  '你说话富有哲理，温婉含蓄，又不失威严。\n' +
  '请根据用户提供的八字格局或卦象结果，给出兼具文学美感与生活指导意义的深度解析。\n' +
  '语气要平和、慈悲。使用中文。'

// ----- Persistent config storage -----
const PREF_STORE = 'ai_config'
const KEY_PROVIDER = 'provider'
const KEY_API_KEY = 'apiKey'
const KEY_MODEL = 'model'
const KEY_BASE_URL = 'baseUrl'

let preferences: dataPreferences.Preferences | null = null

export async function initAIConfig(context: Context): Promise<void> {
  try {
    preferences = await dataPreferences.getPreferences(context, PREF_STORE)
  } catch (_e) {
    preferences = null
  }
}

export async function loadAIConfig(): Promise<AIConfig> {
  if (!preferences) {
    return DEFAULT_AI_CONFIG
  }
  try {
    const provider = await preferences.get(KEY_PROVIDER, DEFAULT_AI_CONFIG.provider) as string
    const apiKey = await preferences.get(KEY_API_KEY, DEFAULT_AI_CONFIG.apiKey) as string
    const model = await preferences.get(KEY_MODEL, DEFAULT_AI_CONFIG.model) as string
    const baseUrl = await preferences.get(KEY_BASE_URL, '') as string
    return { provider, apiKey, model, baseUrl: baseUrl || undefined }
  } catch (_e) {
    return DEFAULT_AI_CONFIG
  }
}

export async function saveAIConfig(config: AIConfig): Promise<void> {
  if (!preferences) {
    return
  }
  try {
    await preferences.put(KEY_PROVIDER, config.provider)
    await preferences.put(KEY_API_KEY, config.apiKey)
    await preferences.put(KEY_MODEL, config.model)
    await preferences.put(KEY_BASE_URL, config.baseUrl || '')
    await preferences.flush()
  } catch (_e) {
    // Persistence failed; config stays in memory for the session
  }
}

// ----- HTTP client helpers -----
const TIMEOUT_CONNECT = 15000  // 15s connection timeout
const TIMEOUT_READ = 30000     // 30s read timeout

function createRequestOptions(method: http.RequestMethod, headers: Record<string, string>, body: string): http.HttpRequestOptions {
  return {
    method: method,
    header: headers,
    extraData: body,
    connectTimeout: TIMEOUT_CONNECT,
    readTimeout: TIMEOUT_READ
  }
}

function safeString(val: Object | undefined | null): string {
  if (val === undefined || val === null) return ''
  return val as string
}

// ----- API callers -----
export async function interpretMetaphysics(
  promptOrMessages: string | ChatMessage[],
  config: AIConfig = DEFAULT_AI_CONFIG
): Promise<string> {
  let messages: ChatMessage[]
  if (typeof promptOrMessages === 'string') {
    messages = [{ role: 'user', content: promptOrMessages }]
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
    return '未设置 API 密钥。请在右上角齿轮图标中配置 AI。'
  }

  const baseUrl = config.baseUrl || getDefaultBaseUrl(config.provider)
  const modelName = config.model || getDefaultModel(config.provider)

  const allMessages: ChatMessage[] = [
    { role: 'system', content: SYSTEM_PROMPT },
    ...messages
  ]

  const httpReq = http.createHttp()
  try {
    const url = baseUrl + '/chat/completions'
    const body = JSON.stringify({ model: modelName, messages: allMessages })
    const response = await httpReq.request(
      url,
      createRequestOptions(http.RequestMethod.POST, {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ' + config.apiKey
      }, body)
    )

    if (response.responseCode === 200) {
      const data = JSON.parse(response.result as string) as Record<string, Object>
      const choices = data['choices'] as Object[]
      if (choices && choices.length > 0) {
        const firstChoice = choices[0] as Record<string, Object>
        const msgObj = firstChoice['message'] as Record<string, Object>
        const content = safeString(msgObj['content'])
        if (content.length > 0) {
          return content
        }
      }
      return 'AI 返回了空响应，请重试。'
    }

    if (response.responseCode === 401 || response.responseCode === 403) {
      return 'API 密钥无效或权限不足 (HTTP ' + response.responseCode + ')。请检查设置。'
    }
    if (response.responseCode === 429) {
      return 'API 调用频率超限，请稍后重试。'
    }
    return 'API 请求失败 (HTTP ' + response.responseCode + ')。请检查网络与配置。'
  } catch (e) {
    const errMsg = (e as Object).toString()
    if (errMsg.includes('timeout') || errMsg.includes('Timeout')) {
      return '网络连接超时，请检查网络后重试。'
    }
    if (errMsg.includes('resolve') || errMsg.includes('DNS') || errMsg.includes('unknown host')) {
      return '无法解析 API 服务器地址，请检查网络或 base URL 配置。'
    }
    return '网络请求失败：' + errMsg.substring(0, 80)
  } finally {
    httpReq.destroy()
  }
}

async function callGeminiAPI(messages: ChatMessage[], config: AIConfig): Promise<string> {
  if (config.apiKey.length === 0) {
    return '未设置 Gemini API 密钥。请在右上角齿轮图标中配置。'
  }

  const modelName = config.model || 'gemini-2.0-flash'

  const contents: ChatMessage[] = []
  for (let i = 0; i < messages.length; i++) {
    const m = messages[i]
    contents.push({ role: m.role === 'user' ? 'user' : 'model', content: m.content })
  }

  const httpReq = http.createHttp()
  try {
    const url = 'https://generativelanguage.googleapis.com/v1beta/models/' + modelName + ':generateContent?key=' + config.apiKey
    const sysPart: GeminiPart = { text: SYSTEM_PROMPT }
    const sysInst: GeminiSystemInstruction = { parts: [sysPart] }
    const reqBody: GeminiRequestBody = {
      contents: contents,
      systemInstruction: sysInst
    }
    const body = JSON.stringify(reqBody)

    const response = await httpReq.request(
      url,
      createRequestOptions(http.RequestMethod.POST, { 'Content-Type': 'application/json' }, body)
    )

    if (response.responseCode === 200) {
      const data = JSON.parse(response.result as string) as Record<string, Object>
      const candidates = data['candidates'] as Object[]
      if (candidates && candidates.length > 0) {
        const first = candidates[0] as Record<string, Object>
        const content = first['content'] as Record<string, Object>
        const parts = content['parts'] as Object[]
        if (parts && parts.length > 0) {
          const part = parts[0] as Record<string, Object>
          const text = safeString(part['text'])
          if (text.length > 0) {
            return text
          }
        }
      }
      // Check for safety block
      const promptFeedback = data['promptFeedback'] as Record<string, Object> | undefined
      if (promptFeedback) {
        const blockReason = safeString(promptFeedback['blockReason'])
        if (blockReason.length > 0) {
          return '内容被 Gemini 安全策略拦截：' + blockReason
        }
      }
      return 'Gemini 返回了空响应，请重试。'
    }

    if (response.responseCode === 400) {
      return 'Gemini API 请求参数错误。请检查模型名称是否正确。'
    }
    if (response.responseCode === 403) {
      return 'Gemini API 密钥无效或权限不足。请检查设置。'
    }
    if (response.responseCode === 429) {
      return 'Gemini API 调用频率超限，请稍后重试。'
    }
    return 'Gemini API 请求失败 (HTTP ' + response.responseCode + ')'
  } catch (e) {
    const errMsg = (e as Object).toString()
    if (errMsg.includes('timeout') || errMsg.includes('Timeout')) {
      return '网络连接超时，请检查网络后重试。'
    }
    return '网络请求失败：' + errMsg.substring(0, 80)
  } finally {
    httpReq.destroy()
  }
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

// ----- Offline fallback analysis -----
export function getOfflineBaziAnalysis(dayMaster: string): string {
  const val = TEN_STEMS_ANALYSIS.get(dayMaster)
  return val !== undefined ? val : '天机自得，顺应自然。'
}

export function getOfflineIChingAnalysis(binary: string): string {
  const hex = GET_HEX_BY_BINARY(binary)
  return hex.name + '：' + hex.judgement + '\n' + hex.meaning
}
