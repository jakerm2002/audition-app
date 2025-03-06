//
//  SwiftUIHelpers.swift
//  audition
//
//  Created by Jake Medina on 3/3/25.
//

import Foundation
import PencilKit


// each blob must contain a PKStroke, according to the blob's contentTypeIdentifier
func createDrawing(strokes: [Blob]) throws -> PKDrawing {
    var result = [PKStroke]()
    for stroke in strokes {
        guard stroke.contentTypeIdentifier == PKAppleStrokeTypeIdentifier else {
            throw AuditionError.runtimeError("Cannot create drawing from Blobs. At least one Blob's contentTypeIdentifier does not indicate that this blob contains a PKStroke.")
        }
        result.append(try PKStroke(from: stroke.contents))
    }
    return PKDrawing(strokes: result)
}
