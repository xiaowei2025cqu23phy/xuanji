import dataPreferences from '@ohos.data.preferences'

// ============================================================
// Reading history persistence service
// ============================================================
const PREF_NAME = 'saved_readings'
const KEY_BAZI = 'bazi_readings'
const KEY_ICHING = 'iching_readings'
const MAX_SAVED = 20

export interface SavedBaziReading {
  id: string
  timestamp: number
  date: string
  time: string
  gender: string
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
  } catch (_e) { store = null }
}

// ----- Bazi readings -----
export async function saveBaziReading(reading: SavedBaziReading): Promise<void> {
  if (!store) return
  try {
    const raw = await store.get(KEY_BAZI, '[]') as string
    const list: SavedBaziReading[] = JSON.parse(raw) as SavedBaziReading[]
    list.unshift(reading)
    if (list.length > MAX_SAVED) { list.length = MAX_SAVED }
    await store.put(KEY_BAZI, JSON.stringify(list))
    await store.flush()
  } catch (_e) { /* silent fail */ }
}

export async function loadBaziReadings(): Promise<SavedBaziReading[]> {
  if (!store) return []
  try {
    const raw = await store.get(KEY_BAZI, '[]') as string
    return JSON.parse(raw) as SavedBaziReading[]
  } catch (_e) { return [] }
}

export async function deleteBaziReading(id: string): Promise<void> {
  if (!store) return
  try {
    const raw = await store.get(KEY_BAZI, '[]') as string
    const list: SavedBaziReading[] = JSON.parse(raw) as SavedBaziReading[]
    const filtered = list.filter(r => r.id !== id)
    await store.put(KEY_BAZI, JSON.stringify(filtered))
    await store.flush()
  } catch (_e) { /* silent fail */ }
}

// ----- IChing readings -----
export async function saveIChingReading(reading: SavedIChingReading): Promise<void> {
  if (!store) return
  try {
    const raw = await store.get(KEY_ICHING, '[]') as string
    const list: SavedIChingReading[] = JSON.parse(raw) as SavedIChingReading[]
    list.unshift(reading)
    if (list.length > MAX_SAVED) { list.length = MAX_SAVED }
    await store.put(KEY_ICHING, JSON.stringify(list))
    await store.flush()
  } catch (_e) { /* silent fail */ }
}

export async function loadIChingReadings(): Promise<SavedIChingReading[]> {
  if (!store) return []
  try {
    const raw = await store.get(KEY_ICHING, '[]') as string
    return JSON.parse(raw) as SavedIChingReading[]
  } catch (_e) { return [] }
}

export async function deleteIChingReading(id: string): Promise<void> {
  if (!store) return
  try {
    const raw = await store.get(KEY_ICHING, '[]') as string
    const list: SavedIChingReading[] = JSON.parse(raw) as SavedIChingReading[]
    const filtered = list.filter(r => r.id !== id)
    await store.put(KEY_ICHING, JSON.stringify(filtered))
    await store.flush()
  } catch (_e) { /* silent fail */ }
}
