import Vapor
import FluentMySQL

struct AcronymsController: RouteCollection {
	
	func boot(router: Router) throws {
		let acronymsRoute = router.grouped("api", "acronyms")
		
		/// POST
		acronymsRoute.post(use: createHandler)
		acronymsRoute.post(Acronym.parameter, "categories", Category.parameter, use: addCategoryHandler)
		
		/// GET
		acronymsRoute.get(use: getAllHandler)
		acronymsRoute.get(Acronym.parameter, use: getHandler)
		acronymsRoute.get(Acronym.parameter, "creator", use: getCreatorHandler)
		acronymsRoute.get(Acronym.parameter, "categories", use: getCategoriesHandler)
		
		/// UPDATE
		acronymsRoute.put(Acronym.parameter, use: updateHandler)
		
		/// DELETE
		acronymsRoute.delete(Acronym.parameter, use: deleteHandler)
		
		/// SEARCH
//		acronymsRoute.get("search", use: searchHandler)
//		acronymsRoute.get("long", use: searchLongHandler)
		acronymsRoute.get("search", use: betterSearchHandler)
		
	}
	
	/**
	 CREATE
	*/
	func createHandler(_ req: Request) throws -> Future<Acronym> {
		let acronym = try req.content.decode(Acronym.self)
		return acronym.save(on: req)
	}
	
	func addCategoryHandler(_ req: Request) throws -> Future<HTTPStatus> {
		return try flatMap(to: HTTPStatus.self, req.parameters.next(Acronym.self),
						   req.parameters.next(Category.self)) { acronym, category in
							
			let pivot = try AcronymCategoryPivot(acronym.requireID(), category.requireID())
							return pivot.save(on: req).transform(to: .ok) }
	}
	
	/**
	 GET
	*/
	func getAllHandler(_ req: Request) throws -> Future<[Acronym]> {
		return Acronym.query(on: req).all()
	}
	
	func getCategoriesHandler(_ req: Request) throws -> Future<[Category]> {
		return try req.parameters.next(Acronym.self).flatMap(to: [Category].self)
		{ acronym in return try acronym.categories.query(on: req).all() }
	}

	func getHandler(_ req: Request) throws -> Future<Acronym> {
		return try req.parameters.next(Acronym.self)
	}
	
	func getCreatorHandler(_ req: Request) throws -> Future<User> {
		return try req.parameters.next(Acronym.self).flatMap(to: User.self)
		{ acronym in
			return acronym.creator.get(on: req) }
	}
	
	/**
	SEARCH
	*/
	/*
	func searchHandler(_ req: Request) throws -> Future<[Acronym]> {
		guard let searchTerm = req.query[String.self, at: "term"]
			else { throw Abort(.badRequest, reason: "Missing search term!") }
		return Acronym.query(on: req).filter(\.short == searchTerm).all()
	}
	func searchLongHandler(_ req: Request) throws -> Future<[Acronym]> {
		guard let longSearchTerm = req.query[String.self, at: "long"]
			else { throw Abort(.badRequest, reason: "Missing search Term!") }
		return Acronym.query(on: req).filter(\.long == longSearchTerm).all()
	}
	*/
	
	func betterSearchHandler(_ req: Request) throws -> Future<[Acronym]> {
		guard let searchTerm = req.query[String.self, at: "term"]
			else { throw Abort(.badRequest, reason: "Missing search term!") }
		return Acronym.query(on: req).group(.or) { or in
			or.filter(\.short == searchTerm)
			or.filter(\.long == searchTerm)
		}.all()
	}
	
	/**
	 UPDATE
	*/
	func updateHandler(_ req: Request) throws -> Future<Acronym> {
		return try flatMap(to: Acronym.self,
						   req.parameters.next(Acronym.self),
						   req.content.decode(Acronym.self))
		{ acronym, updatedAcronym in
			acronym.short = updatedAcronym.short
			acronym.long = updatedAcronym.long
			return acronym.save(on: req)
		}
	}
	

	/**
	 DELETE
	*/
	func deleteHandler(_ req: Request) throws -> Future<HTTPStatus> {
		return try req.parameters
			.next(Acronym.self)
			.flatMap(to: HTTPStatus.self)
			{ return $0.delete(on: req).transform(to: .noContent) }
	}
}

extension Acronym: Parameter {}
