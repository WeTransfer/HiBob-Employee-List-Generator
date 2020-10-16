//
//  ContentView.swift
//  Employee List
//
//  Created by Arjen van Bochoven on 03/09/2020.
//  Copyright © 2020 Arjen van Bochoven. All rights reserved.
//

import SwiftUI

struct Response: Codable {
    var employees: [Employee]
}

struct Employee: Codable {
    var email: String
    var firstName: String
    var surname: String
}


struct ContentView: View {
    @State private var employees = [Employee]()
    @State private var accessToken = ""
    @State private var listReceived = false
    @State private var showPopover: Bool = false

    var body: some View {
       
            VStack {
                Text("Employee list generator")
                    .font(.system(.largeTitle, design: .rounded))
                
                HStack {
                    SecureField("Insert Access token...", text: $accessToken)
                    .popover(
                        isPresented: self.$showPopover,
                        arrowEdge: .bottom
                    ) {
                        Text("To get an Access token, log in to HiBob and click on your name in the top right. The Select API Access and copy the token\n\n If you don't have a token, generate one and check 'Full employee read'")
                        .padding()
                            .frame(width: 200)
                    }
                    
                    Button("?") {
                        self.showPopover = true
                    }
                }


                Button(action: {self.loadData()}) {
                    Text("Get list from HiBob")
                }
                .disabled(accessToken == "")

                List(employees, id: \.email) { item in
                    VStack(alignment: .leading) {
                        Text("\(item.firstName);\(item.surname);\(item.email)")
                    }
                }
               
                Button(action: {self.saveEmployeeList()}) {
                    Text("Save employee list")
                }
                .disabled(!listReceived)
                
                Spacer()

            }.frame(minWidth: 400, minHeight: 600)
    }
    
    func loadData() {
        guard let url = URL(string: "https://api.hibob.com/v1/people") else {
            print("Invalid URL")
            return
        }
        let accessToken = self.accessToken
        var request = URLRequest(url: url)
        request.setValue(accessToken, forHTTPHeaderField: "Authorization")
        print("sending request")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            guard error == nil else {
                print("ERROR: \(String(describing: error))")
                return
            }

            if let data = data {
                if let decodedResponse = try?
                    JSONDecoder().decode(Response.self, from: data) {
                    
                    // we have good data – go back to the main thread
                    DispatchQueue.main.async {
                        // update our UI
                        self.employees = decodedResponse.employees
                        // Sort on email
                        self.employees.sort {
                            $0.email < $1.email
                        }
                    }
                    
                    self.listReceived = true

                    // everything is good, so we can exit
                    return
                }
            }

            // if we're still here it means there was a problem
            print("Fetch failed: \(error?.localizedDescription ?? "Unknown error")")

        }.resume()
    }
    
    func employeeListToCsv() -> String {
        var csvString = ""
        for item in employees {
            csvString += "\(item.firstName);\(item.surname);\(item.email)\n"
        }
        return csvString
    }
    
    func getCurrentDate() -> String {
        let date = Date()
        let format = DateFormatter()
        format.dateFormat = "yyyy-MM-dd"
        return format.string(from: date)
    }
    
    func saveEmployeeList() {
        let dialog = NSSavePanel();
        let date = getCurrentDate()
        let fileName = "WT employee list \(date).csv"

        dialog.title                   = "Save a file";
        dialog.nameFieldStringValue    = fileName
        dialog.showsResizeIndicator    = true;
        dialog.showsHiddenFiles        = false;

        if (dialog.runModal() ==  NSApplication.ModalResponse.OK) {
            let result = dialog.url // Pathname of the file

            if (result != nil) {
                let path: URL = result!.absoluteURL
                let str = self.employeeListToCsv()
                do {
                    try str.write(to: path, atomically: true, encoding: .utf8)
                } catch {
                    print(error.localizedDescription)
                }
            }
            
        } else {
            // User clicked on "Cancel"
            return
        }
    }

}


struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
