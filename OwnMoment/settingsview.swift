import SwiftUI

struct SettingsView: View {
    @Environment(\.presentationMode) var presentationMode
    @Binding var customDate: Date
    @Binding var customLocation: String
    @Binding var showDate: Bool
    @Binding var showLocation: Bool
    
    @State private var countryProvince: String = ""
    @State private var provinceCity: String = ""
    
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
                    
                    Toggle("不显示日期", isOn: Binding(
                        get: { !showDate },
                        set: { showDate = !$0 }
                    ))
                }
                
                Section(header: Text("地理位置设置")) {
                    TextField("输入国家/省（8字以内）", text: $countryProvince)
                        .onChange(of: countryProvince) { oldValue, newValue in
                            if newValue.count > 8 {
                                countryProvince = String(newValue.prefix(8))
                            }
                            updateCustomLocation()
                        }
                    
                    TextField("输入省/市（8字以内）", text: $provinceCity)
                        .onChange(of: provinceCity) { oldValue, newValue in
                            if newValue.count > 8 {
                                provinceCity = String(newValue.prefix(8))
                            }
                            updateCustomLocation()
                        }
                    
                    Toggle("不显示位置", isOn: Binding(
                        get: { !showLocation },
                        set: { showLocation = !$0 }
                    ))
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                
                ToolbarItem(placement: .principal) {
                    Text("更多设置")
                        .font(.headline)
                        .fontWeight(.semibold)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        // 保存设置
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
        .onAppear {
             // 初始化输入框内容
             parseCustomLocation()
         }
     }
     
     private func updateCustomLocation() {
         if !countryProvince.isEmpty && !provinceCity.isEmpty {
             customLocation = "\(countryProvince)·\(provinceCity)"
         } else if !countryProvince.isEmpty {
             customLocation = countryProvince
         } else if !provinceCity.isEmpty {
             customLocation = provinceCity
         } else {
             customLocation = ""
         }
     }
     
     private func parseCustomLocation() {
         if customLocation.contains("·") {
             let components = customLocation.components(separatedBy: "·")
             if components.count == 2 {
                 countryProvince = components[0]
                 provinceCity = components[1]
             }
         } else if !customLocation.isEmpty {
             countryProvince = customLocation
             provinceCity = ""
         }
     }
 }

struct LocationPickerView: View {
    @Environment(\.presentationMode) var presentationMode
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

class LocationManager: NSObject, ObservableObject {
    @Published var currentLocation: String? = "中国"
    
    override init() {
        super.init()
        // 不再需要实际获取位置，直接使用默认值
    }
}
