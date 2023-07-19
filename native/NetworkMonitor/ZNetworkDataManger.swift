//
//  ZNetworkDataManger.swift
//  Apptics-SDK
//
//  Created by shyam-15059 on 14/07/23.
//

import Foundation
import VTComponents


public protocol ZActivityObserver {
    func activityAdded(activity: ZNetworkActivity)
    func activityUpdated(activity: ZNetworkActivity)
    func activityRemoved(activity: ZNetworkActivity)
}

public class ZActivityDataManager: ZTaskInfoObserver {
    
    public var activityLimit = 500 {
        didSet {
            if activityLimit < 10 {
                activityLimit = 10
            }
//            checkLimit()
        }
    }
    
    private var activityMap: [String: ZNetworkActivity] = [:]
    private var activityIds: [String] = []
    
    private var queue: DispatchQueue = {
        let queue = DispatchQueue(label: "com.zoho.ZActivityDataManager", qos: DispatchQoS.background)
        queue.setSpecific(key: queueIdentifierKey, value: queueIdentifierValue)
        return queue
    }()
    static let queueIdentifierKey = DispatchSpecificKey<UnsafeMutableRawPointer>()
    static let queueIdentifierValue = UnsafeMutableRawPointer.allocate(byteCount: 1, alignment: 1)
    public static var shared = ZActivityDataManager()
   
    private func add(activity: ZNetworkActivity) {
//        queue.sync {
            activityMap[activity.id] = activity
            activityIds.append(activity.id)
//        }
//        checkLimit()
    }
    
    private func update(activity: ZNetworkActivity) {
//        queue.sync {
            activityMap[activity.id] = activity
//        }
    }
    private init() {
//        startTracking()
    }
    
    public func getResponseData(id: String) -> Data? {
        if let responseData = activityMap[id] {
            return responseData.responseData
        }
        return nil
    }
    
    public func getAllActivities() -> [ZNetworkActivity] {
        var activities = [ZNetworkActivity]()
//        queue.sync {
            activities = activityIds.compactMap({return activityMap[$0]})
//        }
        return activities
    }
    
    
//    private func remove(activity: ZNetworkActivity) {
//        synchronize(callback: { [unowned self] in
//            self.activityMap.removeValue(forKey: activity.id)
//            if let index = self.activityIds.firstIndex(of: activity.id) {
//                self.activityIds.remove(at: index)
//            }
//            ZNotificationCenter.shared.notify(onMainThread: true, ZActivityObserver.self) { (observer) in
//                observer.activityRemoved(activity: activity)
//            }
//            self.checkLimit()
//        }, async: false)
//    }
//
    
//    func synchronize(callback: @escaping () -> (), async: Bool) {
//        if DispatchQueue.getSpecific(key: ZActivityDataManager.queueIdentifierKey) == ZActivityDataManager.queueIdentifierValue {
//            callback()
//        }
//        else {
//            if async {
//                queue.async {
//                    callback()
//                }
//            }
//            else {
//                queue.sync {
//                    callback()
//                }
//            }
//        }
//    }
//
    public func startTracking() {
        ZNotificationCenter.shared.add(observer: self, for: ZTaskInfoObserver.self)
    }
    
    private func removeTracking() {
        ZNotificationCenter.shared.remove(observer: self, for: ZTaskInfoObserver.self)
    }
    
//    private func checkLimit() {
//        synchronize(callback: { [unowned self] in
//            while self.activityIds.count > self.activityLimit {
//                var activity: ZNetworkActivity?
//                activity = self.activityMap[self.activityIds[0]]
//                if activity != nil {
//                    self.remove(activity: activity!)
//                }
//            }
//        }, async: false)
//    }
    
    public func removeAllData() {
//        queue.sync {
            activityMap = [:]
            activityIds = []
//        }
    }
    
    
    public func added(task: ZTaskInfo) {
        let activity = convert(task: task)
        add(activity: activity)
    }
    
    public func updated(task: ZTaskInfo) {
        update(activity: convert(task: task))
    }
    
    public func ended(task: ZTaskInfo) {
        update(activity: convert(task: task))
//        if task.responseData != nil && ZActivityDataManager.shared.canTrack == true {
//            ZActivityDataManager.database.saveResponseData(id: String(task.id), responseData: task.responseData!)
//        }
    }
    
    private func convert(task: ZTaskInfo) -> ZNetworkActivity {
        let activity = ZNetworkActivity(id: String(task.id))
        activity.task = task.task
        activity.userIdentifier = task.userIdentifier
        activity.priority = ZNetworkActivity.Priority(rawValue: task.priority.rawValue)
        activity.startTime = task.startTime
        activity.endTime = task.endTime
        activity.groupId = task.metaData?.groupId
        activity.groupActionName = task.metaData?.groupActionName
        activity.isUserInitiated = task.metaData?.isUserInitiated
        activity.moduleName = task.metaData?.moduleName
        activity.apiName = task.metaData?.apiName
        activity.request = task.request
        return activity
    }
    
}

import Foundation

public class ZBaseActivity {
    public var id: String
    public var groupId: String?
    public var groupActionName: String?
    
    public init(id: String) {
        self.id = id
    }
}

public class ZNetworkActivity: ZBaseActivity {
    
    public enum Priority: String {
        case low
        case medium
        case high
    }
    
    public var task: URLSessionTask?
    public var userIdentifier: String?
    public var priority: Priority?
    public var startTime: Date?
    public var endTime: Date? {
        didSet {
            if let startTime = self.startTime, let endTime = self.endTime {
                totalTimeTaken = endTime.timeIntervalSince(startTime)
            }
        }
    }
    public var totalTimeTaken: TimeInterval? = nil
    public var responseData: Data?
    public var isUserInitiated: Bool?
    public var apiName: String?
    public var moduleName: String?
    public var speed: ZNetworkSpeed = .normal
    public var request: URLRequest?
}


public enum ZNetworkSpeed {
    case verySlow
    case slow
    case normal
}

public protocol ZNetworkSpeedObserver {
    func networkSpeedUpdate(speed: ZNetworkSpeed)
}

public class ZNetworkSpeedTracker {
    
    private var appSpeed: ZNetworkSpeed = .normal
    private var speedChangeCounter: Int = 0 {
        didSet {
            if speedChangeCounter == 5 {
                speedChangeCounter = 0
                appSpeed = appSpeed == .normal ? .verySlow : .normal
                ZNotificationCenter.shared.notify(onMainThread: true, ZNetworkSpeedObserver.self) {[weak self] (observer) in
                    if let speed = self?.appSpeed {
                        observer.networkSpeedUpdate(speed: speed)
                    }
                }
            }
        }
    }
    
    private var speedPercent: [String: (Int64, Double)] = [:]
//    public var minTimeToNotMarkSlow: TimeInterval = 3
    
    func findSpeed(activity: ZNetworkActivity) -> ZNetworkSpeed {
        var currentSpeed: ZNetworkSpeed = .normal
        guard let apiName = activity.apiName, let startTime = activity.startTime, let endTime = activity.endTime else {
            if let startTime = activity.startTime, let endTime = activity.endTime {
                let timeTaken = endTime.timeIntervalSince1970 - startTime.timeIntervalSince1970
                if timeTaken > 3 {
                    return .verySlow
                } else if timeTaken > 1 {
                    return .slow
                } else {
                    return .normal
                }
            }
            return currentSpeed
        }
        if let responseData = ZActivityDataManager.shared.getResponseData(id: activity.id), responseData.count > 0 {
            let timeTaken = endTime.timeIntervalSince1970 - startTime.timeIntervalSince1970
            let speed = Double(responseData.count) / timeTaken
            if let (count, average) = speedPercent[apiName] {
                if timeTaken > 3 {
                    currentSpeed = average > (speed + (speed * 0.2)) ? .verySlow : .normal
                } else if timeTaken > 1 {
                    currentSpeed = average > (speed + (speed * 0.2)) ? .slow : .normal
                }
                speedPercent[apiName] = (count+1, ((average * Double(count)) + speed) / Double(count + 1))
            } else {
                speedPercent[apiName] = (1, speed)
            }
        } else {
            //Need to handle for timeouts
        }
        if appSpeed != currentSpeed {
            speedChangeCounter += 1
        }
        return currentSpeed
    }
    
}

extension ZNetworkSpeedTracker: ZTaskInfoObserver {
    
    public func added(task: ZTaskInfo) {}
    
    public func updated(task: ZTaskInfo) {}
    
    public func ended(task: ZTaskInfo) {
        
    }
    
}


class ZActivityListPresenter {
    
    var isSegmented : Bool?
    
    weak var activityListView: ZActivityListViewContract?
    
    var segmentedActivities: [ZBaseActivity] = []
    
    init() {
        ZNotificationCenter.shared.add(observer: self, for: ZActivityObserver.self)
    }
    
    func getActivityResponseData(id: String) -> Data? {
        let responseData = ZActivityDataManager.shared.getResponseData(id: id)
        return responseData
    }
    
    func getAllActivites() {
        let activities = ZActivityDataManager.shared.getAllActivities()
        activityListView?.showAllActivities(activities: activities)
    }
    
    func clearAllActivities() {
        ZActivityDataManager.shared.removeAllData()
    }
    
}

extension ZActivityListPresenter : ZActivityObserver {
    func activityAdded(activity: ZNetworkActivity) {
        activityListView?.addActivity(activity: activity)
    }
    
    func activityUpdated(activity: ZNetworkActivity) {
        activityListView?.updateActivity(activity: activity)
    }
    
    func activityRemoved(activity: ZNetworkActivity) {
        activityListView?.removeActivity(activity: activity)
    }
    
}



public class NetworkCallListVC : UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    let networkCallTableView = UITableView(frame: .zero, style: .plain)
    var activityItems : [ZNetworkActivity] = []
    let presenter = ZActivityListPresenter()
     
    public override func loadView() {
        super.loadView()
        presenter.getAllActivites()
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        presenter.activityListView = self
       
        view.backgroundColor = .black
        view.addSubview(networkCallTableView)
        networkCallTableView.delegate = self
        networkCallTableView.dataSource = self
        
        networkCallTableView.register(StationDetailsTableViewCell.self, forCellReuseIdentifier: "Header")
        networkCallTableView.register(StationDetailsTableViewCell.self, forCellReuseIdentifier: StationDetailsTableViewCell.identifier)
        
        setConstraints()
        
    }
    
    
    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
    }
    func setConstraints(){
        
        var constraints = [NSLayoutConstraint]()
        
        networkCallTableView.translatesAutoresizingMaskIntoConstraints = false
        constraints.append(networkCallTableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor))
        constraints.append(networkCallTableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor))
        constraints.append(networkCallTableView.leftAnchor.constraint(equalTo: view.leftAnchor))
        constraints.append(networkCallTableView.rightAnchor.constraint(equalTo: view.rightAnchor))
        
        NSLayoutConstraint.activate(constraints)
    }
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        activityItems.count + 1
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.row == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "Header", for: indexPath) as! StationDetailsTableViewCell
            
            cell.setLabelValues(stationNameAndCode: "Status", arrTime: "Url", deptTime: "timetaken", runningDay: "id", dist: "starttime")
            cell.selectionStyle = .none
            return cell
        }
        else {
            let cell = tableView.dequeueReusableCell(withIdentifier: StationDetailsTableViewCell.identifier, for: indexPath) as! StationDetailsTableViewCell
            let item = activityItems[indexPath.row]
            cell.setLabelValues(stationNameAndCode: getActivityStatus(activity: item), arrTime: item.request?.url?.absoluteString ?? " Nothing ", deptTime: "\(item.totalTimeTaken)", runningDay: item.id, dist: "\(item.startTime)")
            cell.selectionStyle = .none
            return cell
        }
    }
    
    
    private func getActivityStatus(activity: ZNetworkActivity) -> String {
        
        var toolTip: String = "Running"
        
        if activity.task?.state == .running || activity.task?.state == .suspended {
            return toolTip
        }
        else {
            if activity.task?.error != nil {
                toolTip = "Failure"
            }
            let urlResponse = activity.task?.response as? HTTPURLResponse
            if urlResponse == nil {
              toolTip = "Failure"
            } else {
                toolTip = "\(urlResponse!.statusCode)"
            }
        }
        return toolTip
    }
    
}

extension NetworkCallListVC: ZActivityListViewContract {
    func showAllActivities(activities: [ZNetworkActivity]) {
        self.activityItems = activities
        networkCallTableView.reloadData()
    }
    
    func addActivity(activity: ZNetworkActivity) {
        activityItems.append(activity)
        networkCallTableView.reloadData()
    }
    
    func updateActivity(activity: ZNetworkActivity) {
        removeActivity(activity: activity)
        activityItems.append(activity)
        networkCallTableView.reloadData()
    }
    
    func removeActivity(activity: ZNetworkActivity) {
        activityItems.removeAll { act in
            return act.id == activity.id
        }
        networkCallTableView.reloadData()
    }
    
    
}


protocol ZActivityListViewContract: AnyObject {
    
    func showAllActivities(activities: [ZNetworkActivity])
    func addActivity(activity: ZNetworkActivity)
    func updateActivity(activity: ZNetworkActivity)
    func removeActivity(activity: ZNetworkActivity)
    
}

class StationDetailsTableViewCell: UITableViewCell {
    
    
    static let identifier = "StationDetailsTableViewCell"
    
    let stationNameAndCodeLabel : UILabel = {
        let label = UILabel()
        label.textAlignment = .left
        label.font = .preferredFont(forTextStyle: .subheadline)
        label.numberOfLines = 0
        return label
    }()
    
   
    
    let arrTimeLabel : UILabel = {
        let label = UILabel()
        label.textAlignment = .justified
        label.font = .preferredFont(forTextStyle: .subheadline)
        label.numberOfLines = 0
        return label
    }()
    
    let depTimeLabel : UILabel = {
        let label = UILabel()
        label.textAlignment = .justified
        label.font = .preferredFont(forTextStyle: .subheadline)
        label.numberOfLines = 0
        return label
    }()
    
    let runningDayLabel : UILabel = {
        let label = UILabel()
        label.textAlignment = .left
        label.font = .preferredFont(forTextStyle: .subheadline)

        return label
    }()
    
    let distLabel : UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.font = .preferredFont(forTextStyle: .subheadline)
        label.numberOfLines = 0
        return label
    }()
    
    var bottomAnchorConstraint : NSLayoutConstraint? = nil
    
    
    
    

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        contentView.addSubview(stationNameAndCodeLabel)
        contentView.addSubview(arrTimeLabel)
        contentView.addSubview(depTimeLabel)
        contentView.addSubview(runningDayLabel)
        contentView.addSubview(distLabel)
        
        setConstraints()
        
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setConstraints(){
        
        var constraints = [NSLayoutConstraint]()
        
        stationNameAndCodeLabel.translatesAutoresizingMaskIntoConstraints = false
        constraints.append(stationNameAndCodeLabel.topAnchor.constraint(equalTo: contentView.topAnchor,constant: 10))
        
        constraints.append(stationNameAndCodeLabel.leftAnchor.constraint(equalTo: contentView.leftAnchor,constant: 20))
        constraints.append(stationNameAndCodeLabel.widthAnchor.constraint(equalTo: contentView.widthAnchor,multiplier: 0.4))
        
        arrTimeLabel.translatesAutoresizingMaskIntoConstraints = false
        constraints.append(arrTimeLabel.topAnchor.constraint(equalTo: stationNameAndCodeLabel.topAnchor))
//        constraints.append(arrTimeLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor,constant: -5))
        constraints.append(arrTimeLabel.leftAnchor.constraint(equalTo: stationNameAndCodeLabel.rightAnchor,constant: 10))
        constraints.append(arrTimeLabel.widthAnchor.constraint(equalTo: contentView.widthAnchor,multiplier: 0.13))
        
        depTimeLabel.translatesAutoresizingMaskIntoConstraints = false
        constraints.append(depTimeLabel.topAnchor.constraint(equalTo: stationNameAndCodeLabel.topAnchor))
//        constraints.append(depTimeLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor,constant: -5))
        constraints.append(depTimeLabel.leftAnchor.constraint(equalTo: arrTimeLabel.rightAnchor,constant: 5))
        constraints.append(depTimeLabel.widthAnchor.constraint(equalTo: contentView.widthAnchor,multiplier: 0.13))
        
        runningDayLabel.translatesAutoresizingMaskIntoConstraints = false
        constraints.append(runningDayLabel.topAnchor.constraint(equalTo: stationNameAndCodeLabel.topAnchor))
//        constraints.append(runningDayLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor,constant: -5))
        constraints.append(runningDayLabel.leftAnchor.constraint(equalTo: depTimeLabel.rightAnchor,constant: 10))
        constraints.append(runningDayLabel.widthAnchor.constraint(equalTo: contentView.widthAnchor,multiplier: 0.1))
        
        distLabel.translatesAutoresizingMaskIntoConstraints = false
        constraints.append(distLabel.topAnchor.constraint(equalTo: stationNameAndCodeLabel.topAnchor))
//        constraints.append(distLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor,constant: -5))
        constraints.append(distLabel.rightAnchor.constraint(equalTo: contentView.rightAnchor,constant: -10))
        constraints.append(distLabel.widthAnchor.constraint(equalTo: contentView.widthAnchor,multiplier: 0.13))
        
        
        
        
        NSLayoutConstraint.activate(constraints)
    }
    
    func setLabelValues(stationNameAndCode : String,arrTime:String,deptTime:String,runningDay:String,dist:String){
        
        if stationNameAndCode == "Station Name"{
            bottomAnchorConstraint = depTimeLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor,constant: -10)
            bottomAnchorConstraint!.isActive = true
            arrTimeLabel.textAlignment = .left
            depTimeLabel.textAlignment = .left
            arrTimeLabel.textColor = .systemGray
            depTimeLabel.textColor = .systemGray
            stationNameAndCodeLabel.textColor = .systemGray
            runningDayLabel.textColor = .systemGray
            distLabel.textColor = .systemGray
        }
        
        else{
            bottomAnchorConstraint = stationNameAndCodeLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor,constant: -10)
            bottomAnchorConstraint!.isActive = true
        }
        
        stationNameAndCodeLabel.text = stationNameAndCode
        arrTimeLabel.text = arrTime
        depTimeLabel.text = deptTime
        runningDayLabel.text = runningDay
        distLabel.text = dist
        
    }
    
    
}


