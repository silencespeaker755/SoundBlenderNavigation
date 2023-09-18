//
//  SoundList.swift
//  SoundNavigation
//
//  Created by Jason on 2023/9/13.
//  Copyright © 2023 Apple. All rights reserved.
//

import SwiftUI

struct SoundList: View {
    @Binding var sources:[String]
    @Binding var message:String
    @Binding var waited:Int
    
    @State private var isFlashing = false
    
    var body: some View {
        HStack(alignment: .center){
            Spacer()
            VStack(spacing: 0) {
                VStack{
                    if message != "" {
                        VStack{
                            if waited == -1 {
                                Text(message)
                                    .frame(width: 200, height: 48)
                                    .foregroundColor(Color.black)
                                    .background(
                                        RoundedRectangle(cornerRadius: 15)
                                            .stroke(Color.black, lineWidth: 2)
                                    )
                                    .background(Color(red: 0.5, green: 0.93, blue: 0.6))
                                    .cornerRadius(15)
                                    .padding(.bottom, 5)
                            }
                            else {
                                VStack{
                                    if isFlashing {
                                        Text(message)
                                            .frame(width: 200, height: 48)
                                            .foregroundColor(Color.black)
                                            .background(
                                                RoundedRectangle(cornerRadius: 15)
                                                    .stroke(Color.black, lineWidth: 2)
                                            )
                                            .background(Color(red: 0.95, green: 0.51, blue: 0.51))
                                            .cornerRadius(15)
                                            .padding(.bottom, 5)
                                    }
                                    else{
                                        Text(message)
                                            .frame(width: 250, height: 48)
                                            .foregroundColor(Color.clear)
                                            .background(Color.clear)
                                            .cornerRadius(15)
                                            .padding(.bottom, 5)
                                    }
                                }
                                .onAppear {
                                    flashView()
                                }
                            }
                        }
                    }
                    HStack{
                        Spacer()
                        VStack{
                            ForEach(Array(sources), id: \.self) { type in
                                VStack{
                                    HStack(alignment: .bottom , spacing: 15) {
                                        Text(type)
                                    }
                                    .frame(width: 150, height: 48)
                                    .foregroundColor(Color.black)
                                    .background(
                                        RoundedRectangle(cornerRadius: 15)
                                            .stroke(Color.black, lineWidth: 2)
                                    )
                                    .background(Color(red: 0.99, green: 0.96, blue: 0.74))
                                    .cornerRadius(15)
                                    
                                    //                        Divider().frame(width: 150)
                                }
                                .padding(.bottom, 5)
                            }
                        }
                    }
                    .frame(width: 200)
                }
                Spacer()
            }
            .foregroundColor(Color.clear)
            .background(Color.clear)
            .padding(20)
            //        .frame(width: 150, height: 170)
        }
    }
    
    func flashView() {
        withAnimation(Animation.easeInOut(duration: 0.5).repeatForever()) {
            isFlashing.toggle()
        }
    }
}

struct SoundList_Previews: PreviewProvider {
    @State static var sources:[String] = ["Test", "Speech"]
    @State static var message:String = "goes right"
    @State static var waited:Int = -1
    static var previews: some View {
        SoundList(sources: $sources, message: $message, waited: $waited)
    }
}
