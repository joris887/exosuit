# Condition-Based Waiting

Replace arbitrary timeouts with condition polling. This eliminates race conditions and makes tests deterministic.

## The Problem

```javascript
// BAD: Guessing at timing — flaky on slow CI, wastes time on fast machines
await sleep(500);
expect(result).toBeDefined();
```

## The Solution

```javascript
// GOOD: Wait for the actual condition
await waitFor(() => expect(result).toBeDefined());
```

## Patterns by Language

### JavaScript/TypeScript
```javascript
// Using @testing-library
await waitFor(() => expect(screen.getByText('Done')).toBeVisible());

// Custom polling
async function waitFor(condition, timeout = 5000, interval = 50) {
  const start = Date.now();
  while (Date.now() - start < timeout) {
    try { condition(); return; } catch { await new Promise(r => setTimeout(r, interval)); }
  }
  condition(); // Final attempt — throws on failure
}
```

### Python
```python
# Using tenacity
from tenacity import retry, stop_after_delay, wait_fixed

@retry(stop=stop_after_delay(5), wait=wait_fixed(0.1))
def wait_for_result():
    assert get_result() is not None

# Manual polling
import time
def wait_for(condition, timeout=5, interval=0.05):
    deadline = time.time() + timeout
    while time.time() < deadline:
        if condition():
            return
        time.sleep(interval)
    assert condition(), "Condition not met within timeout"
```

## When to Use

- Async operations (API calls, database writes, file I/O)
- UI state changes (animations, lazy loading, transitions)
- Process startup (servers, workers, background jobs)
- Event-driven flows (message queues, webhooks)

## Benefits

- Tests pass on slow CI systems (no arbitrary timing assumptions)
- Tests run faster on fast machines (no unnecessary waiting)
- Tests are deterministic (condition is verified, not assumed)
