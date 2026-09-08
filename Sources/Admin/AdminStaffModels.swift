import Foundation

struct ASUAdminStaffSummary: Decodable, Hashable {
    let total: Int
    let active: Int
    let blocked: Int
    let admins: Int
    let managers: Int

    static let empty = ASUAdminStaffSummary(total: 0, active: 0, blocked: 0, admins: 0, managers: 0)
}

struct ASUAdminStaffViewer: Decodable, Hashable {
    let id: Int
    let role: ASUAdminRole
}

enum ASUAdminStaffScope: String, Decodable, Hashable {
    case allStaff = "all_staff"
    case salesManagers = "sales_managers"
}

struct ASUAdminStaffMember: Decodable, Hashable, Identifiable {
    let id: Int
    let email: String
    let fullName: String
    let phone: String?
    let role: ASUAdminRole
    let status: String
    let createdBy: Int?
    let createdAt: String
    let updatedAt: String
    let lastLoginAt: String?
    let isCurrentUser: Bool

    var isActive: Bool { status == "active" }
    var isBlocked: Bool { status == "blocked" }

    func initials() -> String {
        let parts = fullName
            .split(whereSeparator: { $0.isWhitespace })
            .prefix(2)
            .compactMap { $0.first }
        let value = String(parts).uppercased()
        return value.isEmpty ? "AS" : value
    }
}

struct ASUAdminStaffSnapshot: Hashable {
    let viewer: ASUAdminStaffViewer
    let scope: ASUAdminStaffScope
    let summary: ASUAdminStaffSummary
    let staff: [ASUAdminStaffMember]
}

struct ASUAdminCreatedStaff: Hashable {
    let member: ASUAdminStaffMember
    let temporaryPassword: String
}
