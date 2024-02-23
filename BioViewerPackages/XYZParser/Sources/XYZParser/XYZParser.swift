import BioViewerFoundation
import Foundation
import simd

public actor XYZParser {
    
    var currentLine: Int = 0
    var totalLineCount: Int = 1
    // Initialize empty configuration
    var configurations: [XYZParsedConfiguration] = [XYZParsedConfiguration(id: 0)]
    
    public init() { }
    
    // MARK: - Reset parser
    func resetParser() {
        self.currentLine = 0
        self.totalLineCount = 1
        self.configurations = [XYZParsedConfiguration(id: 0)]
    }
    
    // MARK: - Configuration creation
    
    func createNewConfigurationUnlessEmpty() {
        guard configurations.last?.atomElements.count != 0 else {
            // No need to create a new configuration, the last one is already empty
            return
        }
        configurations.append(contentsOf: [XYZParsedConfiguration(id: configurations.count)])
    }
    
    // MARK: - Parse line
    
    func parseLine(_ line: String, progress: Progress) {
        currentLine += 1
        progress.completedUnitCount = Int64(currentLine)
        
        let lineElements = line.components(separatedBy: .whitespaces).filter({ !$0.isEmpty })
        guard lineElements.count >= XYZConstants.atomLineNumberOfComponents else {
            createNewConfigurationUnlessEmpty()
            return
        }
        
        // Try to parse energy
        let normalizedLine = line.lowercased().components(separatedBy: .whitespacesAndNewlines).joined(separator: "")
        if normalizedLine.contains("energy=") {
            let components = normalizedLine.components(separatedBy: "energy=")
            if components.count >= 2 {
                configurations.last?.energy = Float(components[1])
            }
        }
        
        // Retrieve atom element

        let elementString = lineElements[0].replacingOccurrences(of: " ", with: "")

        // Normalize atom element, might be of "UNKNOWN" type
        let element = AtomElement(string: elementString)

        // Get atom coordinates

        // Check that all 3 coordinates are non-nil so we don't end up
        // with atoms with partial coordinates. Remove whitespaces too
        // or float-casting will return nil.

        guard let x = Float( lineElements[1] ),
              let y = Float( lineElements[2] ),
              var z = Float( lineElements[3] )
        else {
            createNewConfigurationUnlessEmpty()
            return
        }
        
        // Since the projection matrix is left-handed, fix the chirality of the molecules
        z = -z
        
        // Save atom position to array
        configurations.last?.atomArray.append(simd_float3(x, y, z))
        configurations.last?.atomElements.append(element)
    }
    
    // MARK: - Parse XYZ
    
    public func parseXYZ(
        fileName: String,
        fileExtension: String,
        byteSize: Int?,
        rawText: String,
        progress: Progress,
        originalFileInfo: ProteinFileInfo? = nil
    ) throws -> ProteinFile {
        
        resetParser()
        
        self.totalLineCount = rawText.reduce(into: 0) { (count, letter) in
            if letter == "\n" {
                count += 1
            }
        }
        progress.totalUnitCount = Int64(totalLineCount)
        
        var atomArray = ContiguousArray<simd_float3>()
        var energyArray: [Float]?
        var atomElements = [AtomElement]()
        var atomArrayComposition = ProteinElementComposition()
        
        // Protein file data
        var fileInfo = ProteinFileInfo(
            pdbID: originalFileInfo?.pdbID,
            description: originalFileInfo?.description,
            authors: originalFileInfo?.authors,
            sourceLines: originalFileInfo?.sourceLines
        )

        rawText.enumerateLines(invoking: { line, _ in
            self.parseLine(line, progress: progress)
        })
                
        guard let firstConfiguration = configurations.first else {
            throw XYZParserError.noConfiguration
        }
        
        let configurationCount: Int = configurations.count
        
        // Add element array contents into the contiguous array
        let totalCount: Int = firstConfiguration.atomArrayComposition.totalCount
        atomArray.reserveCapacity(MemoryLayout<simd_float3>.stride * totalCount * configurationCount)
        
        for configuration in configurations {
            atomArray.append(contentsOf: configuration.atomArray)
            
            if let configurationEnergy = configuration.energy {
                if energyArray == nil {
                    energyArray = [Float]()
                }
                energyArray?.append(configurationEnergy)
            }
        }
        
        guard atomArray.count > 0 else {
            throw XYZParserError.emptyAtomCount
        }

        atomElements.append(contentsOf: firstConfiguration.atomElements)
        atomArrayComposition = ProteinElementComposition(elements: atomElements)
                
        fileInfo.sourceLines = rawText.components(separatedBy: .newlines)
        
        // Return ProteinFile
        let protein = Protein(
            configurationCount: configurationCount,
            configurationEnergies: energyArray,
            atoms: atomArray,
            elementComposition: atomArrayComposition,
            atomElements: atomElements,
            chainComposition: nil,
            atomChainIDs: nil,
            residueComposition: nil,
            atomResidues: nil,
            atomSecondaryStructure: nil,
            sequence: nil
        )
        
        let fileType: ProteinFileType = configurations.count > 1 ? .dynamicStructure : .staticStructure
        
        return ProteinFile(
            fileType: fileType,
            fileName: fileName,
            fileExtension: fileExtension,
            models: [protein],
            fileInfo: fileInfo,
            byteSize: byteSize
        )
    }
}
