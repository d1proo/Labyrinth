//
//  ContentView.swift
//  Labyrinth
//
//  Created by Дмитрий Прохоренко on 22.12.2025.
//

import SwiftUI

struct LabyrinthGameView: View {
	@StateObject private var motion = MotionManager()
	@State private var ballPosition = CGPoint(x: 0, y: 0)
	@State private var showWinAlert = false
	@State private var showBoundaryAlert = false
	@State private var isGameActive = true
	@State private var countdown = 3 // Новое состояние для отсчета
	@State private var showCountdown = true // Показывать ли отсчет
	
	// Константы
	private let sensitivity: CGFloat = 1
	private let ballRadius: CGFloat = 20
	private let finishZone = CGRect(x: 150, y: 400, width: 100, height: 100)
	private let arrowMoveDistance: CGFloat = 5 // Расстояние перемещения по стрелкам
	
	// Стены лабиринта
	private let walls: [CGRect] = [
		CGRect(x: 160, y: 100, width: 10, height: 90),
		CGRect(x: 0, y: 130, width: 160, height: 10),
		CGRect(x: 230, y: 100, width: 10, height: 30),
		CGRect(x: 230, y: 130, width: 170, height: 10),
		CGRect(x: 20, y: 140, width: 10, height: 190),
		CGRect(x: 360, y: 140, width: 10, height: 190),
		CGRect(x: 230, y: 320, width: 140, height: 10),
		CGRect(x: 20, y: 320, width: 150, height: 10),
		CGRect(x: 230, y: 200, width: 80, height: 10),
		CGRect(x: 300, y: 210, width: 10, height: 110),
		CGRect(x: 90, y: 190, width: 10, height: 80),
		CGRect(x: 90, y: 270, width: 150, height: 10),
		CGRect(x: 130, y: 280, width: 10, height: 40)
	]
	
	var body: some View {
		GeometryReader { geometry in
			let screenWidth = geometry.size.width
			
			ZStack {
				// Фон лабиринта
				Color.black.ignoresSafeArea()
				
				// Стены лабиринта
				ForEach(walls.indices, id: \.self) { index in
					let wall = walls[index]
					Rectangle()
						.fill(Color.gray)
						.frame(width: wall.width, height: wall.height)
						.position(x: wall.midX, y: wall.midY)
				}
				
				// Финишная зона
				Rectangle()
					.fill(Color.green.opacity(0.5))
					.frame(width: finishZone.width, height: finishZone.height)
					.overlay(
						Text("Финиш")
							.font(.system(size: 21, weight: .heavy, design: .rounded))
							.foregroundColor(.white)
					)
				
				// Шарик
				Circle()
					.fill(RadialGradient(
						gradient: Gradient(colors: [.white, .green]),
						center: .center,
						startRadius: 0,
						endRadius: ballRadius
					))
					.frame(width: ballRadius * 2, height: ballRadius * 2)
					.position(ballPosition)
					.opacity(showCountdown ? 0.3 : 1.0) // Делаем шарик полупрозрачным во время отсчета
				
				// Отсчет на весь экран
				if showCountdown {
					Color.black.opacity(0.7)
						.ignoresSafeArea()
						.overlay(
							Text("\(countdown)")
								.font(.system(size: 150, weight: .bold, design: .rounded))
								.foregroundColor(.white.opacity(0.8))
								.shadow(color: .green, radius: 20)
						)
				}
			}
			.onAppear {
				// Стартовая позиция шарика
				ballPosition = CGPoint(x: screenWidth / 2, y: ballRadius + 50)
				
				// Запускаем отсчет
				startCountdown()
			}
			.onChange(of: motion.x) { _, _ in
				if !showCountdown { // Обновляем позицию только когда отсчет закончен
					DispatchQueue.main.async {
						updatePosition(screenSize: geometry.size)
					}
				}
			}
			.onChange(of: motion.y) { _, _ in
				if !showCountdown {
					DispatchQueue.main.async {
						updatePosition(screenSize: geometry.size)
					}
				}
			}
			.alert("Победа! 🎉", isPresented: $showWinAlert) {
				Button("Играть снова", action: resetGame)
			} message: {
				Text("Вы успешно прошли лабиринт!")
			}
		}
	}
	
	private func startCountdown() {
		// Запускаем таймер отсчета
		Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
			if countdown > 1 {
				countdown -= 1
			} else {
				// Отсчет закончен
				timer.invalidate()
				showCountdown = false
				motion.startMonitoring() // Запускаем датчики только после отсчета
			}
		}
	}
	
	private func updatePosition(screenSize: CGSize) {
		guard isGameActive && !showCountdown else { return }
		
		let newX = ballPosition.x + motion.x * sensitivity
		let newY = ballPosition.y + motion.y * sensitivity
		
		// Прямоугольник шарика
		let ballRect = CGRect(
			x: newX - ballRadius * 0.8,
			y: newY - ballRadius * 0.8,
			width: ballRadius * 1.6,
			height: ballRadius * 1.6
		)
		
		// Ищем столкновения
		var finalX = newX
		var finalY = newY
		
		for wall in walls {
			if ballRect.intersects(wall) {
				// Определяем тип стены по соотношению сторон
				if wall.width > wall.height {
					// Горизонтальная стена - разрешаем движение по X
					finalY = ballPosition.y // Блокируем Y
				} else {
					// Вертикальная стена - разрешаем движение по Y
					finalX = ballPosition.x // Блокируем X
				}
			}
		}
		
		// Проверяем границы экрана
		let boundary = CGRect(x: ballRadius,
							  y: ballRadius,
							  width: screenSize.width - ballRadius * 2,
							  height: screenSize.height - ballRadius * 2)
		
		if finalX < boundary.minX || finalX > boundary.maxX {
			finalX = ballPosition.x
		}
		if finalY < boundary.minY || finalY > boundary.maxY {
			finalY = ballPosition.y
		}
		
		// Обновляем позицию
		ballPosition = CGPoint(x: finalX, y: finalY)
		
		// Проверка достижения финиша
		let finalBallRect = CGRect(
			x: ballPosition.x - ballRadius,
			y: ballPosition.y - ballRadius,
			width: ballRadius * 2,
			height: ballRadius * 2
		)
		
		if finalBallRect.intersects(finishZone) {
			isGameActive = false
			showWinAlert = true
			motion.stopMonitoring()
		}
	}
	
	private func resetGame() {
		isGameActive = true
		countdown = 3
		showCountdown = true
		ballPosition = CGPoint(x: UIScreen.main.bounds.width / 2, y: ballRadius + 50)
		startCountdown()
	}
}
