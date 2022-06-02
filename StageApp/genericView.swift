//
//  genericView.swift
//  StageApp
//
//  Created by Bilel Hattay on 29/05/2022.
//

import SwiftUI

struct genericView: View {
    @Binding var email: String
    @Binding var password: String

    var body: some View {
        VStack {
            Spacer()
                .frame(height: 100)
            TextField("email", text: $email)
                .textFieldStyle(.roundedBorder)
                .frame(width: UIScreen.main.bounds.width * 0.8)
                .shadow(radius: 3)
            TextField("mot de passe", text: $password)
                .textFieldStyle(.roundedBorder)
                .frame(width: UIScreen.main.bounds.width * 0.8)
                .shadow(radius: 3)
            Spacer()
                .frame(height: 80)
            Button {
                
            } label: {
                Text("se connecter")
                    .frame(width: UIScreen.main.bounds.width * 0.6, height: 40)
                    .background(Color.blue)
            }

            Spacer()
        }
    }
}

struct genericView_Previews: PreviewProvider {
    static var previews: some View {
        genericView(email: .constant(""), password: .constant(""))
    }
}
