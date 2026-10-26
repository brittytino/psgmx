import fs from 'node:fs'
import path from 'node:path'
import { spawnSync, execSync } from 'node:child_process'

let cachedPythonPath: string | null = null

export function getPythonExecutable(): string | null {
  if (cachedPythonPath) return cachedPythonPath

  if (process.env.PYTHON_PATH && fs.existsSync(process.env.PYTHON_PATH)) {
    cachedPythonPath = process.env.PYTHON_PATH
    return cachedPythonPath
  }

  const candidates: string[] = []

  if (process.platform === 'win32') {
    // 1. Query where.exe python and filter out WindowsApps stubs
    try {
      const output = execSync('where.exe python', { encoding: 'utf-8', stdio: ['ignore', 'pipe', 'ignore'] })
      const lines = output.split(/\r?\n/).map(s => s.trim()).filter(Boolean)
      for (const line of lines) {
        if (!line.toLowerCase().includes('windowsapps')) {
          candidates.push(line)
        }
      }
    } catch {
      // ignore
    }

    // 2. Direct AppData paths
    const localApp = process.env.LOCALAPPDATA || ''
    if (localApp) {
      candidates.push(path.join(localApp, 'Python', 'bin', 'python.exe'))
      const programsPython = path.join(localApp, 'Programs', 'Python')
      if (fs.existsSync(programsPython)) {
        try {
          const dirs = fs.readdirSync(programsPython)
          for (const dir of dirs) {
            candidates.push(path.join(programsPython, dir, 'python.exe'))
          }
        } catch {
          // ignore
        }
      }
    }

    // 3. Common Windows drive root installs
    candidates.push(
      'C:\\Python314\\python.exe',
      'C:\\Python313\\python.exe',
      'C:\\Python312\\python.exe',
      'C:\\Python311\\python.exe',
      'C:\\Python310\\python.exe'
    )
  }

  // 4. POSIX / generic commands
  candidates.push('python3', 'python', 'py')

  for (const cand of candidates) {
    try {
      if (cand.includes(path.sep) && !fs.existsSync(cand)) continue
      const res = spawnSync(cand, ['--version'], {
        encoding: 'utf-8',
        timeout: 3000,
        stdio: ['ignore', 'pipe', 'pipe']
      })
      if (res.status === 0 && !res.stderr?.toLowerCase().includes('microsoft store')) {
        cachedPythonPath = cand
        return cand
      }
    } catch {
      // try next
    }
  }

  return null
}

export function executeLocal(
  language: string,
  code: string,
  stdin: string,
  timeoutMs: number = 6000
): { stdout: string; stderr: string; code: number; signal: string | null } | null {
  const lang = language.toLowerCase()

  if (lang === 'python' || lang === 'py') {
    const pythonCmd = getPythonExecutable()
    if (!pythonCmd) {
      return {
        stdout: '',
        stderr: 'Python runtime was not found on this system. Please check your Python environment.',
        code: 1,
        signal: null,
      }
    }

    try {
      const res = spawnSync(pythonCmd, ['-c', code], {
        input: stdin || '',
        encoding: 'utf-8',
        timeout: timeoutMs,
        maxBuffer: 512 * 1024,
      })

      if (res.error) {
        return {
          stdout: res.stdout || '',
          stderr: res.error.message || 'Execution timed out or failed.',
          code: 1,
          signal: res.signal ?? null,
        }
      }

      // Check if it hit the WindowsApps Microsoft Store stub
      if (res.status === 9009 || res.stderr?.toLowerCase().includes('microsoft store')) {
        // Cached path might be bad, reset and try direct scan
        cachedPythonPath = null
        return {
          stdout: '',
          stderr: 'Python configuration error: Windows App execution alias intercepted. Python path refreshed.',
          code: 1,
          signal: null,
        }
      }

      return {
        stdout: res.stdout || '',
        stderr: res.stderr || '',
        code: res.status ?? 0,
        signal: res.signal ?? null,
      }
    } catch (e: any) {
      return {
        stdout: '',
        stderr: e?.message || 'Local execution error.',
        code: 1,
        signal: null,
      }
    }
  }

  if (lang === 'javascript' || lang === 'js') {
    try {
      const res = spawnSync(process.execPath, ['-e', code], {
        input: stdin || '',
        encoding: 'utf-8',
        timeout: timeoutMs,
        maxBuffer: 512 * 1024,
      })

      if (res.error) {
        return {
          stdout: res.stdout || '',
          stderr: res.error.message || 'Execution timed out.',
          code: 1,
          signal: res.signal ?? null,
        }
      }

      return {
        stdout: res.stdout || '',
        stderr: res.stderr || '',
        code: res.status ?? 0,
        signal: res.signal ?? null,
      }
    } catch (e: any) {
      return {
        stdout: '',
        stderr: e?.message || 'Local execution error.',
        code: 1,
        signal: null,
      }
    }
  }

  return null
}
