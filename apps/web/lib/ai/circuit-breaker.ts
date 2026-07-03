/**
 * Circuit Breaker — TypeScript port of the Python CircuitBreaker class.
 * 
 * States:
 *   CLOSED    → Claude is healthy. All traffic goes to Claude.
 *   OPEN      → Too many consecutive failures. All traffic goes to Gemini.
 *   HALF_OPEN → Recovery probe: send one request to Claude.
 *               Success → back to CLOSED.
 *               Failure → reset timer, stay OPEN.
 */

export enum CBState {
  CLOSED    = 'CLOSED',
  OPEN      = 'OPEN',
  HALF_OPEN = 'HALF_OPEN',
}

export class CircuitBreaker {
  private _state        = CBState.CLOSED;
  private _failureCount = 0;
  private _openedAt: number | null = null;

  constructor(
    private readonly failureThreshold  = Number(process.env.CB_FAILURE_THRESHOLD    || 3),
    private readonly recoveryTimeoutMs = Number(process.env.CB_RECOVERY_TIMEOUT_SEC || 60) * 1000,
  ) {}

  get state(): CBState {
    if (this._state === CBState.OPEN && this._openedAt !== null) {
      if (Date.now() - this._openedAt >= this.recoveryTimeoutMs) {
        this._state = CBState.HALF_OPEN;
      }
    }
    return this._state;
  }

  recordSuccess(): void {
    this._state        = CBState.CLOSED;
    this._failureCount = 0;
    this._openedAt     = null;
  }

  recordFailure(): void {
    this._failureCount++;
    if (this._failureCount >= this.failureThreshold || this._state === CBState.HALF_OPEN) {
      this._state    = CBState.OPEN;
      this._openedAt = Date.now();
    }
  }

  asDict() {
    return {
      state:               this.state,
      failure_count:       this._failureCount,
      failure_threshold:   this.failureThreshold,
      recovery_timeout_sec: this.recoveryTimeoutMs / 1000,
    };
  }
}
