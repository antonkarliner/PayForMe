//
//  OnboardingView.swift
//  iWontPayAnyway
//
//  Created by Max Tharr on 21.01.20.
//  Copyright © 2020 Mayflower GmbH. All rights reserved.
//

import SwiftUI
import Combine

struct ProjectDetailView: View {
    
    @Environment(\.presentationMode)
    var presentationMode: Binding<PresentationMode>
    
    @ObservedObject
    var addProjectModel = AddProjectModel.shared
    
    @State
    var addProjectButtonDisabled = true
    
    @State
    var showConnectionIndicator = false
    
    @Binding
    var hidePlusButton: Bool
    
    var body: some View {
        VStack {
            Picker(selection: $addProjectModel.projectType.animation(), label: Text("snens")) {
                Text("Cospend").tag(ProjectBackend.cospend)
                Text("iHateMoney").tag(ProjectBackend.iHateMoney)
            }.pickerStyle(SegmentedPickerStyle())
                .padding(EdgeInsets(top: 8, leading: 8, bottom: 0, trailing: 8))
            
//            if addProjectModel.projectType == ProjectBackend.iHateMoney {
//                Picker(selection: $addProjectModel.addOrCreate, label: Text("snens")) {
//                    Text("Add Existing").tag(0)
//                    Text("Create New").tag(1)
//                }
//                .pickerStyle(SegmentedPickerStyle())
//                .padding(EdgeInsets(top: 8, leading: 8, bottom: 0, trailing: 8))
//                .animation(.easeInOut)
//            }
            Form {
                if self.addProjectModel.projectType == .cospend {
                    Section(header: Text("Server Address")) {
                        TextFieldContainer("https://mynextcloud.org",
                                           text: self.$addProjectModel.serverAddress)
                            .autocapitalization(.none).keyboardType(.URL)
                            .onTapGesture {
                                if self.addProjectModel.serverAddress.isEmpty {
                                    DispatchQueue.main.async {
                                        self.addProjectModel.serverAddress = "https://"
                                    }
                                }
                        }
                    }
                    .animation(.easeInOut)
                }
                Section(header: Text("Project Name & Password")) {
                    if addProjectModel.addOrCreate == 1 && addProjectModel.projectType == .iHateMoney {
                        TextField("Enter your email", text: self.$addProjectModel.emailAddr).autocapitalization(.none)
                            .keyboardType(.emailAddress)
                    }
                    TextField("Enter project id",
                              text: self.$addProjectModel.projectName)
                        .autocapitalization(.none)
                    
                    SecureField("Enter project password", text: self.$addProjectModel.projectPassword)
                }
            }
            .id(addProjectModel.projectType == .cospend ? "cospend" : "iHateMoney")
                
            .frame(width: UIScreen.main.bounds.width, height: addProjectModel.buttonOffset, alignment: .center)
            .onReceive(addProjectModel.validationProgress) {
                switch $0 {
                    case .inProgress:
                        self.showConnectionIndicator = true
                        print("inProgess")
                    case .success:
                        self.showConnectionIndicator = false
                        self.addProjectButtonDisabled = false
                        print("success")
                    case .failure:
                        self.showConnectionIndicator = false
                        self.addProjectButtonDisabled = true
                        print("failure")
                }
            }
            FancyButton(isDisabled: $addProjectButtonDisabled,
                        isLoading: $showConnectionIndicator,
                        add: false,
                        action: addButton,
                        text:
                addProjectModel.addOrCreate == 0 || addProjectModel.projectType == .cospend ? "Add Project" : "Create Project")
            Spacer()
            
        }
        .navigationBarTitle("Add Project")
        .onAppear {
            self.hidePlusButton = true
        }
        .onDisappear {
            self.hidePlusButton = false
        }
        .background(Color.PFMBackground)
    }
    
    func addButton() {
        
        let project: Project
        
        if addProjectModel.projectType == .cospend {
            guard let url = URL(string: addProjectModel.serverAddress) else { return }
            project = Project(name: addProjectModel.projectName, password: addProjectModel.projectPassword, backend: .cospend, url: url)
        } else {
            project = Project(name: addProjectModel.projectName, password: addProjectModel.projectPassword, backend: .iHateMoney)
        }
        
        if addProjectModel.addOrCreate == 0 {
            ProjectManager.shared.addProject(project)
            addProjectModel.reset()
        } else {
            ProjectManager.shared.createProject(project, email: self.addProjectModel.emailAddr) {
                self.addProjectModel.reset()
            }
        }
        
        self.presentationMode.wrappedValue.dismiss()
    }
    
}

struct OnboardingView_Previews: PreviewProvider {
    static var previews: some View {
        ProjectDetailView(addProjectModel: AddProjectModel.shared, hidePlusButton: .constant(false)).environment(\.locale, .init(identifier: "de"))
    }
}
