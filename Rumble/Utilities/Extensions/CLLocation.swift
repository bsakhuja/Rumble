//
//  CLLocation.swift
//  Rumble
//
//  Created by Brian Sakhuja on 11/8/23.
//

import Foundation
import MapKit

extension CLLocation {
    func placemark(completion: @escaping (_ placemark: CLPlacemark?, _ error: Error?) -> Void) {
        CLGeocoder().reverseGeocodeLocation(self) { completion($0?.first, $1) }
    }
}
