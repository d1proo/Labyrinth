//
//  MotionManager.swift
//  Labyrinth
//
//  Created by Дмитрий Прохоренко on 22.12.2025.
//

import CoreMotion
import Combine

class MotionManager: ObservableObject {
	private let motionManager = CMMotionManager()
	@Published var x: CGFloat = 0.0
	@Published var y: CGFloat = 0.0
	
	private var calibrationX: CGFloat = 0.0
	private var calibrationY: CGFloat = 0.0
	private var isFirstReading = true
	
	private let maxSpeed: CGFloat = 6.0
	private let smoothFactor: CGFloat = 0.5
	
	init() {
		startMonitoring()
	}
	
	func startMonitoring() {
		guard motionManager.isDeviceMotionAvailable else { return }
		motionManager.deviceMotionUpdateInterval = 1/60
		
		motionManager.startDeviceMotionUpdates(to: .main) { [weak self] data, _ in
			guard let self = self, let data = data else { return }
			
			DispatchQueue.main.async {
				let rawX = CGFloat(data.gravity.x)
				let rawY = -CGFloat(data.gravity.y)
				
				// Калибровка при первом чтении
				if self.isFirstReading {
					self.calibrationX = rawX
					self.calibrationY = rawY
					self.isFirstReading = false
				}
				
				// Применяем калибровку
				let calibratedX = rawX - self.calibrationX
				let calibratedY = rawY - self.calibrationY
				
				// Простое умножение на максимальную скорость
				self.x = calibratedX * self.maxSpeed
				self.y = calibratedY * self.maxSpeed
				
				// Мертвая зона
				if abs(self.x) < 0.1 { self.x = 0 }
				if abs(self.y) < 0.1 { self.y = 0 }
			}
		}
	}
	
	func stopMonitoring() {
		motionManager.stopDeviceMotionUpdates()
		x = 0
		y = 0
		isFirstReading = true
	}
}
