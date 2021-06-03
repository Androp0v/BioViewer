//
//  PDB_ViewerTests.swift
//  BioViewerTests
//
//  Created by Raúl Montón Pinillos on 4/5/21.
//

import XCTest
@testable import BioViewer

class BioViewerTests: XCTestCase {

    var scheduler: MetalScheduler?
    var protein: Protein?

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
        self.scheduler = MetalScheduler.shared
        let proteinSampleFile = Bundle.main.url(forResource: "2OGM", withExtension: "pdb")!
        let proteinData = try! Data(contentsOf: proteinSampleFile)
        self.protein = parsePDB(rawText: String(decoding: proteinData, as: UTF8.self))
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testExample() throws {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        let camera = Camera(nearPlane: 1, farPlane: 10, focalLength: 50)
        print(camera.focalLength)
    }

    func testPerformanceExample() throws {
        let measureOptions = XCTMeasureOptions.init()
        measureOptions.iterationCount = 100
        
        // Original implementation: 0.339s, 0.339s (25th May 2021)
        // Improved implementation: 0.328s, 0.327s (26th May 2021)
        self.measure(options: measureOptions, block: {
            scheduler?.createSASPoints(protein: self.protein!, sceneDelegate: ProteinViewSceneDelegate())
        })
    }

}
