//
//  ContentView.swift
//  A star algorithm
//
//  Created by cmStudent on 2025/09/10.
//

import SwiftUI

struct Point: Hashable {
    let x: Int
    let y: Int
}


class Map: ObservableObject{
    @Published var rows: Int
    @Published var cols: Int
    @Published var walls: Set<Point>
    @Published var start: Point = Point(x: 0, y: 0)
    @Published var goal: Point
    
    @Published var path: [Point] = []
    
    // Keeps track of where we came from:
    // cameFrom[point] = previousPoint
    // Used later to reconstruct the path once we reach the goal.
    @Published var cameFrom: [Point: Point] = [:]
    
    // gScore[point] = cost of the cheapest path found so far from start → point
    @Published var gScore: [Point: Float] = [Point(x: 0, y: 0) : 0]
    // Nodes to explore (the "open set"). Start from the start point.
    @Published var openSet: Set<Point> = [Point(x: 0, y: 0)]
    
    @Published var slowDownSec: Double = 1
    
    @Published var currentCheckPoint: Point? = nil
    
    init(rows: Int, cols: Int, walls: Set<Point>, goal: Point) {
        self.rows = rows
        self.cols = cols
        self.walls = walls
        self.goal = goal
    }
    
    
    @MainActor
    func findPath() async {
        path.removeAll()
        cameFrom.removeAll()
        gScore = [Point(x: 0, y: 0) : 0]
        openSet = [Point(x: 0, y: 0)]
       
        
        
        
       
        
        // fScore[point] = estimated total cost from start → point → goal
        // = gScore[point] + heuristic(point, goal)
        var fScore: [Point: Float] = [start: heuristic(from: start, to: goal)]
        
        // Helper: compare two points by their fScore values.
        let hasLowerFScore: (Point, Point) -> Bool = { p1, p2 in
            fScore[p1, default: Float.greatestFiniteMagnitude] < fScore[p2, default: Float.greatestFiniteMagnitude]
        }
        
        // Main A* loop
        while !openSet.isEmpty {
            try? await Task.sleep(for: .seconds(slowDownSec))

            // Pick the node in openSet with the lowest fScore
            currentCheckPoint = openSet.min(by: hasLowerFScore)
            guard let currentCheckPoint else {
                break // Should never happen since openSet is not empty, but safe guard.
            }
            

            if currentCheckPoint == goal {
                
                let resultPath = reconstructPath(cameFrom: cameFrom, current: currentCheckPoint)
                
                for p in resultPath {
                    try? await Task.sleep(for: .seconds(slowDownSec))
                    path.append(p)
                }
                return
            }
            
            // Mark this node as processed (remove from open set)
            openSet.remove(currentCheckPoint)
            
            // Check each neighbor (up, down, left, right, diagonals)
            for neighbor in neighbors(of: currentCheckPoint) {
                
                // Movement cost from current → neighbor
                // Diagonal moves cost √2, straight moves cost 1
                let dx = abs(neighbor.x - currentCheckPoint.x)
                let dy = abs(neighbor.y - currentCheckPoint.y)
                let isDiagonalMove = dx == 1 && dy == 1
                let moveCost: Float = isDiagonalMove ? sqrtf(2) : 1
                
                // Cost of cheapest path to current node
                let costForCurrentPoint = gScore[currentCheckPoint, default: Float.greatestFiniteMagnitude]
                
                // Tentative cost of reaching neighbor via current
                let tentativeGScore = costForCurrentPoint + moveCost
                
                // If we found a cheaper path to neighbor → update records
                if tentativeGScore < gScore[neighbor, default: Float.greatestFiniteMagnitude] {
                    cameFrom[neighbor] = currentCheckPoint
                    gScore[neighbor] = tentativeGScore
                    fScore[neighbor] = tentativeGScore + heuristic(from: neighbor, to: goal)
                    
                    // Add neighbor to open set (to be explored later)
                    openSet.insert(neighbor)
                }
            }
        }
    }

    
    private func reconstructPath(cameFrom: [Point: Point], current: Point) -> [Point] {
        var path = [current]
        var temp = current
        
        // Walk back through the cameFrom dictionary until we reach start
        while let prevPoint = cameFrom[temp] {
            path.append(prevPoint)
            temp = prevPoint
        }
        return path
//        return path.reversed() // Reverse to get start → goal
    }

    
    private func heuristic(from pointA: Point, to pointB: Point) -> Float {
        let dx = Float(pointA.x - pointB.x)
        let dy = Float(pointA.y - pointB.y)
        return sqrtf(dx * dx + dy * dy)
    }

    
    private func neighbors(of point: Point) -> [Point] {
        let directions = [(-1, 0), (1, 0), (0, -1), (0,1), (1 ,-1), (1, 1), (-1, -1), (-1, 1)] // up, down, left, right, diagonal
        
        return directions.compactMap { (directionX, directionY) in
            
            let newX = point.x + directionX
            let newY = point.y + directionY
            let newPoint = Point(x: newX, y: newY)
            
            if pointIsInMapAndNotHittingWalls(newPoint) {
                return newPoint
            }
            
            return nil
        }
    }
    
    
    private func pointIsInMapAndNotHittingWalls(_ point: Point) -> Bool {
        return point.x >= 0 && point.x < rows && point.y >= 0 && point.y < cols && !walls.contains(point)
    }
    
    
}

extension Map {
    func printGrid(path: [Point]? = nil) {
        for y in 0..<cols {
            var row = ""
            for x in 0..<rows {
                let p = Point(x: x, y: y)
                
                if p == start {
                    row += "S "   // Start
                } else if p == goal {
                    row += "G "   // Goal
                } else if walls.contains(p) {
                    row += "🟥 "   // Wall
                } else if let path = path, path.contains(p) {
                    row += "🟩 "   // Path
                } else {
                    row += ". "   // Empty cell
                }
            }
            print(row)
        }
        print("") // spacing after grid
    }
}


struct ContentView: View {
    @StateObject private var mapModel = Map(
        rows: 30,
        cols: 30,
        walls: Set<Point>([
            Point(x: 1, y: 9),
            Point(x: 7, y: 20),
            Point(x: 29, y: 24),
            Point(x: 14, y: 16),
            Point(x: 16, y: 23),
            Point(x: 5, y: 1),
            Point(x: 26, y: 28),
            Point(x: 21, y: 1),
            Point(x: 18, y: 1),
            Point(x: 22, y: 3),
            Point(x: 9, y: 5),
            Point(x: 22, y: 28),
            Point(x: 4, y: 21),
            Point(x: 17, y: 11),
            Point(x: 7, y: 25),
            Point(x: 9, y: 10),
            Point(x: 21, y: 11),
            Point(x: 21, y: 26),
            Point(x: 25, y: 22),
            Point(x: 12, y: 9),
            Point(x: 13, y: 15),
            Point(x: 26, y: 7),
            Point(x: 11, y: 10),
            Point(x: 27, y: 11),
            Point(x: 1, y: 24),
            Point(x: 17, y: 10),
            Point(x: 11, y: 6),
            Point(x: 25, y: 24),
            Point(x: 23, y: 15),
            Point(x: 10, y: 1),
            Point(x: 9, y: 17),
            Point(x: 11, y: 9),
            Point(x: 17, y: 28),
            Point(x: 4, y: 15),
            Point(x: 20, y: 11),
            Point(x: 27, y: 21),
            Point(x: 25, y: 26),
            Point(x: 1, y: 21),
            Point(x: 10, y: 5),
            Point(x: 25, y: 19),
            Point(x: 21, y: 28),
            Point(x: 25, y: 21),
            Point(x: 27, y: 12),
            Point(x: 10, y: 23),
            Point(x: 25, y: 23),
            Point(x: 28, y: 28),
            Point(x: 5, y: 4),
            Point(x: 12, y: 11),
            Point(x: 14, y: 9),
            Point(x: 12, y: 25),
            Point(x: 1, y: 19),
            Point(x: 13, y: 9),
            Point(x: 26, y: 1),
            Point(x: 17, y: 23),
            Point(x: 17, y: 13),
            Point(x: 5, y: 28),
            Point(x: 27, y: 16),
            Point(x: 10, y: 17),
            Point(x: 17, y: 15),
            Point(x: 18, y: 19),
            Point(x: 22, y: 21),
            Point(x: 27, y: 9),
            Point(x: 17, y: 3),
            Point(x: 4, y: 9),
            Point(x: 17, y: 6),
            Point(x: 9, y: 3),
            Point(x: 20, y: 9),
            Point(x: 9, y: 7),
            Point(x: 5, y: 14),
            Point(x: 13, y: 28),
            Point(x: 11, y: 11),
            Point(x: 12, y: 1),
            Point(x: 20, y: 28),
            Point(x: 12, y: 3),
            Point(x: 24, y: 1),
            Point(x: 11, y: 3),
            Point(x: 8, y: 15),
            Point(x: 4, y: 28),
            Point(x: 19, y: 19),
            Point(x: 8, y: 1),
            Point(x: 7, y: 9),
            Point(x: 25, y: 20),
            Point(x: 6, y: 3),
            Point(x: 9, y: 1),
            Point(x: 10, y: 13),
            Point(x: 14, y: 28),
            Point(x: 27, y: 13),
            Point(x: 17, y: 9),
            Point(x: 5, y: 21),
            Point(x: 17, y: 19),
            Point(x: 15, y: 20),
            Point(x: 12, y: 28),
            Point(x: 8, y: 4),
            Point(x: 9, y: 21),
            Point(x: 16, y: 1),
            Point(x: 12, y: 23),
            Point(x: 24, y: 11),
            Point(x: 3, y: 19),
            Point(x: 6, y: 4),
            Point(x: 8, y: 9),
            Point(x: 5, y: 25),
            Point(x: 21, y: 21),
            Point(x: 2, y: 9),
            Point(x: 13, y: 3),
            Point(x: 28, y: 9),
            Point(x: 23, y: 9),
            Point(x: 6, y: 21),
            Point(x: 3, y: 1),
            Point(x: 1, y: 7),
            Point(x: 19, y: 1),
            Point(x: 11, y: 15),
            Point(x: 25, y: 28),
            Point(x: 7, y: 21),
            Point(x: 20, y: 1),
            Point(x: 28, y: 21),
            Point(x: 15, y: 12),
            Point(x: 7, y: 4),
            Point(x: 13, y: 13),
            Point(x: 7, y: 19),
            Point(x: 6, y: 1),
            Point(x: 11, y: 14),
            Point(x: 15, y: 14),
            Point(x: 2, y: 28),
            Point(x: 22, y: 17),
            Point(x: 20, y: 15),
            Point(x: 20, y: 7),
            Point(x: 13, y: 25),
            Point(x: 13, y: 16),
            Point(x: 15, y: 26),
            Point(x: 28, y: 13),
            Point(x: 12, y: 15),
            Point(x: 10, y: 15),
            Point(x: 15, y: 1),
            Point(x: 19, y: 25),
            Point(x: 9, y: 9),
            Point(x: 3, y: 17),
            Point(x: 1, y: 14),
            Point(x: 23, y: 17),
            Point(x: 8, y: 3),
            Point(x: 1, y: 12),
            Point(x: 18, y: 21),
            Point(x: 11, y: 1),
            Point(x: 27, y: 28),
            Point(x: 17, y: 1),
            Point(x: 13, y: 23),
            Point(x: 29, y: 8),
            Point(x: 17, y: 14),
            Point(x: 14, y: 7),
            Point(x: 19, y: 7),
            Point(x: 11, y: 13),
            Point(x: 27, y: 26),
            Point(x: 27, y: 7),
            Point(x: 5, y: 19),
            Point(x: 20, y: 26),
            Point(x: 20, y: 13),
            Point(x: 19, y: 9),
            Point(x: 2, y: 21),
            Point(x: 21, y: 23),
            Point(x: 13, y: 1),
            Point(x: 9, y: 13),
            Point(x: 26, y: 15),
            Point(x: 7, y: 28),
            Point(x: 27, y: 5),
            Point(x: 5, y: 6),
            Point(x: 28, y: 17),
            Point(x: 28, y: 3),
            Point(x: 29, y: 25),
            Point(x: 26, y: 9),
            Point(x: 25, y: 15),
            Point(x: 24, y: 9),
            Point(x: 23, y: 18),
            Point(x: 6, y: 17),
            Point(x: 0, y: 3),
            Point(x: 17, y: 22),
            Point(x: 29, y: 7),
            Point(x: 25, y: 18),
            Point(x: 19, y: 3),
            Point(x: 2, y: 5),
            Point(x: 25, y: 4),
            Point(x: 11, y: 19),
            Point(x: 1, y: 13),
            Point(x: 19, y: 26),
            Point(x: 15, y: 28),
            Point(x: 25, y: 9),
            Point(x: 24, y: 28),
            Point(x: 15, y: 16),
            Point(x: 14, y: 3),
            Point(x: 10, y: 19),
            Point(x: 4, y: 17),
            Point(x: 13, y: 12),
            Point(x: 15, y: 25),
            Point(x: 16, y: 13),
            Point(x: 17, y: 7),
            Point(x: 12, y: 21),
            Point(x: 15, y: 23),
            Point(x: 21, y: 7),
            Point(x: 27, y: 15),
            Point(x: 8, y: 25),
            Point(x: 17, y: 16),
            Point(x: 10, y: 25),
            Point(x: 8, y: 17),
            Point(x: 26, y: 21),
            Point(x: 22, y: 26),
            Point(x: 16, y: 16),
            Point(x: 25, y: 6),
            Point(x: 21, y: 19),
            Point(x: 18, y: 3),
            Point(x: 12, y: 17),
            Point(x: 1, y: 11),
            Point(x: 26, y: 24),
            Point(x: 24, y: 21),
            Point(x: 18, y: 26),
            Point(x: 27, y: 17),
            Point(x: 5, y: 9),
            Point(x: 23, y: 26),
            Point(x: 1, y: 15),
            Point(x: 23, y: 5),
            Point(x: 21, y: 25),
            Point(x: 18, y: 28),
            Point(x: 11, y: 5),
            Point(x: 4, y: 11),
            Point(x: 9, y: 15),
            Point(x: 3, y: 25),
            Point(x: 1, y: 23),
            Point(x: 23, y: 28),
            Point(x: 28, y: 2),
            Point(x: 22, y: 11),
            Point(x: 9, y: 19),
            Point(x: 27, y: 1),
            Point(x: 1, y: 4),
            Point(x: 25, y: 3),
            Point(x: 3, y: 11),
            Point(x: 2, y: 1),
            Point(x: 25, y: 7),
            Point(x: 3, y: 21),
            Point(x: 17, y: 26),
            Point(x: 25, y: 5),
            Point(x: 11, y: 21),
            Point(x: 17, y: 21),
            Point(x: 18, y: 11),
            Point(x: 1, y: 20),
            Point(x: 26, y: 3),
            Point(x: 20, y: 4),
            Point(x: 23, y: 21),
            Point(x: 19, y: 11),
            Point(x: 7, y: 11),
            Point(x: 18, y: 23),
            Point(x: 9, y: 25),
            Point(x: 15, y: 11),
            Point(x: 3, y: 6),
            Point(x: 3, y: 5),
            Point(x: 29, y: 6),
            Point(x: 26, y: 13),
            Point(x: 5, y: 8),
            Point(x: 19, y: 28),
            Point(x: 5, y: 17),
            Point(x: 1, y: 8),
            Point(x: 7, y: 15),
            Point(x: 5, y: 15),
            Point(x: 0, y: 9),
            Point(x: 21, y: 17),
            Point(x: 4, y: 1),
            Point(x: 28, y: 1),
            Point(x: 28, y: 11),
            Point(x: 11, y: 28),
            Point(x: 9, y: 23),
            Point(x: 26, y: 17),
            Point(x: 18, y: 15),
            Point(x: 23, y: 6),
            Point(x: 23, y: 23),
            Point(x: 14, y: 23),
            Point(x: 11, y: 17),
            Point(x: 15, y: 3),
            Point(x: 25, y: 16),
            Point(x: 4, y: 26),
            Point(x: 21, y: 24),
            Point(x: 25, y: 13),
            Point(x: 23, y: 11),
            Point(x: 21, y: 18),
            Point(x: 15, y: 7),
            Point(x: 23, y: 7),
            Point(x: 7, y: 24),
            Point(x: 15, y: 17),
            Point(x: 23, y: 14),
            Point(x: 7, y: 23),
            Point(x: 6, y: 28),
            Point(x: 21, y: 9),
            Point(x: 28, y: 5),
            Point(x: 7, y: 7),
            Point(x: 19, y: 13),
            Point(x: 7, y: 17),
            Point(x: 11, y: 7),
            Point(x: 17, y: 18),
            Point(x: 19, y: 15),
            Point(x: 5, y: 26),
            Point(x: 21, y: 15),
            Point(x: 23, y: 3),
            Point(x: 18, y: 4),
            Point(x: 26, y: 19),
            Point(x: 6, y: 26),
            Point(x: 4, y: 25),
            Point(x: 18, y: 25),
            Point(x: 2, y: 26),
            Point(x: 15, y: 9),
            Point(x: 10, y: 3),
            Point(x: 22, y: 1),
            Point(x: 11, y: 23),
            Point(x: 29, y: 28),
            Point(x: 13, y: 21),
            Point(x: 24, y: 23),
            Point(x: 3, y: 28),
            Point(x: 1, y: 17),
            Point(x: 1, y: 26),
            Point(x: 25, y: 17),
            Point(x: 19, y: 20),
            Point(x: 1, y: 5),
            Point(x: 14, y: 25),
            Point(x: 29, y: 5),
            Point(x: 24, y: 19),
            Point(x: 24, y: 3),
            Point(x: 29, y: 23),
            Point(x: 10, y: 28),
            Point(x: 4, y: 3),
            Point(x: 4, y: 19),
            Point(x: 25, y: 11),
            Point(x: 26, y: 26),
            Point(x: 7, y: 1),
            Point(x: 1, y: 25),
            Point(x: 2, y: 11),
            Point(x: 5, y: 13),
            Point(x: 19, y: 23),
            Point(x: 8, y: 11),
            Point(x: 10, y: 21),
            Point(x: 26, y: 23),
            Point(x: 0, y: 26),
            Point(x: 12, y: 19),
            Point(x: 2, y: 3),
            Point(x: 2, y: 15),
            Point(x: 16, y: 9),
            Point(x: 24, y: 26),
            Point(x: 16, y: 26),
            Point(x: 15, y: 13),
            Point(x: 15, y: 21),
            Point(x: 9, y: 28),
            Point(x: 3, y: 9),
            Point(x: 6, y: 11),
            Point(x: 24, y: 15),
            Point(x: 13, y: 11),
            Point(x: 13, y: 7),
            Point(x: 7, y: 18),
            Point(x: 8, y: 28),
            Point(x: 22, y: 9),
            Point(x: 25, y: 12),
            Point(x: 28, y: 4),
            Point(x: 3, y: 26),
            Point(x: 8, y: 7),
            Point(x: 1, y: 16),
            Point(x: 6, y: 15),
            Point(x: 21, y: 16),
            Point(x: 23, y: 19),
            Point(x: 11, y: 25),
            Point(x: 21, y: 3),
            Point(x: 17, y: 5),
            Point(x: 6, y: 9),
            Point(x: 23, y: 13),
            Point(x: 16, y: 28),
            Point(x: 4, y: 6),
            Point(x: 1, y: 28),
            Point(x: 23, y: 1),
            Point(x: 3, y: 15),
            Point(x: 16, y: 3),
            Point(x: 15, y: 19),
            Point(x: 18, y: 20),
            Point(x: 15, y: 18),
            Point(x: 5, y: 5),
            Point(x: 5, y: 3),
            Point(x: 17, y: 25),
            Point(x: 29, y: 9),
            Point(x: 10, y: 9),
            Point(x: 14, y: 15),
            Point(x: 13, y: 17),
            Point(x: 25, y: 1),
            Point(x: 1, y: 3),
            Point(x: 8, y: 10),
            Point(x: 20, y: 3),
            Point(x: 14, y: 1),
            Point(x: 7, y: 26)
        ]),
        goal: Point(x: 29, y: 29)
    )
    let screenWidth = UIViewController().view.bounds.width
    let screenHeight = UIViewController().view.bounds.height
    
    var body: some View {
        VStack(alignment: .center) {
            Slider(value: $mapModel.slowDownSec, in: 0...1)
            HStack {
                Button {
                    Task {
                        await mapModel.findPath()
                    }
                } label: {
                    Text("Start")
                        .font(.largeTitle)
                        .foregroundStyle(.red)
                }
                
                Button {
                    
                    print("let walls = Set<Point>([")
                    mapModel.walls.forEach({ print("Point(x: \($0.x), y: \($0.y)),") })
                    print("])")
                    
                } label: {
                    Text("Print map")
                        .font(.largeTitle)
                        .foregroundStyle(.red)
                }
            }
            GeometryReader { geometry in
                let screenWidth = geometry.size.width
                let screenHeight = geometry.size.height
                
                VStack(spacing: 1) {
                    ForEach(0..<mapModel.rows, id: \.self) { rowIndex in
                        HStack(spacing: 1) {
                            ForEach(0..<mapModel.cols, id: \.self) { colIndex in
                                
                                ZStack {
                                    Rectangle()
                                        .fill(cellColor(row: rowIndex, col: colIndex, mapModel: mapModel))
                                        .frame(
                                            width: screenWidth / CGFloat(mapModel.cols + 2),
                                            height: screenHeight / CGFloat(mapModel.rows + 2)
                                        )
                                    
                                    Text("\(mapModel.gScore[Point(x: colIndex, y: rowIndex), default: 0])")
                                }
                                .onTapGesture {
                                    handleTap(row: rowIndex, col: colIndex)
                                }

                            }
                        }
                    }
                    
                    
                }
                .frame(maxWidth: .infinity)
            }
        }

    }
    
    
    private func handleTap(row: Int, col: Int) {
        let tappedPoint = Point(x: col, y: row)
        if mapModel.walls.contains(where: { $0 == tappedPoint }) {
            mapModel.walls.remove(tappedPoint)
        } else {
            mapModel.walls.insert(tappedPoint)
        }
    }
    
    func cellColor(row: Int, col: Int, mapModel: Map) -> Color {
        let point = Point(x: col, y: row)
        
        if mapModel.start == point {
            return .green
        } else if mapModel.goal == point {
            return .red
        } else if mapModel.walls.contains(where: { $0 == point }) {
            return .black
        } else if mapModel.currentCheckPoint == point {
            return .red
        } else if mapModel.path.contains(where: { $0 == point }) {
            return .yellow
        } else if mapModel.openSet.contains(where: { $0 == point}) {
            return .orange
        }  else if mapModel.cameFrom.keys.contains(point) {
            return .blue

        } else {
            return .gray
        }
    }
}

#Preview {
    ContentView()
}
