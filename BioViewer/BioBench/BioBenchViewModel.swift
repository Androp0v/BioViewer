//
//  BioBenchViewModel.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 12/11/23.
//

import BioViewerFoundation
import Foundation
import SwiftUI

@MainActor @Observable final class BioBenchViewModel {
    
    var currentImage: CGImage?
    var benchmarkedProteins = [BenchmarkedProtein]()
    
    func runBenchmark(
        proteinViewModel: ProteinViewModel,
        colorViewModel: ProteinColorViewModel?,
        proteinDataSource: ProteinDataSource,
        statusViewModel: StatusViewModel
    ) async {
        colorViewModel?.colorBy = .chain
        for pdbID in [
            "1A3N",
            "2OGM",
            "3JBT",
            "1CWP",
            "6P4L",
            "5IRE",
            "5FUA"
            // "1UF2"
        ] {
            let benchmarkAction = StatusAction(
                type: .benchmark(proteinName: pdbID),
                progress: Progress(totalUnitCount: Int64(BioBenchConfig.numberOfFrames))
            )
            statusViewModel.showStatusForAction(benchmarkAction)
            guard let (rawText, byteSize) = try? await RCSBFetch.fetchPDBFile(rcsbid: pdbID) else {
                continue
            }
            let fileInfo = ProteinFileInfo(
                pdbID: pdbID,
                description: "",
                authors: "",
                sourceLines: nil
            )
            await proteinDataSource.removeAllFilesFromDatasource()
            let statusAction = StatusAction(type: .importFile, progress: Progress())
            try? await FileImporter.importFileFromRawText(
                rawText: rawText,
                proteinDataSource: proteinDataSource,
                statusViewModel: statusViewModel,
                statusAction: statusAction,
                fileInfo: fileInfo,
                fileName: pdbID,
                fileExtension: "pdb",
                byteSize: byteSize
            )
            await proteinViewModel.renderer.mutableState.fitCameraToBoundingVolume(proteinDataSource.selectionBoundingVolume)
            await proteinViewModel.renderer.mutableState.setAutorotating(true)
            proteinViewModel.renderer.benchmarkedFrames = 0
            let waitTask = Task.detached {
                while await proteinViewModel.renderer.benchmarkedFrames < BioBenchConfig.numberOfFrames {
                    benchmarkAction.progress?.completedUnitCount = await Int64(proteinViewModel.renderer.benchmarkedFrames)
                    await Task.yield()
                }
            }
            _ = await waitTask.result
            guard let benchmarkedTimes = proteinViewModel.renderer.benchmarkTimes else { continue }
            let meanTime = meanTime(measuredTimes: benchmarkedTimes)
            let stdTime = stdTime(measuredTimes: benchmarkedTimes, mean: meanTime)
            benchmarkedProteins.append(
                BenchmarkedProtein(
                    name: pdbID,
                    atoms: proteinDataSource.totalAtomCount,
                    time: meanTime,
                    std: stdTime
                )
            )
            print("BioBench \(benchmarkedProteins.count) (\(pdbID)): \(proteinDataSource.totalAtomCount), \(meanTime), \(stdTime.0), \(stdTime.1)")
            await proteinViewModel.renderer.mutableState.setAutorotating(false)
            statusViewModel.signalActionFinished(benchmarkAction, withError: nil)
            currentImage = await proteinViewModel.renderer.mutableState.exportBenchmarkTextures()
        }
    }
    
    private func meanTime(measuredTimes: [CFTimeInterval]) -> Double {
        return measuredTimes.reduce(0.0, { $0 + Double($1) }) / Double(BioBenchConfig.numberOfFrames)
    }
    
    private func stdTime(measuredTimes: [CFTimeInterval], mean: Double) -> (Double, Double) {
        let deviation = sqrt( measuredTimes.reduce(0.0, { $0 + pow($1 - mean, 2) }) / Double(BioBenchConfig.numberOfFrames) )
        return (mean - deviation, mean + deviation)
    }
}
