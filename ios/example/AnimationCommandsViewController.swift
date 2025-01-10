/*
 
Copyright 2021 Microoled
Licensed under the Apache License, Version 2.0 (the “License”);
you may not use this file except in compliance with the License.
You may obtain a copy of the License at
    http://www.apache.org/licenses/LICENSE-2.0
Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an “AS IS” BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
 
*/

import Foundation
import ActiveLookSDK
import UIKit

class AnimationCommandsViewController : CommandsTableViewController {

    
    // MARK: - Life cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Font commands"
        
        commandNames = [
            "Save Cfg Demo",
            "Display anim 1",
            "Display anim 2",
            "Clear anim",
            "Delete anim 1",
            "Delete anim 2",
            "Delete Cfg Demo",
        ]
        commandActions = [
            self.saveCfgDemo,
            self.displayAnim1,
            self.displayAnim2,
            self.clearAnim,
            self.deleteAnim1,
            self.deleteAnim2,
            self.deleteCfgDemo,
        ]
    }
    
    
    // MARK: - Actions
    
    func saveCfgDemo() {
        let alert = UIAlertController(title: "Please wait", message: "Uploading Cfg", preferredStyle: .alert)
        self.present(alert, animated: true)
        
        glasses.cfgRead(name: "ALooK", callback: { (config: ConfigurationElementsInfo) in
            if let filePath = Bundle.main.path(forResource: "demo-cfg", ofType: "txt") {
                do {
                    let cfg = try String(contentsOfFile: filePath)
                    self.glasses.loadConfiguration(cfg: cfg.components(separatedBy: "\n"))
                } catch {}
            }
            alert.dismiss(animated: true)
        })
    }
    
    func displayAnim1() {
        glasses.clear()
        glasses.cfgSet(name: "Demo")
        glasses.animDisplay(handlerId: 0, id: 1, delay: 100, repeatAnim: 255, x: 150, y: 100)
    }
    
    func displayAnim2() {
        glasses.clear()
        glasses.cfgSet(name: "Demo")
        glasses.animDisplay(handlerId: 0, id: 2, delay: 100, repeatAnim: 255, x: 150, y: 100)
    }
    
    func clearAnim(){
        glasses.animClear(handlerId: 0)
    }
    
    func deleteAnim1() {
        glasses.cfgSet(name: "Demo")
        glasses.animDelete(id: 1)
    }
    
    func deleteAnim2() {
        glasses.cfgSet(name: "Demo")
        glasses.animDelete(id: 2)
    }
    
    func deleteCfgDemo() {
        glasses.cfgDelete(name: "Demo")
    }
    
}
