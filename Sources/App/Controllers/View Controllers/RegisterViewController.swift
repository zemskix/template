//
//  RegisterViewController.swift
//  App
//
//  Created by Jimmy McDermott on 6/12/18.
//

import Foundation
import Vapor
import FluentMySQL
import Crypto

class RegisterViewController: RouteCollection {
    func boot(router: Router) throws {
        router.frontend(.noAuthed) { build in
            build.get("/register", use: registerView)
            build.post(RegisterRequest.self, at: "/register", use: register)
        }
    }
    
    func registerView(req: Request) throws -> Future<View> {
        let context = CSRFContext(csrf: try req.setCSRF())
        return try req.privateView().render("register", context, request: req)
    }

    func register(req: Request, content: RegisterRequest) throws -> Future<Response> {
        guard content.password == content.confirmPassword else { throw RedirectError(to: "/register", error: "Passwords don't match") }
        
        let existingUserQuery = User
            .query(on: req)
            .filter(\.email == content.email)
            .count()
        
        return existingUserQuery.flatMap { count in
            guard count == 0 else { throw RedirectError(to: "/register", error: "A user with that email exists already") }
            
            let hashedPassword = try BCrypt.hash(content.password)
            let newUser = User(name: content.name, email: content.email, password: hashedPassword)
            
            let response = req.redirect(to: "/home").flash(.success, "Successfully registered")
            return newUser.save(on: req).transform(to: response)
        }
    }
}