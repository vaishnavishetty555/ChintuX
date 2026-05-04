import SwiftUI

/// Spacing and layout tokens. Base unit 4.
enum Spacing {
    static let base: CGFloat = 4

    // Semantic steps
    static let xxs: CGFloat = 4
    static let xs:  CGFloat = 8
    static let s:   CGFloat = 12
    static let m:   CGFloat = 16
    static let l:   CGFloat = 20
    static let xl:  CGFloat = 24
    static let xxl: CGFloat = 32

    // Specific layout constants
    static let screenHorizontal: CGFloat = 20
    static let screenVertical:   CGFloat = 24
    static let cardPadding:      CGFloat = 16
    static let cardGap:          CGFloat = 12
    static let tapTargetMin:     CGFloat = 48
}

enum Radius {
    static let input:   CGFloat = 10
    static let card:    CGFloat = 16
    static let button:  CGFloat = 28
    static let sheet:   CGFloat = 24
    static let chip:    CGFloat = 20
    static let avatar:  CGFloat = 14
    static let small:   CGFloat = 8
}