# Root Cause Tracing Technique

Trace BACKWARD from the symptom to the source. Do not guess forward.

## The Backward Trace

```
Symptom (error message, wrong output, crash)
  ↑ What function produced this output?
  ↑ What data was passed to that function?
  ↑ Where did that data come from?
  ↑ At which point did the data become incorrect?
  = ROOT CAUSE
```

## Steps

1. **Start at the symptom location** (file:line from stack trace)
2. **Read the failing code** — what does it expect? What did it get?
3. **Add instrumentation** if the data flow is unclear:
   ```
   console.log('DEBUG:', variable, typeof variable)
   ```
4. **Move one level up** — who called this function? With what arguments?
5. **Repeat** until you find where correct data becomes incorrect
6. **Remove instrumentation** after finding root cause

## Multi-Component Tracing

For bugs that cross component boundaries (API → database, frontend → backend):

1. Verify data is correct at the **source** component
2. Verify data is correct **after serialization** (JSON, protobuf)
3. Verify data is correct **after transmission** (check network response)
4. Verify data is correct **after deserialization** at the destination
5. The bug is at the boundary where data changes

## Git Bisect for Regressions

When "it used to work" but you don't know which commit broke it:

```bash
git bisect start
git bisect bad              # Current commit is broken
git bisect good <commit>    # Known working commit
# Git checks out a middle commit — test it
# Mark as good or bad, repeat until found
git bisect reset            # When done
```
