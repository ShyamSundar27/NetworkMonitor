//
//  DateExtension.swift
//  VTComponents-iOS
//
//  Created by Robin Rajasekaran on 30/01/20.
//

import Foundation


extension Date {
    
    public var timeIntervalInMilliSec: TimeInterval {
        return (self.timeIntervalSince1970 * 1000)
    }
    
    public static func dateFromMilliseconds(value: TimeInterval) -> Date {
        return Date(timeIntervalSince1970: value / 1000)
    }
    
    public static func dateFromMilliseconds(value: String) -> Date {
        return dateFromMilliseconds(value: (value as NSString).doubleValue)
    }
    
    public static func currentTimeInMilliseconds() -> UInt {
        return UInt(floor(Date().timeIntervalSince1970 * 1000))
    }
    
    public func startOfWeek(using calendar: Calendar) -> Date {
        if let date = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: self)) {
            return date
        }
        
        print("VTComponents.Date.startOfWeek(using:) - this should not occur")
        return self
    }
    
    public func isSameMinuteAs(_ date: Date) -> Bool {
        if isSameHourAs(date) {
            let calendar = Calendar.current
            let thisComps = calendar.dateComponents([.minute], from: self)
            let otherComps = calendar.dateComponents([.minute], from: date)
            return thisComps.minute! == otherComps.minute!
        }
        return false
    }
    
    func isSameHourAs(_ date: Date) -> Bool {
        if isSameDay(date) {
            let calendar = Calendar.current
            let thisComps = calendar.dateComponents([.hour], from: self)
            let otherComps = calendar.dateComponents([.hour], from: date)
            return thisComps.hour! == otherComps.hour!
        }
        return false
    }
    
    public func isSameDay(_ date: Date) -> Bool {
        if isSameMonthAs(date) {
            let calender = Calendar.current
            var compSet: Set<Calendar.Component> = Set<Calendar.Component>()
            compSet.insert(Calendar.Component.day)
            let currentComps: DateComponents =  calender.dateComponents(compSet, from: self)
            let dateComps: DateComponents = calender.dateComponents(compSet, from: date)
            return dateComps.day! == currentComps.day!
        }
        return false
    }
    
    public func isPreviousDayOf(_ date: Date) -> Bool {
        if self.isSameMonthAs(date) {
            let calender = Calendar.current
            var compSet: Set<Calendar.Component> = Set<Calendar.Component>()
            compSet.insert(Calendar.Component.day)
            let currentComps: DateComponents =  calender.dateComponents(compSet, from: self)
            let dateComps: DateComponents = calender.dateComponents(compSet, from: date)
            return (dateComps.day! - 1) == currentComps.day!
        }
        return false
    }
    
    public func isSameWeekAs(_ other: Date) -> Bool {
        if self.isSameMonthAs(other) {
            if let selfWeek = Calendar.current.dateComponents([.weekOfYear], from: self).weekOfYear,
                let otherWeek = Calendar.current.dateComponents([.weekOfYear], from: other).weekOfYear {
                return selfWeek == otherWeek
            }
        }
        return false
    }
    
    public func isSameMonthAs(_ date: Date) -> Bool {
        if self.isSameYearAs(date) {
            let calender = Calendar.current
            var compSet: Set<Calendar.Component> = Set<Calendar.Component>()
            compSet.insert(Calendar.Component.month)
            let currentComps: DateComponents =  calender.dateComponents(compSet, from: self)
            let dateComps: DateComponents = calender.dateComponents(compSet, from: date)
            return dateComps.month! == currentComps.month!
        }
        return false
    }
    
    public func isSameYearAs(_ date: Date) -> Bool {
        let calender = Calendar.current
        let currentComps: DateComponents =  calender.dateComponents([.year], from: self)
        let dateComps: DateComponents = calender.dateComponents([.year], from: date)
        return dateComps.year! == currentComps.year!
    }
}


