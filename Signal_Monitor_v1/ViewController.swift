//
//  ViewController.swift
//  Signal_Monitor_v1
//
//  Created by Mark on 12/30/21.
// Good example for BLE Central/Peripheral - uynguyen.github.io/2018/02/21/Play-Central-And-Peripheral-Roles-With-CoreBluetooth/
// medium.com/@cbartel/ios-scan-and-connect-to-a-ble-peripheral-in-the-background-731f960d520d

import UIKit
import AVKit
import CoreBluetooth


// MARK: - Core Bluetooth service IDs
let Signal_Monitor_Service_CBUUID = CBUUID(string: "4fafc201-1fb5-459e-8fcc-c5c9c3319142")


// MARK: - Core Bluetooth characteristic IDs
let Monitor_Characteristic_CBUUID = CBUUID(string: "BEB5483E-36E1-4688-B7F5-EA07361B26A8")
let Voltage_Setting_Characteristic_CBUUID = CBUUID(string: "BEB5483E-36E1-4688-B7F6-EA07361B26B9")
let Voltage_Characteristic_CBUUID = CBUUID(string: "BEB5483E-36E1-4688-B7F6-EA07361B26C7")


@available(iOS 15, *)
@available(iOS 15, *)
class ViewController: UIViewController, CBCentralManagerDelegate, CBPeripheralDelegate {
    // MARK: - Core Bluetooth class member variables
    
    // Create instance variables of the
    // CBCentralManager and CBPeripheral so they
    // persist for the duration of the app's life
    var centralManager: CBCentralManager?
    var SignalMonitor: CBPeripheral?
    

    @IBOutlet weak var connectionActivityStatus: UIActivityIndicatorView!
    
    @IBOutlet weak var bluetoothOffLabel: UILabel!
    @IBOutlet weak var ADC_SLIDER: UISlider!
    
    @IBOutlet weak var ADC_SliderSettingLabel: UILabel!
    
    @IBOutlet weak var ADCValue: UILabel!
    
    @IBOutlet weak var ADCValueLabel: UILabel!
    
    // Characteristics
    //private var powerState: CBCharacteristic?
    private var ADCSetting: CBCharacteristic?
    private var ADC_Value: CBCharacteristic?
    //private var currentTime: CBCharacteristic?
    
    // MARK: - UI outlets / member variables
    
    var play_flag = false
    
    var audioPlayer: AVAudioPlayer?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        ADC_SLIDER.isEnabled = false
    
        connectionActivityStatus.backgroundColor = UIColor.black
        connectionActivityStatus.startAnimating()
        bluetoothOffLabel.alpha = 0.0
        
        ADC_SliderSettingLabel.text = String(Int(ADC_SLIDER.value))
        
        // Create a concurrent background queue for the central
        let centralQueue: DispatchQueue = DispatchQueue(label: "com.iosbrain.centralQueueName", attributes: .concurrent)
        
        // Create a central to scan for, connect to,
        // manage, and collect data from peripherals
        centralManager = CBCentralManager(delegate: self, queue: centralQueue)
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        
        case .unknown:
            print("Bluetooth status is UNKNOWN")
            bluetoothOffLabel.alpha = 1.0
        case .resetting:
            print("Bluetooth status is RESETTING")
            bluetoothOffLabel.alpha = 1.0
        case .unsupported:
            print("Bluetooth status is UNSUPPORTED")
            bluetoothOffLabel.alpha = 1.0
        case .unauthorized:
            print("Bluetooth status is UNAUTHORIZED")
            bluetoothOffLabel.alpha = 1.0
        case .poweredOff:
            print("Bluetooth status is POWERED OFF")
            bluetoothOffLabel.alpha = 1.0
        case .poweredOn:
            print("Bluetooth status is POWERED ON")
            DispatchQueue.main.async { () -> Void in
                self.bluetoothOffLabel.alpha = 0.0
                self.connectionActivityStatus.backgroundColor = UIColor.black
                self.connectionActivityStatus.startAnimating()
                
            }
            // STEP 3.2: scan for peripherals that we're interested in
            centralManager?.scanForPeripherals(withServices: [Signal_Monitor_Service_CBUUID])
            print("Central Manager Looking!!")
        default: break
        } // END switch
    }
    
    // STEP 4.1: discover what peripheral devices OF INTEREST
    // are available for this app to connect to
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        
        print("Peripheral Found ",peripheral.name!)
        decodePeripheralState(peripheralState: peripheral.state)
        // STEP 4.2: MUST store a reference to the peripheral in
        // class instance variable
        SignalMonitor = peripheral
        // STEP 4.3: since ViewController
        // adopts the CBPeripheralDelegate protocol,
        // the SeaArkLivewellTimer must set its
        // delegate property to ViewController
        // (self)
        SignalMonitor?.delegate = self
        
        // STEP 5: stop scanning to preserve battery life;
        // re-scan if disconnected
        centralManager?.stopScan()
        print("Stopped Scanning")
        
        // STEP 6: connect to the discovered peripheral of interest
        centralManager?.connect(SignalMonitor!)
        
    } // END func centralManager(... didDiscover peripheral
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        
        DispatchQueue.main.async { () -> Void in
            
            self.connectionActivityStatus.backgroundColor = UIColor.green
            self.connectionActivityStatus.stopAnimating()
            self.ADC_SLIDER.isEnabled = true
           
        }
        
        // STEP 8: look for services of interest on peripheral
        print("Did Connect....Looking for Signal Monitor State")
        SignalMonitor?.discoverServices([Signal_Monitor_Service_CBUUID])

    } // END func centralManager(... didConnect peripheral)
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
    
    for service in peripheral.services! {
        
        if service.uuid == Signal_Monitor_Service_CBUUID {
            
            print("Service: \(service)")
            
            // STEP 9: look for characteristics of interest
            // within services of interest
            peripheral.discoverCharacteristics(nil, for: service)
            
            }
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        ADC_SLIDER.isEnabled = false
      
        connectionActivityStatus.backgroundColor = UIColor.black
        connectionActivityStatus.startAnimating()
        centralManager?.scanForPeripherals(withServices: [Signal_Monitor_Service_CBUUID])
        print("Central Manager Looking!!")
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        
        for characteristic in service.characteristics! {
            
            print("Characteristic: \(characteristic)")
            
            print("Hello from Char...")
            if characteristic.uuid == Monitor_Characteristic_CBUUID{
                print("Signal Monitor State")
                //powerState = characteristic
                peripheral.setNotifyValue(true, for: characteristic)
            }
            
            if characteristic.uuid == Voltage_Setting_Characteristic_CBUUID{
                print("Voltage Setting Notify")
                //peripheral.setNotifyValue(true, for: characteristic)
                ADCSetting = characteristic
            }
            
            if characteristic.uuid == Voltage_Characteristic_CBUUID{
                print("Voltage READING Notify")
                peripheral.setNotifyValue(true, for: characteristic)
                //ADC_Value = characteristic
            }
        }
    } // END func peripheral(... didDiscoverCharacteristicsFor service
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        
        if characteristic.uuid == Voltage_Setting_Characteristic_CBUUID {
            
            // STEP 14: we generally have to decode BLE
            // data into human readable format
            let count_n_seconds = [UInt8](characteristic.value!)
            
            print("Voltage Setting Value...", count_n_seconds[0])

           /*DispatchQueue.main.async { () -> Void in
                self.timerValueLabel.text = String(count_n_seconds[0])
            }*/
        } // END if characteristic.uuid == Voltage_Setting_Characteristic_CBUUID
        
        if characteristic.uuid == Monitor_Characteristic_CBUUID {
            
            //let circuit_state = characteristic.value!
            //let value = (String(data: circuit_state, encoding: String.Encoding.ascii)!);
            let circuit_state = [UInt8](characteristic.value!)
            let path = Bundle.main.path(forResource: "tick", ofType:"mp3")!
            let url = URL(fileURLWithPath: path)
                        print("Circuit State : ", circuit_state[0])
                        if (circuit_state[0] == 1){
                            print("Play Sound")
                            //let action = 1;
                            play_flag = true;
                            //playSound(audio_action: action)
                            //let systemSoundID: SystemSoundID = 1322
                            //    AudioServicesPlaySystemSound (systemSoundID)
                            do {
                                audioPlayer = try AVAudioPlayer(contentsOf: url)
                                audioPlayer?.play()
                            } catch {
                                print("Error loading file")
                            }
                        } else {
                            print("Dont Play Sound")
                            //let action = 0;
                            //play_flag = false
                            //playSound(audio_action: action)
                        }
            
            print("Monitor State : ")

        } // END if characteristic.uuid == Monitor_Characteristic_CBUUID
        
        if characteristic.uuid == Voltage_Characteristic_CBUUID {
            
            // STEP 14: we generally have to decode BLE
            // data into human readable format
            let ADCCurrentValue = [UInt8](characteristic.value!)
            
            print("Voltage Setting Value...", ADCCurrentValue[0])
            let weight = characteristic.value!
            print(String(data: weight, encoding: String.Encoding.ascii)!);
            
           DispatchQueue.main.async { () -> Void in
                //self.ADCValue.text = String(ADCCurrentValue[0])
               self.ADCValue.text = String(data: weight, encoding: String.Encoding.ascii)
            }
        } // END if characteristic.uuid ==...
        
    } // END func peripheral(... didUpdateValueFor characteristic
    
    func readTimer(using sensorLocationCharacteristic: CBCharacteristic) -> Int {
        
        let timeValue = sensorLocationCharacteristic.value!
        // convert to an array of unsigned 8-bit integers
        let data = [UInt8](timeValue)
        return Int(data[1])
        
    } // END func readSensorLocation
    
    func decodePeripheralState(peripheralState: CBPeripheralState) {
        
        switch peripheralState {
            case .disconnected:
                print("Peripheral state: disconnected")
            case .connected:
                print("Peripheral state: connected")
            case .connecting:
                print("Peripheral state: connecting")
            case .disconnecting:
                print("Peripheral state: disconnecting")
        default: break
        }
        
    } // END func decodePeripheralState(peripheralState
    
    func writeonStateValueToChar( withCharacteristic characteristic: CBCharacteristic, withValue value: Data) {
        if characteristic.properties.contains(.writeWithoutResponse) && SignalMonitor != nil {
            SignalMonitor?.writeValue(value, for: characteristic, type:.withoutResponse)
        }
    }
    
    @IBAction func ADCSettingChanged(_ sender: Any) {
        print("ADC Setting State Changed")
        ADC_SLIDER.isContinuous = false
        let ADCValue = String(Int(ADC_SLIDER.value))
        self.ADC_SliderSettingLabel.text = String(Int(ADC_SLIDER.value))
        let data = Data(ADCValue.utf8)
        print("ADC Setting",data)
        writeonStateValueToChar(withCharacteristic: ADCSetting!, withValue: data)
    }
    
    /*@IBAction func offTimeSettingChanged(_ sender: Any) {
        print("OFF Time Setting State Changed")
        let offTimerValue = String(Int(offTimeSettingSlider.value))
        self.offTimerSettingLabel.text = String(Int(offTimeSettingSlider.value))
        let data = Data(offTimerValue.utf8)
        print("off Time Setting",data)
        writeonStateValueToChar(withCharacteristic: offTimeSetting!, withValue: data)
    }*/
}
