import Vapor
import FluentMySQL

final class User: Codable {
	
	var id: UUID?
	var username: String
	var name: String
	
	init(username: String, name: String) {
		self.username = username
		self.name = name
	}
}

extension User: Model {
	
	typealias ID = UUID
	typealias Database = MySQLDatabase
	static var idKey: WritableKeyPath<User, UUID?> {
		return \User.id
	}
}

extension User: Content {}
extension User: Migration {}


extension User {
	var acronyms: Children<User, Acronym> {
		return children(\.creatorID)
	}
}
