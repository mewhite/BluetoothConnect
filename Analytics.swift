//
//  Created by Yonat Sharon on 12/9/14.
//
//  Note: requires a bridging header with
//        #import "Analytics.h"

import Foundation

/// Swift wrapper to pass file/line to the Objective-C analytics wrapper
func trace(msg : String, function : String = __FUNCTION__, file : String = __FILE__, line : Int = __LINE__) {
    Analytics.trace("(\(file.lastPathComponent.stringByDeletingPathExtension).\(function):\(line)) \(msg)")
}
