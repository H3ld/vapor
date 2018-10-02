import Vapor

struct CategoriesController: RouteCollection {
	func boot(router: Router) throws {
		
		let categoriesRoutes = router.grouped("api", "categories")
		
		categoriesRoutes.post(use: createHandler)
		categoriesRoutes.get(use: getAllHandler)
		categoriesRoutes.get(Category.parameter, use: getHandler)
		categoriesRoutes.get(Category.parameter, "acronyms", use: getAcronymsHandler)
	}
	
	/// get all
	/// - GET
	func getAllHandler(_ req: Request) throws -> Future<[Category]> {
		return Category.query(on: req).all()
	}
	
	/// get one
	/// - GET
	func getHandler(_ req: Request) throws -> Future<Category> {
		return try req.parameters.next(Category.self)
	}
	
	/// create
	/// - POST
	func createHandler(_ req: Request) throws -> Future<Category> {
		return try req.content
			.decode(Category.self)
			.flatMap(to: Category.self) { category in
				return category.save(on: req)
		}
	}
	
	/// get linked acronymes
	/// - GET
	func getAcronymsHandler(_ req: Request) throws -> Future<[Acronym]> {
		return try req.parameters.next(Category.self).flatMap(to: [Acronym].self)
		{ category in return try category.acronyms.query(on: req).all() }
	}
}

extension Category: Parameter {}
