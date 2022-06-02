//
//  ContentView.swift
//  StageApp
//
//  Created by Bilel Hattay on 29/05/2022.
//

import SwiftUI
import FirebaseFirestore
import FirebaseStorage
import FirebaseAuth

import Combine

let db = Firestore.firestore()
let storage = Storage.storage()
let bucketlink = "gs://miamapp-cc1ca.appspot.com/"

func Unwrapped<T>(binding: Binding<T?>) -> Binding<T> {
    return Binding(get: {
        binding.wrappedValue!
    }, set: {
        binding.wrappedValue = $0
    })
}

func imagetoFile(pathName: String, image: UIImage) -> URL? {
    let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
    if let filePath = paths.first?.appendingPathComponent(pathName + ".jpeg") {
        do { try image.jpegData(compressionQuality: 0.25)?.write(to: filePath, options: .atomic) }
        catch { }
        return filePath
    }
    return nil
}

func uploadImage(pathName: String, image: UIImage) {
    if let filePath = imagetoFile(pathName: pathName, image: image) {
        let stopath = bucketlink + "\(Auth.auth().currentUser!.uid)/" + filePath.lastPathComponent
        dbManager.shared.UploadFile(PathtoFile: filePath, storagePath: stopath) { bool in
            if bool {
                dbManager.shared.downloadFile(storagePath: stopath) { url in
                    if let url = url {
                        let newdatas: [String: Any] = [
                            "urlcontent": url.absoluteString,
                        ]
                        let subdocid = pathName == "PhotoDeProfil" ? "profilpic": "couvpic"
                        db.collection("Users").document(Auth.auth().currentUser!.uid).collection(pathName).document(subdocid).setData(newdatas, merge: true)
                    }
                }
            } else {
                
            }
        }
    }
}

func loadImageFromUrl_Ios14(urlString: String, completion: @escaping(UIImage)->() ) {
    // PAS IMAGE DANS CACHE
    guard let url = URL(string: urlString) else {
        
        return }
    
    let task = URLSession.shared.dataTask(with: url) { data, response, error in
        guard let data = data else { return }
        let ImageComp = UIImage(data: data) ?? UIImage()
        completion(ImageComp)
    }
    task.resume()
}

struct ContentView: View {
    @State var email = ""
    @State var password = ""
    @State var connect = false
    @State var pageInfo = false
    
    @StateObject var manager = dbManager.shared
    @State var keyboardheight: CGFloat = 0

    var body: some View {
        NavigationView {
            GeometryReader { reader in
                ZStack {
                    Color.white.frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
                        .onTapGesture {
                            hideKeyboard()
                        }
                    if manager.isSignedin {
                        if pageInfo {
                            informationsView(showVue: $pageInfo)
                                .navigationTitle("Informations")
                                .navigationBarTitleDisplayMode(.inline)
                                .navigationBarItems(
                                    leading:
                                        Button(action: {
                                            pageInfo = false
                                        }, label: {
                                            Label("Profil", systemImage: "chevron.left")
                                                .labelStyle(.titleAndIcon)
                                                .foregroundColor(.red)
                                        })
                                )
                        } else {
                            profilView(pageInfo: $pageInfo)
                        }
                        
                    } else {
                        if connect {
                            generic(manager: manager, email: $email, password: $password, connect: connect, placeButton: "Se connecter")
                                .navigationTitle("")
                                .navigationBarTitleDisplayMode(.inline)
                                .navigationBarItems(
                                    leading:
                                        Text("S'inscrire")
                                        .bold()
                                        .font(.title3),
                                    trailing:
                                        Button(action: {
                                            connect.toggle()
                                        }, label: {
                                            Text("S'inscrire")
                                                .bold()
                                                .foregroundColor(.red)

                                        })
                                )
                                .ignoresSafeArea(.keyboard, edges: .bottom)
                        } else {
                            generic(manager: manager, email: $email, password: $password, connect: connect, placeButton: "S'inscrire")
                                .navigationTitle("")
                                .navigationBarTitleDisplayMode(.inline)
                                .navigationBarItems(
                                    leading: Text("S'inscrire")
                                        .bold()
                                        .font(.title3),
                                    trailing:
                                        Button(action: {
                                            connect.toggle()
                                        }, label: {
                                            Text("Se connecter")
                                                .bold()
                                                .foregroundColor(.red)

                                        })
                                )
                                .ignoresSafeArea(.keyboard, edges: .bottom)

                        }

                    }
                }

            }
        }
        .onReceive(Publishers.keyboardHeight, perform: { keyboardheight = $0; print("al: \(keyboardheight)") })
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

struct informationsView: View {
    @Binding var showVue: Bool
    
    @State var phone = ""
    @State var adresse = ""
    @State var ville = ""
    @State var codePostal = ""
    @State var moyenne_b = ""
    @State var moyenne_h = ""

    var body: some View {
        ScrollView {
            VStack {
                VStack(spacing: 15) {
                    TextField("numéro de téléphone", text: $phone)
                        .keyboardType(.numberPad)
                    TextField("adresse", text: $adresse)
                    TextField("Ville", text: $ville)
                    TextField("Code Postal", text: $codePostal)
                        .keyboardType(.numberPad)
                    TextField("moyenne basse de prix", text: $moyenne_b)
                        .keyboardType(.numberPad)
                    TextField("moyenne haute de prix", text: $moyenne_h)
                        .keyboardType(.numberPad)
                }
                .frame(width: 280)
                .textFieldStyle(.roundedBorder)
                Button {
                    setinfosUserdoc()
                    setInfostodb()
                    showVue = false
                } label: {
                    Text("Enregistrer")
                        .bold()
                        .frame(width: 220, height: 50)
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
                Spacer()
            }
            .frame(width: UIScreen.main.bounds.width)
            .background(Color.white)
            .onTapGesture {
                hideKeyboard()
            }
        }
        .onTapGesture {
            hideKeyboard()
        }
    }
    
    func setinfosUserdoc() {
        if phone.isEmpty || ville.isEmpty {
            return
        }
        let datas: [String: Any] = [
            "PhoneNumber": phone,
            "Ville": ville,
            "ville": ville
        ]
        db.collection("Users").document(dbManager.shared.Authuser.currentUser!.uid).setData(datas, merge: true)
    }
    
    func setInfostodb() {
        if ville.isEmpty || adresse.isEmpty || codePostal.isEmpty || moyenne_h.isEmpty || moyenne_b.isEmpty {
            return
        }
        let newDatas: [String: Any] = [
            "adresse": adresse,
            "Adresse": adresse,
            "ville": ville,
            "Ville": ville,
            "code postal": codePostal,
            "Code Postal": codePostal,
            "moyenne basse": (moyenne_b as NSString).integerValue,
            "moyenne haute": (moyenne_h as NSString).integerValue,
            
        ]
        db.collection("Users").document(dbManager.shared.Authuser.currentUser!.uid).collection("InfosdesCommerces").document(dbManager.shared.Authuser.currentUser!.uid).setData(newDatas, merge: true)
    }
}

struct profilView: View {
    @State var profilpic = UIImage(systemName: "person.fill")
    @State var couvpic: UIImage!
    @State var photoMenu: UIImage?
    
    @State var keyword = ""
    @State var pseudo = ""
    @State var showSetPseudo = true
    @State var showImagePicker = 0

    @Binding var pageInfo: Bool
    var body: some View {
        ScrollView {
            ZStack(alignment: .top) {
                VStack(spacing: 25) {
                    ZStack(alignment: .bottomLeading) {
                        Group {
                            if couvpic != nil {
                                Image(uiImage: couvpic)
                                    .resizable()
                                    .frame(width: UIScreen.main.bounds.width, height: 200)
                            } else {
                                Color.gray
                                    .frame(width: UIScreen.main.bounds.width, height: 200)
                            }
                        }
                        .onTapGesture {
                            showImagePicker = 1
                        }
                        Image(uiImage: profilpic ?? UIImage())
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 72, height: 72)
                            .cornerRadius(360)
                            .clipped()
                            .overlay(Circle().stroke(lineWidth: 1.5))
                            .offset(x: 25, y: 18)
                            .onTapGesture {
                                showImagePicker = 2
                            }
                    }
                    if showSetPseudo {
                        VStack {
                            TextField("ajouter un pseudo", text: $pseudo)
                                .textFieldStyle(.roundedBorder)
                                .frame(width: UIScreen.main.bounds.width * 0.5)
                            Button {
                                pseudo.trimmingCharacters(in: .whitespacesAndNewlines)
                                dbManager.shared.setpseudo(pseudo: pseudo)
                                pseudo.removeAll()
                                showSetPseudo = false
                            } label: {
                                Text("valider")
                                    .padding(.vertical, 5)
                                    .padding(.horizontal, 15)
                                    .background(Color.black)
                                    .foregroundColor(.white)
                                    .cornerRadius(18)
                            }

                        }
                    } else {
                        Text(pseudo)
                            .onTapGesture {
                                print(Auth.auth().currentUser!.uid)
                            }
                    }
                    VStack(spacing: 8) {
                        TextField("ajouter un mot clé", text: $keyword)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: UIScreen.main.bounds.width * 0.5)
                            .padding(.top, 25)
                        Button {
                            keyword.trimmingCharacters(in: .whitespacesAndNewlines)
                            addkeyword()
                            keyword.removeAll()
                        } label: {
                            Text("valider")
                                .padding(.vertical, 5)
                                .padding(.horizontal, 15)
                                .background(Color.black)
                                .foregroundColor(.white)
                                .cornerRadius(18)
                        }

                    }

                    Button {
                        showImagePicker = 3
                    } label: {
                        ZStack {
                            Rectangle()
                                .fill(Color.black)
                                .frame(width: 110, height: 110)
                            Image(systemName: "plus")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 90, height: 90)
                                .foregroundColor(.white)
                        }
                    }

                    Spacer()
                }
                .onAppear {
                    dbManager.shared.getPseudo { bool, str in
                        if let str = str {
                            pseudo = str
                            showSetPseudo = false
                        }
                    }
                    dbManager.shared.getProfilpic { image in
                        if let image = image {
                            profilpic = image
                        }
                    }
                    dbManager.shared.getCouvpic { image in
                        if let image = image {
                            couvpic = image
                        }
                    }
                }
                
                if photoMenu != nil {
                    newMenu(photoMenu: $photoMenu, showImagePicker: $showImagePicker, pseudo: pseudo)
                }

                if showImagePicker == 1 {
                    ImagePicker(image: $couvpic, dismiss: $showImagePicker)
                        .transition(.move(edge: .bottom))
                } else if showImagePicker == 2 {
                    ImagePicker(image: $profilpic, dismiss: $showImagePicker)
                        .transition(.move(edge: .bottom))
                } else if showImagePicker == 3 {
                    ImagePicker(image: $photoMenu, dismiss: $showImagePicker)
                }
            }
            .navigationTitle(photoMenu == nil ? "Profil": "Menu")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading:
                    Button(action: {
                        if photoMenu == nil {
                            dbManager.shared.signout()
                        } else {
                            photoMenu = nil
                        }
                    }, label: {
                        if photoMenu == nil {
                            Label("Se déconnecter", systemImage: "chevron.left")
                                .labelStyle(.titleAndIcon)
                                .foregroundColor(.red)
                        } else {
                            Label("Profil", systemImage: "chevron.left")
                                .labelStyle(.titleAndIcon)
                                .foregroundColor(.red)
                        }
                    }),
                trailing:
                    Button(action: {
                        pageInfo = true
                    }, label: {
                        Text("informations")
                    })
            )
            .onChange(of: profilpic) { newValue in
                if let image = newValue {
                    uploadImage(pathName: "PhotoDeProfil", image: image)
                }
            }
            .onChange(of: couvpic) { newValue in
                if let image = newValue {
                    uploadImage(pathName: "PhotoDeCouverture", image: image)
                }
            }
        }
    }
    
    func addkeyword() {
        let data: [String: Any] = [
            "key": FieldValue.arrayUnion([keyword])
        ]
        db.collection("Users").document(Auth.auth().currentUser!.uid).setData(data, merge: true)
    }
}

struct newMenu: View {
    @State var description = ""
    @State var prix = ""
    @State var titre = ""
    
    @Binding var photoMenu: UIImage?
    @Binding var showImagePicker: Int
    
    let pseudo: String
    var body: some View {
        VStack {
            TextEditor(text: $description)
                .frame(width: 280, height: 120)
                .padding()
                .overlay(RoundedRectangle(cornerRadius: 24).stroke(lineWidth: 2))
            
            HStack {
                TextField("Entrez un titre", text: $titre)
                    .frame(width: 200)
                TextField("prix", text: $prix)
                    .frame(width: 80)
            }
            .padding()
            .textFieldStyle(.roundedBorder)
            Button(action: {
                publierMenu()
                photoMenu = nil
            }, label: {
                Text("Publier")
                    .bold()
                    .frame(width: 220, height: 50)
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            })
                .padding(.bottom)
                .disabled(photoMenu == nil)
            Image(uiImage: photoMenu ?? UIImage())
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(height: 160)
                .onTapGesture {
                    showImagePicker = 3
                }
            Spacer()
        }
        .frame(width: UIScreen.main.bounds.width)
        .background(Color.white)
        .onTapGesture {
            hideKeyboard()
        }
    }
    
    func publierMenu() {
        let newDatas: [String: Any] = [
            "UserId": dbManager.shared.Authuser.currentUser!.uid,
            "pseudo": pseudo,
            "identifier": "menu",
            "description": description,
            "Name": titre,
            "price": (prix as NSString).floatValue,
            "randomizer": Int.random(in: 1...30),
            "date": FieldValue.serverTimestamp()
        ]
        
        let newDatasMenu: [String: Any] = [
            "prix": (prix as NSString).floatValue,
            "titre": titre,
            "description": description,
            "type": "plat",
            "dispo":false,
        ]
        
        dbManager.shared.publierMenu(image: photoMenu!, newDatas: newDatas, menu: newDatasMenu) { bool in
            if bool {
                description.removeAll()
                titre.removeAll()
                prix.removeAll()
                photoMenu = nil
            }
        }
    }
}

struct generic: View {
    @ObservedObject var manager: dbManager
    
    @Binding var email: String
    @Binding var password: String
    let connect: Bool
    let placeButton: String
    
    @State var alert = false
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
                if connect {
                    connection()
                } else {
                    subscribe()
                }
               
            } label: {
                Text(placeButton)
                    .bold()
                    .frame(width: UIScreen.main.bounds.width * 0.65, height: 50)
                    .background(Color.blue)
                    .cornerRadius(12)
                    .foregroundColor(.white)
            }

            Spacer()
        }
        .alert(isPresented: $alert) {
            Alert(title: Text("echec de la connection"), dismissButton: .cancel())
        }
    }
    
    func subscribe() {
        manager.SignUp(email: email, password: password) { bool in
            print("\(bool)")
            alert = !bool
        }
    }
    
    func connection() {
        manager.signIn(email: email, password: password) { bool in
            alert = !bool
        }
    }
}

class dbManager: ObservableObject {
    static let shared = dbManager()
    
    @Published var Authuser = Auth.auth()
    @Published var isSignedin = Auth.auth().currentUser != nil
    // MARK: INSCRIPTION
    func SignUp(email: String, password: String, completion: @escaping(Bool)->()) {
        let NewUserData: [String: Any] = [
            "Titre": "FoodLoveur",
            "posts": 0,
            "email": email,
            "activity": "Commerce"
        ]
        
        Authuser.createUser(withEmail: email, password: password) { (result, _error) in
            guard let authResult = result, _error == nil else {
                // Sign In FAILED
                return completion(false)
            }
            
            completion(true)
            self.isSignedin = true
            // Sign IN SUCCEED
            self.SetupDataSignUp(datas: NewUserData, uid: authResult.user.uid)
        }
    }
    
    func SetupDataSignUp(datas: [String: Any], uid: String) {
        db.collection("Users").document(uid).setData(datas, merge: true) { err in

            if let err = err {

                print("Error writing document: \(err)")
                self.Authuser.currentUser!.delete { error in
                    if let _ = error {
                        
                    }
                }
                return
            }
            db.collection("Users").document(uid).collection("CompteMiam").document("compte").setData(["solde":0], merge: true) { error in
                if let _ = error {
                    
                }
                else {
                    
                }
            }
        }
    }
    
    // MARK: CONNECTION
    func signIn(email: String, password: String, completion: @escaping(Bool)->()) {
        Authuser.signIn(withEmail: email, password: password) { (result, error) in
            guard result != nil, error == nil else {
                return completion(false)
            }
           //  Sign IN SUCCEED
            self.isSignedin = true
            return completion(true)
        }
    }
    
    func signout() {
        do {
            try Authuser.signOut()
            isSignedin = false
            print("succes: \(Authuser.currentUser)")
        } catch {
            
        }
    }
    
    func setpseudo(pseudo: String) {
        db.collection("Users").document(Authuser.currentUser!.uid).setData(["pseudo": pseudo], merge: true)
    }
    
    func getPseudo(completion: @escaping(Bool, String?)->()) {
        db.collection("Users").document(Authuser.currentUser!.uid).getDocument { userSnap, error in
            if let _ = error {
                return completion(false, nil)
            }
            
            if let datas = userSnap?.data() {
                let pseudo = datas["pseudo"] as? String
                return completion(true, pseudo)
            } else {
                return completion(false, nil)
            }
        }
    }
    
    func getProfilpic(completion: @escaping(UIImage?)->()) {
        db.collection("Users").document(Authuser.currentUser!.uid).collection("PhotoDeProfil").document("profilpic").getDocument { profilpicSnap, _ in
            if let datas = profilpicSnap?.data() {
                if let urlcontent = datas["urlcontent"] as? String {
                    
                    loadImageFromUrl_Ios14(urlString: urlcontent) { uiimage in
                        return completion(uiimage)
                    }
                } else {
                    return completion(nil)
                }
            } else {
                return completion(nil)
            }
        }
    }
    
    func getCouvpic(completion: @escaping(UIImage?)->()) {
        db.collection("Users").document(Authuser.currentUser!.uid).collection("PhotoDeCouverture").document("couvpic").getDocument { couvPicSnap, _ in
            if let datas = couvPicSnap?.data() {
                if let urlcontent = datas["urlcontent"] as? String {
                    
                    loadImageFromUrl_Ios14(urlString: urlcontent) { image in
                        return completion (image)
                    }
                } else {
                    return completion (nil)
                }
            } else {
                return completion(nil)
            }
        }
    }
    
    func UploadFile(PathtoFile: URL, storagePath: String, completion: @escaping(Bool)->()) {
        let fileRef = storage.reference(forURL: storagePath)
        
        fileRef.putFile(from: PathtoFile, metadata: nil) { metadatas, error in
            if let error = error {
               return  completion(false)
            }
            else {
                return completion(true)
            }
        }
    }
    
    func downloadFile(storagePath: String, completion: @escaping(URL?)->()) {
        let storageRef = storage.reference(forURL: storagePath)
        
        storageRef.downloadURL { url, error in
            if let _ = error {
                return completion(nil)
            }
            else {
                //print(url)
                return completion(url)
            }
        }
       
    }
    
    func publierMenu(image: UIImage, newDatas: [String: Any], menu: [String: Any], completion: @escaping(Bool)->()) {
        let pubId = UUID().uuidString
        print("publied: \(pubId)")
        if let filePath = imagetoFile(pathName: pubId, image: image) {
            let stopath = bucketlink + "Publications/" + filePath.lastPathComponent

            UploadFile(PathtoFile: filePath, storagePath: stopath) { bool in
                if bool {
                    self.downloadFile(storagePath: stopath) { url in
                        if let url = url {
                            var newdatas: [String: Any] = newDatas
                            newdatas.updateValue(url.absoluteString, forKey: "urlcontent")
                            db.collection("Publications").document(pubId).setData(newdatas, merge: true)
                            var menu: [String: Any] = menu
                            menu.updateValue(url.absoluteString, forKey: "url")
                            db.collection("Users").document(self.Authuser.currentUser!.uid).collection("Menu").document(pubId).setData(menu, merge: true)
                        }
                    }
                }
            }
        }
    }
}
