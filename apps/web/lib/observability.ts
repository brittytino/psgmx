type LogLevel = 'info' | 'warn' | 'error'

export function logEvent(level: LogLevel, event: string, fields: Record<string, unknown> = {}) {
  const entry = JSON.stringify({
    timestamp: new Date().toISOString(),
    level,
    event,
    service: 'psgmx-web',
    ...fields,
  })
  if (level === 'error') console.error(entry)
  else if (level === 'warn') console.warn(entry)
  else console.info(entry)
}

export function requestId(headers: Headers) {
  return headers.get('x-request-id') || crypto.randomUUID()
}
