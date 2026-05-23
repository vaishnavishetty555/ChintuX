import SwiftUI

/// Spacing scale based on 4-pt grid.
enum Spacing {
    static let base: CGFloat = 4

    static let xxs: CGFloat = 4
    static let xs:  CGFloat = 8
    static let s:   CGFloat = 12
    static let m:   CGFloat = 16
    static let l:   CGFloat = 20
    static let xl:  CGFloat = 24
    static let xxl: CGFloat = 32
    static let xxxl: CGFloat = 48

    static let screenHorizontal: CGFloat = 20
    static let screenVertical:   CGFloat = 24
    static let cardPadding:      CGFloat = 16
    static let cardGap:          CGFloat = 12
    static let tapTargetMin:     CGFloat = 48

    /// Vertical breathing room for content above the floating tab bar.
    static let tabBarBottomSafe: CGFloat = 96
}

enum Radius {
    static let xs:      CGFloat = 6
    static let small:   CGFloat = 10   // inputs
    static let input:   CGFloat = 10
    static let button:  CGFloat = 12
    static let card:    CGFloat = 20
    static let chip:    CGFloat = 999   // capsule
    static let avatar:  CGFloat = 16
    static let pill:    CGFloat = 999
    static let sheet:   CGFloat = 24
    static let tabBar:  CGFloat = 28

    // Paw Buddy Care additions
    static let cardLg:   CGFloat = 22
    static let cardXl:   CGFloat = 28
    static let cardFull: CGFloat = 999
}
