// An example Joystick
// Copy this example and modify it
// https://github.com/michael94ellis/SwiftUIJoystick

import SwiftUI
import SwiftUIJoystick

public struct Joystick: View {
    
    /// The monitor object to observe the user input on the Joystick in XY or Polar coordinates
    @ObservedObject public var joystickMonitor: JoystickMonitor
    /// The width or diameter in which the Joystick will report values
    ///  For example: 100 will provide 0-100, with (50,50) being the origin
    private let dragDiameter: CGFloat
    /// Can be `.rect` or `.circle`
    /// Rect will allow the user to access the four corners
    /// Circle will limit Joystick it's radius determined by `dragDiameter / 2`
    private let shape: JoystickShape
    
    public init(monitor: JoystickMonitor, width: CGFloat, shape: JoystickShape = .rect) {
        self.joystickMonitor = monitor
        self.dragDiameter = width
        self.shape = shape
    }
    
    public var body: some View {
        VStack{
            JoystickBuilder(
                monitor: self.joystickMonitor,
                width: self.dragDiameter,
                shape: self.shape,
                background: {
                    Circle().fill(Color.blue.opacity(0.9))
                        .frame(width: self.dragDiameter, height: self.dragDiameter)
                },
                foreground: {
                    Circle().fill(Color.black)
                        .frame(width: self.dragDiameter / 4, height: self.dragDiameter / 4)
                },
                locksInPlace: false)
//            Text("Diameter: \(self.dragDiameter)")
//            Text("XY Point = (x: \(self.joystickMonitor.xyPoint.x.formattedString), y: \(self.joystickMonitor.xyPoint.y.formattedString))")
//            Text("Polar Point = (radians: \(self.joystickMonitor.polarPoint.degrees.formattedString), y: \(self.joystickMonitor.polarPoint.distance.formattedString)")
        }
    }
}
