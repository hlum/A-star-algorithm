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


class Map {
    let rows: Int
    let cols: Int
    let walls: Set<Point>
    let start: Point
    let goal: Point
    
    init(rows: Int, cols: Int, walls: Set<Point>, start: Point, goal: Point) {
        self.rows = rows
        self.cols = cols
        self.walls = walls
        self.start = start
        self.goal = goal
    }
    
    
    
    func findPath() -> [Point]? {
        // Nodes to explore (the "open set"). Start from the start point.
        var openSet: Set<Point> = [start]
        
        // Keeps track of where we came from:
        // cameFrom[point] = previousPoint
        // Used later to reconstruct the path once we reach the goal.
        var cameFrom: [Point: Point] = [:]
        
        // gScore[point] = cost of the cheapest path found so far from start → point
        var gScore: [Point: Float] = [start: 0]
        
        // fScore[point] = estimated total cost from start → point → goal
        // = gScore[point] + heuristic(point, goal)
        var fScore: [Point: Float] = [start: heuristic(from: start, to: goal)]
        
        // Helper: compare two points by their fScore values.
        let hasLowerFScore: (Point, Point) -> Bool = { p1, p2 in
            fScore[p1, default: Float.greatestFiniteMagnitude] < fScore[p2, default: Float.greatestFiniteMagnitude]
        }
        
        // Main A* loop
        while !openSet.isEmpty {
            // Pick the node in openSet with the lowest fScore
            guard let currentCheckPoint = openSet.min(by: hasLowerFScore) else {
                break // Should never happen since openSet is not empty, but safe guard.
            }
            

            if currentCheckPoint == goal {
                return reconstructPath(cameFrom: cameFrom, current: currentCheckPoint)
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
        
        // If open set is empty and goal not reached → no path exists
        return nil
    }

    
    private func reconstructPath(cameFrom: [Point: Point], current: Point) -> [Point] {
        var path = [current]
        var temp = current
        
        // Walk back through the cameFrom dictionary until we reach start
        while let prevPoint = cameFrom[temp] {
            path.append(prevPoint)
            temp = prevPoint
        }
        return path.reversed() // Reverse to get start → goal
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
    
    var body: some View {
        VStack {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundStyle(.tint)
            Text("Hello, world!")
        }
        .padding()
        .onAppear {
            testAStarComplex()
        }
    }
    
    func testAStar() {
        let walls: Set<Point> = [
            Point(x: 1, y: 1),
            Point(x: 1, y: 2),
            Point(x: 1, y: 3),
            Point(x: 2, y: 3),
            Point(x: 3, y: 3)
        ]

        let map = Map(
            rows: 5,
            cols: 5,
            walls: walls,
            start: Point(x: 0, y: 0),
            goal: Point(x: 4, y: 4)
        )

        if let path = map.findPath() {
            print("✅ Path found:\n")
            map.printGrid(path: path)
        } else {
            print("❌ No path found.")
            map.printGrid()
        }

    }
    
    func testAStarComplex() {
        let walls: Set<Point> = [
            // Vertical wall with a gap
            Point(x: 1, y: 0), Point(x: 1, y: 1), Point(x: 1, y: 2), Point(x: 1, y: 3),
            Point(x: 1, y: 5), Point(x: 1, y: 6), Point(x: 1, y: 7), Point(x: 1, y: 8), Point(x: 1, y: 9),
            
            // Horizontal wall
            Point(x: 2, y: 5), Point(x: 3, y: 5), Point(x: 4, y: 5), Point(x: 5, y: 5), Point(x: 6, y: 5),
            
            // Another winding section
            Point(x: 7, y: 1), Point(x: 7, y: 2), Point(x: 7, y: 3), Point(x: 7, y: 4),
            Point(x: 7, y: 6), Point(x: 7, y: 7), Point(x: 7, y: 8),
            
            // Small block
            Point(x: 4, y: 2), Point(x: 5, y: 2), Point(x: 6, y: 2)
        ]
        
        let map = Map(
            rows: 10,
            cols: 10,
            walls: walls,
            start: Point(x: 0, y: 0),
            goal: Point(x: 9, y: 9)
        )
        
        if let path = map.findPath() {
            print("✅ Path found:\n")
            map.printGrid(path: path)
        } else {
            print("❌ No path found.")
            map.printGrid()
        }
    }


}

#Preview {
    ContentView()
}
