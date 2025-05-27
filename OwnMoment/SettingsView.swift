import SwiftUI
import CoreLocation

struct SettingsView: View {
    @Environment(".presentationMode") var presentationMode
    @Binding var customDate: Date
    @Binding var customLocation: String
    
    @State private var isLocationPickerPresented = false
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("日期设置")) {
                    DatePicker(
                        "选择日期",
                        selection: $customDate,
                        displayedComponents: [.date]
                    )
                    .datePickerStyle(GraphicalDatePickerStyle())
                }
                
                Section(header: Text("地理位置设置")) {
                    Button(action: {
                        isLocationPickerPresented = true
                    }) {
                        HStack {
                            Text("当前位置")
                            Spacer()
                            Text(customLocation)
                                .foregroundColor(.gray)
                        }
                    }
                }
            }
            .navigationTitle("设置")
            .navigationBarItems(
                leading: Button("取消") {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: Button("完成") {
                    // 保存设置
                    presentationMode.wrappedValue.dismiss()
                }
            )
        }
        .sheet(isPresented: $isLocationPickerPresented) {
            LocationPickerView(selectedLocation: $customLocation)
        }
    }
}

struct LocationPickerView: View {
    @Environment(".presentationMode") var presentationMode
    @Binding var selectedLocation: String
    @StateObject private var locationManager = LocationManager()
    
    var body: some View {
        NavigationView {
            List {
                if let currentLocation = locationManager.currentLocation {
                    Button(action: {
                        selectedLocation = currentLocation
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Text(currentLocation)
                    }
                } else {
                    Text("正在获取位置...")
                }
            }
            .navigationTitle("选择位置")
            .navigationBarItems(trailing: Button("完成") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
}

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let locationManager = CLLocationManager()
    @Published var currentLocation: String?
    
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        
        let geocoder = CLGeocoder()
        geocoder.reverseGeocodeLocation(location) { placemarks, error in
            if let error = error {
                print("反地理编码错误: \(error.localizedDescription)")
                return
            }
            
            if let placemark = placemarks?.first {
                DispatchQueue.main.async {
                    if let locality = placemark.locality, let subLocality = placemark.subLocality {
                        self.currentLocation = "\(locality)·\(subLocality)"
                    } else if let locality = placemark.locality {
                        self.currentLocation = locality
                    }
                }
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("位置获取错误: \(error.localizedDescription)")
    }
}