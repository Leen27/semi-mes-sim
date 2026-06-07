# SOP：会话开始与结束

## 目标

确保每轮会话都有明确的起点和终点，状态在会话之间可追踪、可恢复。

## Clock In（会话开始）

### 前置条件

- 当前目录是仓库根目录（运行 `pwd` 确认）
- Git 工作区相对干净（没有未提交的半成品修改）

### 执行步骤

1. **读取持久化状态文件**
   ```bash
   cat PROGRESS.md | head -30      # 了解当前进度和下一步
   cat feature_list.json | head -40 # 确认活跃功能和 VCR
   ```

2. **读取会话交接文件**
   ```bash
   cat SESSION_HANDOFF.md          # 如果有，了解上一轮总结
   ```

3. **读取最新的 Task Trace**
   ```bash
   ls -t .harness/traces/*.json | head -1 | xargs cat
   ```

4. **运行基础验证**
   ```bash
   make check                      # lint + type-check + test
   ```
   - 如果失败：停止新功能工作，先修复基础状态
   - 如果通过：继续下一步

5. **确认当前 active feature**
   - 检查 `feature_list.json` 中的 `activeFeatureId`
   - 如果存在 active 任务：继续完成它
   - 如果没有 active 任务：按 WIP=1 规则选取下一个 `not_started` 任务

6. **初始化本轮 Task Trace**
   ```bash
   TRACE_FILE=$(bash scripts/harness-trace.sh init <feature-id>)
   export TRACE_FILE
   ```

### 完成标准

- [ ] 已读取 PROGRESS.md、feature_list.json、SESSION_HANDOFF.md（如有）
- [ ] make check 通过
- [ ] 已确认当前要处理的功能 ID
- [ ] Task Trace 已初始化

---

## Clock Out（会话结束）

### 前置条件

- 当前功能已达到可提交的状态（或已明确记录为 blocked）
- 没有未完成的编译或测试

### 执行步骤

1. **运行幂等清理**
   ```bash
   bash scripts/session-cleanup.sh
   ```

2. **运行会话退出检查**
   ```bash
   bash scripts/session-exit-check.sh <feature-id>
   ```
   - 确认五维度全部通过（允许非关键 warning）

3. **更新功能状态**
   - 更新 `feature_list.json`：状态、证据、activeFeatureId
   - 更新 `PROGRESS.md`：进度、VCR、已知问题、下一步
   - 更新 `docs/quality.md`：如有模块质量变化

4. **更新技术债**
   - 如有新发现的债务，追加到 `docs/TECH_DEBT.md`
   - 如有已解决的债务，在 TECH_DEBT.md 中标记为已关闭

5. **Finalize Task Trace**
   ```bash
   bash scripts/harness-trace.sh finalize
   ```

6. **更新会话交接文件**
   - 更新 `SESSION_HANDOFF.md` 的"当前已验证"、"本轮改动"、"下一步最佳动作"

7. **原子提交**
   ```bash
   git add -A
   git commit -m "<type>: <feature-id> — <做了什么 + 为什么>"
   ```

### 完成标准

- [ ] session-cleanup.sh 已运行
- [ ] session-exit-check.sh 通过
- [ ] feature_list.json 已更新
- [ ] PROGRESS.md 已更新
- [ ] Task Trace 已 finalize
- [ ] SESSION_HANDOFF.md 已更新
- [ ] 所有变更已原子提交

---

## 常见问题

**Q: 会话被迫中断（上下文耗尽、意外退出）怎么办？**

A: 下次 Clock In 时，先读取最新的 Task Trace 文件重建状态。trace 文件包含所有已执行的验证步骤和结果，是恢复上下文的第一手资料。

**Q: 一个功能跨了多轮会话怎么办？**

A: 每轮结束时保持功能状态为 `active`，更新 `PROGRESS.md` 记录本轮完成的部分。不要拆成多个功能 ID。

**Q: 发现当前功能有 blocker 无法继续怎么办？**

A: 在 feature_list.json 中将状态改为 `blocked`，在 PROGRESS.md 中详细记录 blocker 原因和解除条件。然后按 WIP=1 规则选取下一个可执行的功能。
