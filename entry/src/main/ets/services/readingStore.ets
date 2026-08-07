import dataPreferences from '@ohos.data.preferences'
import { hilog } from '@kit.PerformanceAnalysisKit'

// ============================================================
// Reading history persistence service
// ============================================================
const PREF_NAME = 'saved_readings'
const KEY_BAZI = 'bazi_readings'
const KEY_ICHING = 'iching_readings'
const MAX_SAVED = 20
const TAG = 'ReadingStore'

export interface SavedBaziReading {
  id: string
  timestamp: number
  date: string
  time: string
  gender: string
  useTrueSolar?: boolean
  longitude?: string
  yearPillar: string
  monthPillar: string
  dayPillar: string
  hourPillar: string
  dayMaster: string
  structure: string
  fiveElements: string  // JSON stringified
}

export interface SavedIChingReading {
  id: string
  timestamp: number
  method: string
  binary: string            // original hexagram binary (for restoring)
  moving: string            // JSON stringified moving indexes
  hexagramName: string
  hexagramSymbol: string
  hexagramNumber: number
  judgement: string
  changedName?: string
  changedSymbol?: string
  movingCount: number
  tiYongRelation: string
}

let store: dataPreferences.Preferences | null = null

export async function initReadingStore(context: Context): Promise<void> {
  try {
    store = await dataPreferences.getPreferences(context, PREF_NAME)
  } catch (e) {
    store = null
    hilog.error(0x0000, TAG, 'initReadingStore failed: %{public}s', (e as Object).toString())
  }
}

// ----- Safe JSON parse helper -----
function safeParseList<T>(raw: string): T[] {
  if (!raw || raw.length === 0) return []
  try {
    const parsed: T[] = JSON.parse(raw) as T[]
    if (Array.isArray(parsed)) {
      return parsed
    }
    hilog.warn(0x0000, TAG, 'Parsed data is not an array, returning empty list')
    return []
  } catch (e) {
    hilog.error(0x0000, TAG, 'JSON.parse failed, data may be corrupted: %{public}s', (e as Object).toString())
    return []
  }
}

// ----- Bazi readings -----
export async function saveBaziReading(reading: SavedBaziReading): Promise<boolean> {
  if (!store) return false
  try {
    const raw = await store.get(KEY_BAZI, '[]') as string
    const list: SavedBaziReading[] = safeParseList<SavedBaziReading>(raw)
    list.unshift(reading)
    if (list.length > MAX_SAVED) { list.length = MAX_SAVED }
    await store.put(KEY_BAZI, JSON.stringify(list))
    await store.flush()
    return true
  } catch (e) {
    hilog.error(0x0000, TAG, 'saveBaziReading failed: %{public}s', (e as Object).toString())
    return false
  }
}

export async function loadBaziReadings(): Promise<SavedBaziReading[]> {
  if (!store) return []
  try {
    const raw = await store.get(KEY_BAZI, '[]') as string
    return safeParseList<SavedBaziReading>(raw)
  } catch (e) {
    hilog.error(0x0000, TAG, 'loadBaziReadings failed: %{public}s', (e as Object).toString())
    return []
  }
}

export async function deleteBaziReading(id: string): Promise<boolean> {
  if (!store) return false
  try {
    const raw = await store.get(KEY_BAZI, '[]') as string
    const list: SavedBaziReading[] = safeParseList<SavedBaziReading>(raw)
    const filtered = list.filter((r: SavedBaziReading) => r.id !== id)
    await store.put(KEY_BAZI, JSON.stringify(filtered))
    await store.flush()
    return true
  } catch (e) {
    hilog.error(0x0000, TAG, 'deleteBaziReading failed: %{public}s', (e as Object).toString())
    return false
  }
}

// ----- IChing readings -----
export async function saveIChingReading(reading: SavedIChingReading): Promise<boolean> {
  if (!store) return false
  try {
    const raw = await store.get(KEY_ICHING, '[]') as string
    const list: SavedIChingReading[] = safeParseList<SavedIChingReading>(raw)
    list.unshift(reading)
    if (list.length > MAX_SAVED) { list.length = MAX_SAVED }
    await store.put(KEY_ICHING, JSON.stringify(list))
    await store.flush()
    return true
  } catch (e) {
    hilog.error(0x0000, TAG, 'saveIChingReading failed: %{public}s', (e as Object).toString())
    return false
  }
}

export async function loadIChingReadings(): Promise<SavedIChingReading[]> {
  if (!store) return []
  try {
    const raw = await store.get(KEY_ICHING, '[]') as string
    return safeParseList<SavedIChingReading>(raw)
  } catch (e) {
    hilog.error(0x0000, TAG, 'loadIChingReadings failed: %{public}s', (e as Object).toString())
    return []
  }
}

export async function deleteIChingReading(id: string): Promise<boolean> {
  if (!store) return false
  try {
    const raw = await store.get(KEY_ICHING, '[]') as string
    const list: SavedIChingReading[] = safeParseList<SavedIChingReading>(raw)
    const filtered = list.filter((r: SavedIChingReading) => r.id !== id)
    await store.put(KEY_ICHING, JSON.stringify(filtered))
    await store.flush()
    return true
  } catch (e) {
    hilog.error(0x0000, TAG, 'deleteIChingReading failed: %{public}s', (e as Object).toString())
    return false
  }
}

// ----- Export all records as JSON (for backup / migration) -----
export async function exportAllReadings(): Promise<string> {
  const bazi = await loadBaziReadings()
  const iching = await loadIChingReadings()
  const backup: ReadingsBackup = {
    version: 1,
    exportDate: new Date().toISOString(),
    baziReadings: bazi,
    ichingReadings: iching
  }
  return JSON.stringify(backup, null, 2)
}

export interface ReadingsBackup {
  version: number
  exportDate: string
  baziReadings: SavedBaziReading[]
  ichingReadings: SavedIChingReading[]
}
