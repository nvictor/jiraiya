//
//  JiraModels.swift
//  Jiraiya
//
//  Created by Victor Noagbodji on 9/17/25.
//

import Foundation

struct Comment: Decodable {
    let body: ADFBody?
}

struct ADFBody: Decodable {
    let content: [ADFNode]
}

struct ADFNode: Decodable {
    let text: String?
    let content: [ADFNode]?
}
