import http from '@ohos.net.http'
import dataPreferences from '@ohos.data.preferences'
import { asset } from '@kit.AssetStoreKit'
import { util } from '@kit.ArkTS'
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
  model: 'gemini-2.0-flash'
}

export const AI_PROVIDERS: ProviderInfo[] = [
  { id: 'gemini', label: 'Google Gemini', defaultModel: 'gemini-2.0-flash', baseUrl: '' },
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
const KEY_DARK_MODE = 'darkMode'
const KEY_LATE_ZI = 'lateZiHuanRi'

// ----- API Key 安全存储（系统 Asset Store 加密，不落明文） -----
const ASSET_ALIAS = 'tiandao_api_key'

function strToBytes(s: string): Uint8Array {
  const enc = new util.TextEncoder()
  return enc.encodeInto(s)
}

function bytesToStr(b: Uint8Array): string {
  const dec = util.TextDecoder.create('utf-8')
  return dec.decodeToString(b)
}

function apiKeyAliasMap(): asset.AssetMap {
  const m: asset.AssetMap = new Map<asset.Tag, asset.Value>()
  m.set(asset.Tag.ALIAS, strToBytes(ASSET_ALIAS))
  return m
}

async function loadApiKeyAsset(): Promise<string> {
  try {
    const res = await asset.query(apiKeyAliasMap())
    if (res.length > 0) {
      const secret = res[0].get(asset.Tag.SECRET)
      if (secret !== undefined) {
        return bytesToStr(secret as Uint8Array)
      }
    }
  } catch (_e) {
    // 无密钥或读取失败
  }
  return ''
}

async function saveApiKeyAsset(key: string): Promise<void> {
  try {
    await asset.remove(apiKeyAliasMap())
  } catch (_e) {
    // 尚无旧密钥
  }
  if (key.length === 0) { return }
  const attr: asset.AssetMap = new Map<asset.Tag, asset.Value>()
  attr.set(asset.Tag.ALIAS, strToBytes(ASSET_ALIAS))
  attr.set(asset.Tag.SECRET, strToBytes(key))
  attr.set(asset.Tag.ACCESSIBILITY, asset.Accessibility.DEVICE_FIRST_UNLOCKED)
  await asset.add(attr)
}

let preferences: dataPreferences.Preferences | null = null

export async function initAIConfig(context: Context): Promise<void> {
  try {
    preferences = await dataPreferences.getPreferences(context, PREF_STORE)
  } catch (_e) {
    preferences = null
  }
}

export async function loadAIConfig(): Promise<AIConfig> {
  let provider = DEFAULT_AI_CONFIG.provider
  let apiKey = await loadApiKeyAsset()
  let model = DEFAULT_AI_CONFIG.model
  let baseUrl = ''
  if (preferences) {
    try {
      provider = await preferences.get(KEY_PROVIDER, DEFAULT_AI_CONFIG.provider) as string
      if (apiKey.length === 0) {
        // 旧版本明文密钥兼容迁移
        apiKey = await preferences.get(KEY_API_KEY, DEFAULT_AI_CONFIG.apiKey) as string
      }
      model = await preferences.get(KEY_MODEL, DEFAULT_AI_CONFIG.model) as string
      baseUrl = await preferences.get(KEY_BASE_URL, '') as string
    } catch (_e) {
      // 读取失败时使用默认值
    }
  }
  return { provider, apiKey, model, baseUrl: baseUrl || undefined }
}

export async function saveAIConfig(config: AIConfig): Promise<void> {
  // 优先写入系统 Asset Store（加密）；失败时降级为 Preferences，保证功能可用
  let assetSaved = false
  try {
    await saveApiKeyAsset(config.apiKey)
    assetSaved = true
  } catch (_e) {
    assetSaved = false
  }
  if (!preferences) {
    return
  }
  try {
    await preferences.put(KEY_PROVIDER, config.provider)
    await preferences.put(KEY_MODEL, config.model)
    await preferences.put(KEY_BASE_URL, config.baseUrl || '')
    if (assetSaved) {
      // 加密存储成功后清理旧版本明文，避免“删除密钥后又被旧明文复活”
      await preferences.delete(KEY_API_KEY)
    } else {
      // 降级存储：与旧版本行为一致
      await preferences.put(KEY_API_KEY, config.apiKey)
    }
    await preferences.flush()
  } catch (_e) {
    // Persistence failed; config stays in memory for the session
  }
}

export async function loadLateZiHuanRi(): Promise<boolean> {
  if (!preferences) {
    return false
  }
  try {
    return await preferences.get(KEY_LATE_ZI, false) as boolean
  } catch (_e) {
    return false
  }
}

export async function saveLateZiHuanRi(v: boolean): Promise<void> {
  if (!preferences) {
    return
  }
  try {
    await preferences.put(KEY_LATE_ZI, v)
    await preferences.flush()
  } catch (_e) {
    // 持久化失败，保持会话内值
  }
}

export async function loadDarkMode(): Promise<boolean> {
  if (!preferences) {
    return false
  }
  try {
    return await preferences.get(KEY_DARK_MODE, false) as boolean
  } catch (_e) {
    return false
  }
}

export async function saveDarkMode(dark: boolean): Promise<void> {
  if (!preferences) {
    return
  }
  try {
    await preferences.put(KEY_DARK_MODE, dark)
    await preferences.flush()
  } catch (_e) {
    // Persistence failed; keep current session value
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
  if (typeof val === 'string') return val
  return String(val)
}

// Truncate response body for error messages (avoid leaking huge HTML pages)
function truncateBody(s: string, max: number): string {
  if (s.length <= max) return s
  return s.substring(0, max) + '...'
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

  // Trim long conversations: keep the initial context prompt, then the most recent turns
  const MAX_MESSAGES = 12
  if (messages.length > MAX_MESSAGES) {
    messages = [messages[0], ...messages.slice(-(MAX_MESSAGES - 1))]
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
    if (response.responseCode === 404) {
      return 'API 接口地址未找到 (404)。请检查 Base URL 配置。'
    }
    const bodySnippet = truncateBody(response.result as string, 200)
    return 'API 请求失败 (HTTP ' + response.responseCode + ')。响应：' + bodySnippet
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
      const body400 = truncateBody(response.result as string, 200)
      return 'Gemini API 请求参数错误。请检查模型名称是否正确。响应：' + body400
    }
    if (response.responseCode === 403) {
      return 'Gemini API 密钥无效或权限不足。请检查设置。'
    }
    if (response.responseCode === 429) {
      return 'Gemini API 调用频率超限，请稍后重试。'
    }
    const bodySnippet = truncateBody(response.result as string, 200)
    return 'Gemini API 请求失败 (HTTP ' + response.responseCode + ')。响应：' + bodySnippet
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
