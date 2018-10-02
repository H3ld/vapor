import Vapor
import Leaf
import FluentMySQL

extension Request {
	func leaf() throws -> LeafRenderer {
		return try self.make(LeafRenderer.self)
	}
}

struct WebsiteController: RouteCollection {

	func boot(router: Router) throws {
		router.get(use: indexHandler)
		router.get("users", "all" , use: allUsersHandler)
		router.get("categories", "all", use: allCategoriesHandler)
		router.get("acronyms", Acronym.parameter, use: acronymDetailHandler)
		router.get("users", User.parameter, use: userDetailHandler)
		router.get("categories", Category.parameter, use: categoryDetailHandler)
		router.get("acronyms", "create", use: createAcronymHandler)
		router.post("acronyms","create", use: createAcronymPostHandler)
		router.delete(Acronym.parameter, use: deleteAcronymHandler)
	}
	
	/// Landing Page &
	/// All Acronyms
	func indexHandler(_ req: Request) throws -> Future<View> {
		return Acronym.query(on: req).all().flatMap(to: View.self) { acronyms in
			let context = IndexContent(title: "Home",
									   acronyms: acronyms.isEmpty ? nil : acronyms)
			return try req.leaf().render("index", context)
		}
	}
	

	/// All Users
	func allUsersHandler(_ req: Request) throws -> Future<View> {
		return User.query(on: req).all().flatMap(to: View.self) { users in
			let context = AllUsersContext(title: "All Users", users: users)
			return try req.leaf().render("all-users", context)
		}
	}
	
	/// All Categories
	func allCategoriesHandler(_ req: Request) throws -> Future<View> {
		return Category.query(on: req).all().flatMap(to: View.self) { categories in
			let context = AllCategoriesContext(title: "All Categories", categories: categories)
			return try req.leaf().render("all-categories", context)
		}
	}
	
	/// Acronym Details
	func acronymDetailHandler(_ req: Request) throws -> Future<View> {
		return try req.parameters.next(Acronym.self).flatMap(to: View.self) { acronym in
			return acronym.creator.get(on: req)
				.and(try acronym.categories.query(on: req).all())
				.flatMap(to: View.self) { (creator, categories) in
				
				let context = AcronymDetailContext(title: acronym.long,
												   acronym: acronym,
												   categories: categories,
												   creator: creator)
				
				
				return try req.leaf().render("acronym-detail", context)
			}
		}
	}
	
	/// User Details
	func userDetailHandler(_ req: Request) throws -> Future<View> {
		return try req.parameters.next(User.self).flatMap(to: View.self) { user in
			return try user.acronyms.query(on: req).all().flatMap(to: View.self) { acronyms in
				let context = UserDetailContext(title: "\(user.username)'s Profil",
												user: user,
												acronyms: acronyms)
				return try req.leaf().render("user-detail", context)
			}
		}
	}
	
	/// Category Details
	func categoryDetailHandler(_ req: Request) throws -> Future<View> {
		return try req.parameters.next(Category.self).flatMap(to: View.self) { category in
			return try category.acronyms.query(on: req).all().flatMap(to: View.self) { acronyms in
				let context = CategoryDetailContext(title: "\(category.name):",
													category: category,
													acronyms: acronyms)
				return try req.leaf().render("category-detail", context)
			}
		}
	}
	
	/**
	Create New Acronym
	*/
	func createAcronymHandler(_ req: Request) throws -> Future<View> {
		return User.query(on: req).all().flatMap(to: View.self) { users in
			let context = CreateAcronymContext(title: "Create Acronym", users: users)
			return try req.leaf().render("create-acronym", context)
		}
	}
	
	func createAcronymPostHandler(_ req: Request) throws -> Future<Response> {
		return try req.content.decode(CreateAcronymPostData.self)
			.flatMap(to: Response.self) { data in
				let acronym = Acronym(short: data.acronymShort, long: data.acronymLong, creatorID: data.creator)
				return acronym.save(on: req).map(to: Response.self) { acronym in
					if let id = acronym.id {
						return req.redirect(to: "/acronyms/\(id)")
					} else { return req.redirect(to: "/") }
				}
		}
	}
	
	/**
	Delete Acronym
	*/
	func deleteAcronymHandler(_ req: Request) throws -> Future<HTTPStatus> {
		return try req.parameters.next(Acronym.self)
			.flatMap(to: HTTPStatus.self) { acronym in
				return acronym.delete(on: req).transform(to: .ok)
		}
	}
}



struct IndexContent: Encodable {
	let title: String
	let acronyms: [Acronym]?
}

struct AcronymDetailContext: Encodable {
	let title: String
	let acronym: Acronym
	let categories: [Category]
	let creator: User
}

struct UserDetailContext: Encodable {
	let title: String
	let user: User
	let acronyms: [Acronym]
}

struct CategoryDetailContext: Encodable {
	let title: String
	let category: Category
	let acronyms: [Acronym]
}

struct AllUsersContext: Encodable {
	let title: String
	let users: [User]
}

struct AllCategoriesContext: Encodable {
	let title: String
	let categories: [Category]
}

struct CreateAcronymContext: Encodable {
	let title: String
	let users: [User]
}

import Foundation

struct CreateAcronymPostData: Content {
	static var defaultMediaType = MediaType.urlEncodedForm
	let acronymShort: String
	let acronymLong: String
	let creator: User.ID
}
