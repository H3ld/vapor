import Vapor

struct UsersController: RouteCollection {
	
	func boot(router: Router) throws {
		let usersRoute = router.grouped("api", "users")

		usersRoute.post(use: createHandler)				/// create
		usersRoute.get(use: getAllHandler)				/// get all
		usersRoute.get(User.parameter, use: getHandler)	/// get one
		usersRoute.get(User.parameter, "published", use: getAcronymsHandler)
	}
	
	/// create handler
	/// - POST
	func createHandler(_ req: Request) throws -> Future<User> {
		return try req.content
			.decode(User.self)
			.flatMap(to: User.self) { user in
			return user.save(on: req)
		}
	}
	
	/// get handler
	/// - GET
	func getHandler(_ req: Request) throws -> Future<User> {
		return try req.parameters.next(User.self)
	}
	
	/// getAll handler
	/// - GET
	func getAllHandler(_ req: Request) throws -> Future<[User]> {
		return User.query(on: req).all()
	}
	
	func getAcronymsHandler(_ req: Request) throws -> Future<[Acronym]> {
		return try req.parameters.next(User.self).flatMap(to: [Acronym].self)
		{ user in return try user.acronyms.query(on: req).all() }
	}
	
}

extension User: Parameter { }
