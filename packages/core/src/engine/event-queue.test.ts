import { describe, it, expect } from 'vitest'
import { EventQueue, EventType } from './event-queue'

describe('EventQueue', () => {
  it('should enqueue and dequeue events in time order', () => {
    const queue = new EventQueue()
    queue.enqueue({ time: 10, type: EventType.LotArrival, entityId: 'L1' })
    queue.enqueue({ time: 5, type: EventType.EquipmentReady, entityId: 'E1' })
    queue.enqueue({ time: 15, type: EventType.ProcessComplete, entityId: 'L1' })

    const first = queue.dequeue()
    expect(first?.time).toBe(5)
    const second = queue.dequeue()
    expect(second?.time).toBe(10)
    const third = queue.dequeue()
    expect(third?.time).toBe(15)
  })

  it('should peek without removing', () => {
    const queue = new EventQueue()
    queue.enqueue({ time: 5, type: EventType.LotArrival, entityId: 'L1' })

    const peeked = queue.peek()
    expect(peeked?.time).toBe(5)
    expect(queue.length).toBe(1)

    const dequeued = queue.dequeue()
    expect(dequeued?.time).toBe(5)
    expect(queue.length).toBe(0)
  })

  it('should return undefined when dequeuing from empty queue', () => {
    const queue = new EventQueue()
    expect(queue.dequeue()).toBeUndefined()
  })

  it('should report isEmpty correctly', () => {
    const queue = new EventQueue()
    expect(queue.isEmpty()).toBe(true)
    queue.enqueue({ time: 1, type: EventType.LotArrival, entityId: 'L1' })
    expect(queue.isEmpty()).toBe(false)
    queue.dequeue()
    expect(queue.isEmpty()).toBe(true)
  })

  it('should track length', () => {
    const queue = new EventQueue()
    expect(queue.length).toBe(0)
    queue.enqueue({ time: 1, type: EventType.LotArrival, entityId: 'L1' })
    expect(queue.length).toBe(1)
    queue.enqueue({ time: 2, type: EventType.EquipmentReady, entityId: 'E1' })
    expect(queue.length).toBe(2)
    queue.dequeue()
    expect(queue.length).toBe(1)
  })

  it('should clear all events', () => {
    const queue = new EventQueue()
    queue.enqueue({ time: 1, type: EventType.LotArrival, entityId: 'L1' })
    queue.enqueue({ time: 2, type: EventType.EquipmentReady, entityId: 'E1' })
    queue.clear()
    expect(queue.isEmpty()).toBe(true)
    expect(queue.length).toBe(0)
    expect(queue.peek()).toBeUndefined()
  })

  it('should handle events with same time (FIFO stable)', () => {
    const queue = new EventQueue()
    queue.enqueue({ time: 5, type: EventType.LotArrival, entityId: 'L1' })
    queue.enqueue({ time: 5, type: EventType.EquipmentReady, entityId: 'E1' })

    const first = queue.dequeue()
    expect(first?.entityId).toBe('L1')
    const second = queue.dequeue()
    expect(second?.entityId).toBe('E1')
  })

  it('should handle interleaved enqueue and dequeue', () => {
    const queue = new EventQueue()
    queue.enqueue({ time: 10, type: EventType.LotArrival, entityId: 'L1' })
    queue.enqueue({ time: 5, type: EventType.EquipmentReady, entityId: 'E1' })

    expect(queue.dequeue()?.time).toBe(5)

    queue.enqueue({ time: 3, type: EventType.ProcessComplete, entityId: 'L1' })
    expect(queue.dequeue()?.time).toBe(3)
    expect(queue.dequeue()?.time).toBe(10)
    expect(queue.dequeue()).toBeUndefined()
  })
})
