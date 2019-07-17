//
//  WeatherDetail.swift
//  MapView
//
//  Created by 鈞 on 2019/7/15.
//  Copyright © 2019 Hung-Ming Chen. All rights reserved.
//

import Foundation

struct CurrentWeather:Decodable {
    var main:Main
}

struct Main:Decodable{
    var temp : Double
}
