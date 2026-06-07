import { describe, it, expect } from 'vitest'
import { LotStatus, EquipmentStatus, EquipmentType } from './index'

describe('LotStatus enum', () => {
  it('should have correct string values', () => {
    expect(LotStatus.Waiting).toBe('waiting')
    expect(LotStatus.Processing).toBe('processing')
    expect(LotStatus.Completed).toBe('completed')
    expect(LotStatus.OnHold).toBe('on_hold')
  })
})

describe('EquipmentStatus enum', () => {
  it('should include core production states', () => {
    expect(EquipmentStatus.Idle).toBe('idle')
    expect(EquipmentStatus.Processing).toBe('processing')
    expect(EquipmentStatus.Error).toBe('error')
  })
})

describe('EquipmentType enum', () => {
  it('should include all semiconductor equipment types', () => {
    const types = Object.values(EquipmentType)
    expect(types).toContain('lithography')
    expect(types).toContain('etching')
    expect(types).toContain('deposition')
    expect(types).toContain('inspection')
    expect(types.length).toBeGreaterThanOrEqual(5)
  })
})
