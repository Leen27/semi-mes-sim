import { describe, it, expect, vi } from 'vitest'
import { SimulationEngine, type SimulationConfig } from './simulation-engine'
import { LotStatus, EquipmentStatus, EquipmentType } from '../models'

const mockConfig: SimulationConfig = {
  initialLots: [
    { id: 'L1', name: 'Lot-001', waferCount: 25, currentStepIndex: 0, routeId: 'R1', priority: 1, status: LotStatus.Waiting, createdAt: 0 },
    { id: 'L2', name: 'Lot-002', waferCount: 25, currentStepIndex: 0, routeId: 'R1', priority: 2, status: LotStatus.Waiting, createdAt: 0 }
  ],
  equipments: [
    { id: 'E1', name: '光刻机-01', type: EquipmentType.Lithography, status: EquipmentStatus.Idle, supportedRecipeIds: ['REC001'], position: { x: 0, y: 0, z: 0 }, throughput: 60 }
  ],
  routes: [
    {
      id: 'R1',
      name: '测试工艺',
      steps: [
        { id: 'S1', sequence: 1, name: '光刻', requiredEquipmentType: EquipmentType.Lithography, recipeId: 'REC001' }
      ]
    }
  ],
  initialSpeed: 1
}

describe('SimulationEngine lifecycle', () => {
  it('should initialize with correct default state', () => {
    const engine = new SimulationEngine(mockConfig)
    const state = engine.getState()

    expect(state.currentTime).toBe(0)
    expect(state.isRunning).toBe(false)
    expect(state.speed).toBe(1)
    expect(state.lots).toHaveLength(2)
    expect(state.equipments).toHaveLength(1)
  })

  it('should start and set isRunning to true', () => {
    const engine = new SimulationEngine(mockConfig)
    engine.start()
    expect(engine.getState().isRunning).toBe(true)
  })

  it('should not start twice', () => {
    const engine = new SimulationEngine(mockConfig)
    engine.start()
    engine.start()
    expect(engine.getState().isRunning).toBe(true)
  })

  it('should pause and set isRunning to false', () => {
    const engine = new SimulationEngine(mockConfig)
    engine.start()
    engine.pause()
    expect(engine.getState().isRunning).toBe(false)
  })

  it('should reset to initial state', () => {
    const engine = new SimulationEngine(mockConfig)
    engine.start()
    engine.tick(1)
    engine.setSpeed(5)
    engine.reset()

    const state = engine.getState()
    expect(state.currentTime).toBe(0)
    expect(state.isRunning).toBe(false)
    expect(state.speed).toBe(1)
    expect(state.lots[0].status).toBe(LotStatus.Waiting)
  })

  it('should advance time on tick when running', () => {
    const engine = new SimulationEngine(mockConfig)
    engine.start()
    engine.tick(2)
    expect(engine.getState().currentTime).toBe(2)
  })

  it('should not advance time on tick when paused', () => {
    const engine = new SimulationEngine(mockConfig)
    engine.start()
    engine.pause()
    engine.tick(2)
    expect(engine.getState().currentTime).toBe(0)
  })

  it('should apply speed multiplier', () => {
    const engine = new SimulationEngine(mockConfig)
    engine.start()
    engine.setSpeed(2)
    engine.tick(1)
    expect(engine.getState().currentTime).toBe(2)
  })

  it('should clamp speed to valid range', () => {
    const engine = new SimulationEngine(mockConfig)
    engine.setSpeed(0.01)
    expect(engine.getState().speed).toBe(0.1)
    engine.setSpeed(200)
    expect(engine.getState().speed).toBe(100)
  })

  it('should return false from tick when not running', () => {
    const engine = new SimulationEngine(mockConfig)
    const result = engine.tick(1)
    expect(result).toBe(false)
  })

  it('should invoke onTick callback', () => {
    const onTick = vi.fn()
    const engine = new SimulationEngine(mockConfig, { onTick })
    engine.start()
    engine.tick(1)
    expect(onTick).toHaveBeenCalled()
  })

  it('should invoke onEvent callback', () => {
    const onEvent = vi.fn()
    const engine = new SimulationEngine(mockConfig, { onEvent })
    engine.start()
    engine.tick(0.1)
    expect(onEvent).toHaveBeenCalled()
  })
})
