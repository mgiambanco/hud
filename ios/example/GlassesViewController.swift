import UIKit
import ActiveLookSDK
import SwiftUI
import SwiftOBD2
import Combine

class GlassesViewController: UIViewController {
	@IBOutlet weak var foundGlasses: UILabel!
	
	@Published var glasses: Glasses!

	@Published var measurements: [OBDCommand: MeasurementResult] = [:]
	@Published var connectionState: ConnectionState = .disconnected
	
	private let scanDuration: TimeInterval = 20.0
	private let connectionTimeoutDuration: TimeInterval = 120.0
	
	private var scanTimer: Timer?
	private var connectionTimer: Timer?
	
	private var discoveredGlassesArray: [DiscoveredGlasses] = []
	private var connecting: Bool = false
	
	
	let obdService = OBDService(connectionType: .bluetooth)

	var cancellables = Set<AnyCancellable>()
	
	func startConnection()  async throws  {
		let obd2info = try await obdService.startConnection(
			preferedProtocol: .protocol6
		)
	}
	
	func startContinousUpdates() {
		obdService
			.startContinuousUpdates(
				[.mode1(.rpm), .mode1(.speed)],
				unit: .imperial
				, interval: 0.1) // You can add more PIDs
			.sink { completion in
				
			} receiveValue: { [self] measurements in
				self.measurements = measurements
				
				self.glasses
					.layoutClearAndDisplayExtended(
						id: 11,
						x: 0,
						y: 0,
						text: String(format: "%.0f",self.measurements[.mode1(.speed)]?.value ?? "0") + "mph"
					)
				self.glasses
					.layoutClearAndDisplayExtended(
						id: 11,
						x: 0,
						y: 45,
						text: String(format: "%.0f",self.measurements[.mode1(.rpm)]?.value ?? "0") + "rpm"
					)
				self.glasses
					.layoutClearAndDisplayExtended(
						id: 11,
						x: 0,
						y: 90,
						text: String(
							format: "%.0f",
							self.measurements[.mode1(.fuelLevel)]?.value ?? "0"
						) + "gal"
					)
//				print(self.measurements)
			}
			.store(in: &cancellables)
	}
	
    private lazy var activeLook: ActiveLookSDK = {
        try! ActiveLookSDK.shared(
                onUpdateStartCallback: { SdkGlassesUpdate in
                 print("onUpdateStartCallback")
             }, onUpdateAvailableCallback: { (SdkGlassesUpdate, authorize: () -> Void) in
                 authorize()
             }, onUpdateProgressCallback: { SdkGlassesUpdate in
                 print("onUpdateProgressCallback:",
                    " \(SdkGlassesUpdate.getSourceFirmwareVersion()) -> \(SdkGlassesUpdate.getTargetFirmwareVersion())",
                    " =>\(String(format: "%.2f", SdkGlassesUpdate.getProgress()))%")
             }, onUpdateSuccessCallback: { SdkGlassesUpdate in
                 print("onUpdateSuccessCallback")
             }, onUpdateFailureCallback: { SdkGlassesUpdate in
                 print("onUpdateFailureCallback")
         })
    }()

    override func viewDidDisappear(_ animated: Bool) {
        activeLook.stopScanning()
        super.viewDidDisappear(animated)
    }

	@IBAction func scan() {
		activeLook.startScanning(
			onGlassesDiscovered: { [weak self] (discoveredGlasses: DiscoveredGlasses) in
				self?.addDiscoveredGlasses(discoveredGlasses)
			}, onScanError: { [weak self] (error: Error) in
				self?.stopScanning()
			}
		)
		
		scanTimer = Timer.scheduledTimer(withTimeInterval: scanDuration, repeats: false) { timer in
			self.stopScanning()
		}
	}

	@IBAction func connect() {
		if connecting { return }
		connecting = true
		
		let selectedGlasses = discoveredGlassesArray[0]
		
		selectedGlasses.connect(
			onGlassesConnected: { [weak self] (glasses: Glasses) in
				guard let self = self else { return }
				self.glasses = glasses
				
				self.connecting = false
				self.connectionTimer?.invalidate()
				if (glasses.isFirmwareAtLeast(version: "4.0")) {
					Task {
						do {
							try await self.startConnection()
							self.startContinousUpdates()
						} catch {
							print(error)
						}
					}
				}
			}, onGlassesDisconnected: { [weak self] in
				guard let self = self else { return }
				
			}, onConnectionError: { [weak self] (error: Error) in
				guard let self = self else { return }
				
				self.connecting = false
				self.connectionTimer?.invalidate()
				
			})
		
		connectionTimer = Timer.scheduledTimer(withTimeInterval: connectionTimeoutDuration, repeats: false, block: { [weak self] (timer) in
			guard let self = self else { return }
			
			print("connection to glasses timed out")
			self.connecting = false
			
		})
	}
    
    private func addDiscoveredGlasses(_ glasses: DiscoveredGlasses) {
        discoveredGlassesArray.append(glasses)
		self.foundGlasses.text = discoveredGlassesArray[0].name
    }
    
    private func stopScanning() {
        activeLook.stopScanning()
        scanTimer?.invalidate()
    }
}
