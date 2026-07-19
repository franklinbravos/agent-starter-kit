---
shortDescription: File-based FIFO message queue for deferring user input during mid-task dispatch.
usedBy: [maestro]
version: 0.1.0
lastUpdated: 2026-07-19
---

## Purpose

The Maestro is the sole user interface. When it dispatches a sub-agent (step 5), it blocks waiting for the sub-agent to complete. The host runtime accepts user input during this wait — new messages land in the same conversation context and are processed immediately when the dispatch returns, causing context confusion, task corruption, and dropped work. This skill defines a file-based FIFO queue that defers non-urgent messages until the current task completes, and handles urgent `/force` commands by pausing the current task.

**Assumption:** Only one Maestro instance runs at a time. The queue uses file-based locking (`.memory/queue/.mid-task` semaphore) that assumes single-instance access. Concurrent instances would race on the `.seq` counter and `.mid-task` semaphore.

## Terminology

- **Mid-task:** The Maestro has dispatched a sub-agent and is waiting for its return. Indicated by the existence of `.memory/queue/.mid-task`.
- **Queue entry:** A file in `.memory/queue/` named `<ts>-<NNNN>.md` where `<ts>` is a timestamp (`YYYY-MM-DD-HH-MM-SS`) and `<NNNN>` is a zero-padded monotonic sequence number. The filename ensures FIFO ordering by chronological sort.
- **Force command:** A user message that equals `/force` after trimming whitespace. It bypasses the queue and pauses the current task for immediate handling.

## Procedure

### Queue directory

Ensure the queue directory exists on every boot:

```bash
mkdir -p .memory/queue
```

### Operations

1. **Check mid-task status.** Determine whether a sub-agent is currently dispatched by checking for the mid-task semaphore:

   ```bash
   test -f .memory/queue/.mid-task && echo "true" || echo "false"
   ```

2. **Mark mid-task.** Create the mid-task semaphore with a timestamp before dispatching a sub-agent:

   ```bash
   date +%s > .memory/queue/.mid-task
   ```

3. **Clear mid-task.** Delete the mid-task semaphore after the sub-agent returns and delivery is complete:

   ```bash
   rm -f .memory/queue/.mid-task
   ```

4. **Enqueue a message.** Save a user message for later processing. Uses a monotonic counter (`.memory/queue/.seq`) for collation-resistant naming — messages are never lost due to same-timestamp filename collisions:

   ```bash
   seq=$(($(cat .memory/queue/.seq 2>/dev/null || echo 0) + 1))
   echo "$seq" > .memory/queue/.seq
   ts=$(date '+%Y-%m-%d-%H-%M-%S')
   filename=".memory/queue/$ts-$(printf '%04d' $seq).md"
   printf '%s' "$message" > "$filename"
   if [ $? -ne 0 ]; then echo "ERROR: write failed"; rm -f "$filename"; fi
   echo "$filename"
   ```

   Set `message` to the exact user message text before running. The command outputs the created filename.

5. **Dequeue the oldest message.** Read and remove the earliest queue entry (by filename sort). Returns the message content if a file existed, or nothing if the queue is empty:

   ```bash
   oldest=$(ls -1 .memory/queue/*.md 2>/dev/null | sort | head -1)
   if [ -n "$oldest" ]; then
     cat "$oldest"
     rm "$oldest"
   fi
   ```

6. **List queue files.** List all pending queue entries sorted by filename (oldest first):

   ```bash
   ls -1 .memory/queue/*.md 2>/dev/null | sort
   ```

7. **Count queue length.** Count the number of pending queue entries:

   ```bash
   ls -1 .memory/queue/*.md 2>/dev/null | wc -l
   ```

8. **Check for force command.** Determine whether a message is an urgent `/force` command. Only an exact match after whitespace trimming qualifies:

   ```bash
   trimmed=$(printf '%s\n' "<message>" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
   if [ "$trimmed" = "/force" ]; then echo "true"; else echo "false"; fi
   ```

   Replace `<message>` with the raw user message text.

9. **Pause the current session.** Set a session's status to `paused` so it can be resumed later. This is used when a `/force` command interrupts mid-task work:

   ```bash
   if [ -f ".memory/session/<slug>.md" ]; then
     sed -i -E '/^## Status$/,/^[a-z]/s/^(in-progress|done)$/paused/' ".memory/session/<slug>.md"
     echo "Session <slug> paused."
   else
     echo "No active session <slug> — no action taken."
   fi
   ```

   Replace `<slug>` with the session slug (e.g., `refactor-auth-module`).

## Guardrails

- **Single-instance assumption.** The queue assumes exactly one Maestro instance. The `.seq` monotonic counter and `.mid-task` semaphore are not safe under concurrent instance access. If multiple Maestros run simultaneously, queue operations may race. This is by design — the framework targets single-user sessions.
- Never create a queue entry without first checking `checkMidTask()`. Enqueuing when not mid-task risks message ordering violations.
- Never call `markMidTask()` twice without an intervening `clearMidTask()`. The second call overwrites the timestamp but does not change behavior — the marker still exists. However, if the first dispatch's `clearMidTask()` is skipped, the marker remains and blocks all future processing.
- After `clearMidTask()`, always run `dequeueOldest()` before ending the turn to ensure queued messages are not forgotten.
- Queue files are plain text. Never store sensitive data (credentials, tokens, secrets) in queue entries.
- The sequence counter `.memory/queue/.seq` must never be manually edited. If corrupted (non-numeric content), the next `enqueueMessage` resets to `1`.
- The `.mid-task` marker is an empty file with a timestamp. Never modify its content manually.

## Acceptance Criteria

1. `.memory/queue/` directory is created during boot sequence.
2. `checkMidTask` returns `true` when `.memory/queue/.mid-task` exists, `false` otherwise.
3. `markMidTask` creates `.memory/queue/.mid-task` with a timestamp.
4. `clearMidTask` deletes `.memory/queue/.mid-task`.
5. `enqueueMessage "test message"` creates a file in `.memory/queue/` with content `test message`.
6. `dequeueOldest` returns the oldest message content and deletes the file.
7. `isForceCommand "/force"` returns `true`; `isForceCommand "regular message"` returns `false`.
8. `queueLength` returns the correct count of pending queue files.
9. Maestro playbook step 0 executes queue check before any other step.
10. Queue events appear in session memory log with `[maestro]` actor.

## Verification (Manual Test Commands)

Run these from the project root to verify queue operations work:

```bash
# Setup
mkdir -p .memory/queue

# checkMidTask — false when absent
test -f .memory/queue/.mid-task && echo "FAIL: .mid-task exists" || echo "PASS: checkMidTask false"

# markMidTask
date +%s > .memory/queue/.mid-task

# checkMidTask — true when present
test -f .memory/queue/.mid-task && echo "PASS: checkMidTask true" || echo "FAIL: .mid-task missing"

# enqueueMessage
seq=$(($(cat .memory/queue/.seq 2>/dev/null || echo 0) + 1))
echo "$seq" > .memory/queue/.seq
ts=$(date '+%Y-%m-%d-%H-%M-%S')
filename=".memory/queue/$ts-$(printf '%04d' $seq).md"
echo "hello" > "$filename"
test -f "$filename" && echo "PASS: enqueueMessage" || echo "FAIL: enqueueMessage"

# queueLength
count=$(ls -1 .memory/queue/*.md 2>/dev/null | wc -l)
echo "Queue length: $count"

# dequeueOldest
oldest=$(ls -1 .memory/queue/*.md 2>/dev/null | sort | head -1)
if [ -n "$oldest" ]; then
  content=$(cat "$oldest")
  rm "$oldest"
  echo "Dequeued: $content"
  test -f "$oldest" && echo "FAIL: file still exists" || echo "PASS: file deleted"
fi

# isForceCommand
trimmed=$(echo "/force" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
if [ "$trimmed" = "/force" ]; then echo "PASS: /force detected"; else echo "FAIL: /force not detected"; fi

trimmed=$(echo "regular message" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
if [ "$trimmed" = "/force" ]; then echo "FAIL: regular detected as force"; else echo "PASS: regular not force"; fi

# Cleanup
rm -f .memory/queue/.mid-task
```

## Stress Tests

### Inversion

What happens when the queue is used in unexpected ways:

- **Enqueue when not mid-task.** Calling `enqueueMessage` without a preceding `markMidTask` creates a queue entry that will be picked up on the next turn start. The message is deferred for one full turn but is never lost. Behavior is safe — the message arrives one turn later than the user might expect.
- **Dequeue from empty queue.** `dequeueOldest` on an empty queue produces no output and exits with code 0. The Maestro should check `queueLength` before dequeuing, or handle empty output gracefully.
- **Multiple `/force` commands.** If the user sends two `/force` messages in succession, the first pauses the current session and starts fresh; the second finds no mid-task marker (already cleared) and processes normally. The first session remains paused, waiting for explicit resume.
- **Empty message enqueued.** `enqueueMessage ""` creates a file with zero bytes. The file is dequeued normally and returns an empty string. No crash, but the Maestro should treat an empty message as a no-op during sweep.

### Subtraction

What breaks when components are removed:

- **`.memory/queue/` missing.** If the queue directory does not exist, all `ls` commands return empty, `test -f` returns false, and `cat` inside `enqueueMessage` fails. The `mkdir -p .memory/queue` in the boot sequence prevents this in normal operation.
- **`.seq` counter missing.** If `.memory/queue/.seq` is deleted, the next `enqueueMessage` resets to `1` (the `cat ... || echo 0` fallback). Existing queue files with higher sequence numbers are unaffected. New files resume from `1` — chronological sort by timestamp still ensures FIFO ordering.
- **`.mid-task` deleted mid-dispatch.** If `.mid-task` is deleted while a sub-agent is running (e.g., manual cleanup), the Maestro's next turn start will not detect mid-task and will proceed to normal processing. The sub-agent's output may interleave with a new task. Recovery: the Maestro must rely on session state rather than the semaphore alone.
- **Queue file manually deleted.** If a queue file is deleted before it is dequeued, the message is lost. This is an edge case with no recovery — the message was never acked by the system.

### Weakest Link

The most failure-prone components in the queue:

- **Filesystem fill.** If the disk is full, `cat > "$filename"` inside `enqueueMessage` fails silently (the file is created empty or truncated). The `.seq` counter is already incremented, producing a sequence gap. Detection requires checking the exit code of the write.
- **Simultaneous writes (non-concurrent).** Since the queue assumes single-instance, two `enqueueMessage` calls in the same shell session without waiting for the first to finish could race on the `.seq` read-then-write. In practice, the Maestro runs sequentially — one operation per turn — so this race is theoretical.
- **Corrupted `.seq`.** If `.seq` contains non-numeric content (e.g., manual edit), the arithmetic expansion `$((cat ...))` fails. The fallback `|| echo 0` catches this and resets to `1`. Previous files retain their sequence numbers.
- **Fragile `sed` for pause.** The `pauseCurrentSession` command uses `sed -i` to replace the line after `## Status`. If the session file's structure deviates from the expected format (e.g., blank line after `## Status` instead of immediately on the next line), the replacement fails silently. The session remains `in-progress` and the `/force` command's pause intent is lost.

## Planned Commits

The following conventional commits represent the implementation boundary for Phase 1:

```
feat(message-queue): add queue skill with FIFO operations and mid-task semaphore

Adds `checkMidTask`, `markMidTask`, `clearMidTask`, `enqueueMessage`,
`dequeueOldest`, `listQueueFiles`, `queueLength`, `isForceCommand`,
`pauseCurrentSession`, `sweepQueue`. Includes collation-resistant naming
via monotonic `.seq` counter, stress tests, and verification commands.

feat(maestro): integrate queue check into playbook steps 0 and 8

Step 0 checks mid-task on every turn start. Step 5 creates `.mid-task`
before dispatch. Step 7 clears `.mid-task` after delivery. Step 8 sweeps
the queue for pending messages.

feat(boot): initialize .memory/queue directory during boot

Ensures the queue directory exists before any queue operation runs.

feat(agent-memory): log queue events in session memory

Adds queue event pattern to schema notes and a queue event example to
the session memory sample.
```
