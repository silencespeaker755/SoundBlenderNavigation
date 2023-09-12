// 主要影片播放
import UIKit
import SceneKit
import CoreMotion
import SpriteKit
import AVFoundation
import Foundation

class PanoViewController: UIViewController, CMHeadphoneMotionManagerDelegate {

    private let headphoneMotionManager = CMHeadphoneMotionManager()
    private let motionManager = CMMotionManager()
    private let cameraNode = SCNNode()
    private let audioController = GVRAudioEngine(renderingMode: kRenderingModeBinauralHighQuality)

    public  var videoFilename : String = ""
    private var player: AVPlayer!
    private var timeObserverToken: Any!
    private var playing_state : Bool = false
    private var playerCurrentItem : AVPlayerItem!
    private var playerCurrentItemDuration : Float!
    

    @IBOutlet weak var sceneView: SCNView!
    @IBOutlet weak var playButton: UIButton!
    @IBOutlet weak var stopButton: UIButton!
    @IBOutlet weak var videoSlider: UISlider!
    @IBOutlet weak var videoTime: UILabel!
    
    // 口述音檔的ID
    var ID : Int = 0 // 不是Json中的id_tracks的id，是一個id?_tracks?就一個ID
    var OID : Int = 0
    var SceneCount : Int = 0
    
    // Json檔使用
    private var TrackName:Array<String> = []
    private var Inoutdoor: Array<Bool> = []
    private var ValueName: Array<Int> = []
    private var tracksName : Array<String> = [] // 讀Json中的“tracks_name“，以利後面讀到各tracks的內容
    private var statusName : Array<String> = [] //之後狀態要用的
    private var tracknameCount :Int = 0 // 一共有幾個口述音檔
    private var FileName : Array<Int> = [] // 所有口述音檔的名稱（ts）
    
    private var FileSETime : [Int: Array<Double>] = [:] // 字典key：口述音檔的名稱（ts）,value:[startTime, endTime, duration]
    private var pinningArr :  Array<Bool> = [] // 該口述音檔是否pinning
    private var File_Point_Count : Array<Int> = [] // 該口述音檔有無point，無會存入-1，有則是存入該口述音檔的point數
    private var IdPositionStamp : Array<Double> = [] // 該id裡有point，point中的"time_stamp_audio"
    private var IdPositionPoint :  [Int:  Array<Double>] = [:] // 對照上面"time_stamp_audio"的編號，存其xyz 3D聲音位置
    
    
    // 播放口述音檔控制用（與UI播放鍵控制有連貫）
    private var timer = Timer()
    private var SceneTimer = Timer()
    private var pointTimer = Timer()
    private var isSlide : Bool = false // 切影片時間
    private var isVideoPause : Bool = false //
    private var isVideoStop : Bool = false
    private var isSceneVideoPush : Bool = false
    
//    private var soundSourceIDs : Array<Int32> = [] // 轉成GVRAudioEngine可以讀的soundId形式
    private var soundSourceID : Int32 = 0
    private var OsoundID : Int32 = 0
    private var headData: CMDeviceMotion?
    private var headDataX : Float = 0.00
    private var headDataY : Float = 0.00
    private var isFindObject : Bool = false
    private var isScenePlay : Bool = false
    private var isloadScene : Bool = false
    private var isloadObject : Bool = false
    private var isSceneClean : Bool = true
    private var isSceneArrayDone : Bool = true
    private var ObjectID : Array<Int> = []
    private var SceneID : Int = 0
    private var SceneIDArry : Array<Int> = []
    private var Scene : Double = 0
    private var SceneArray : Array<Int> = []
    private var SceneTArray : Array<Double> = []
    private var SceneTrack : [Double: Array<String>] = [:]
    private var SceneTs : [Double: Array<Int>] = [:]
    private var SceneTime : [Double: Array<Double>] = [:]
    private var SceneSoundID : Array<Int32> = []
    private var SceneKey :Array<Double> = []
    private var headTX : Array<Float> = []
    private var headTY : Array<Float> = []
    
    /* ------------------------------------ UI播放鍵控制 -------------------------------------------*/
    // UI播放、暫停
    @IBAction func playAndPause(_ sender: UIButton) {
        playing_state = !playing_state
        if playing_state {
//            pointTimer.invalidate()
            playButton.setImage(UIImage(systemName: "pause.fill"), for: .normal)
            player.play()
            
            // 口述音檔
            resumeAudio(soundSourceID)
            audioController?.start()
            
            isVideoPause = false
            if isVideoStop == true{
                soundSource(ID)
                isVideoStop = false
            }
            isSceneVideoPush = false
            pointTimer.invalidate()
            
        } else {
            playButton.setImage(UIImage(systemName: "play.fill"), for: .normal)
            player.pause()
            // 口述音檔
            audioController?.stop()
            pauseAudio(soundSourceID)
            isVideoPause = true
            isSceneVideoPush = true
        }
    }
    // UI播放、暫停
    @IBAction func SceneplayAndPause(_ sender: UIButton) {
        isSceneVideoPush = !isSceneVideoPush
        print("SceneButton: \(isSceneVideoPush)")
        if isSceneVideoPush == false{
            for i in 0..<SceneSoundID.count{
                stopAudio(SceneSoundID[i])
            }
            SceneTimer.invalidate()
            pointTimer.invalidate()
            playing_state = true
            
            playButton.setImage(UIImage(systemName: "pause.fill"), for: .normal)
            player.play()
            
            // 口述音檔
            resumeAudio(soundSourceID)
            audioController?.start()
            
            if isVideoStop == true{
                soundSource(ID)
                isVideoStop = false
            }
            print("Scene: \(Scene)")
        } else {
            playing_state = false
            playButton.setImage(UIImage(systemName: "play.fill"), for: .normal)
            player.pause()
            // 口述音檔
            audioController?.stop()
            pauseAudio(soundSourceID)
            
        }
    }
    
    // UI結束
    @IBAction func stopVideo (_ sender: UIButton) {
        let myTime = CMTime(seconds: 0.0, preferredTimescale: 60000)
        playButton.setImage(UIImage(systemName: "play.fill"), for: .normal)
        if playing_state {
            playing_state = !playing_state
        }
        player.seek(to: myTime)
        player.pause()
        videoTime.text = secsToMin(Float(myTime.seconds))
        // 口述音檔
        stopAudio(soundSourceID)
        for i in 0..<SceneSoundID.count{
            stopAudio(SceneSoundID[i])
        }
        stopAudio(OsoundID)
        ObjectID.removeAll() //初始化
        headTX.removeAll()
        headTY.removeAll()
        isVideoStop = true
        isSceneVideoPush = true
    }
    
    // slider 轉跳
    @IBAction func skimVideo (_ sender: UISlider) {
       // print("slider value changed", sender.value)
        let myTime = CMTime(seconds: Double(sender.value), preferredTimescale: 60000)
        player.seek(to: myTime)
        videoTime.text = secsToMin(Float(myTime.seconds))
        // 口述音檔用
        stopAudio(soundSourceID)
        isSlide = true
    }
    
    // 回到主畫面
    @IBAction func backToTable (_ sender: UIButton) {
        player.pause()
//        audioController?.stop()
        for i in 0..<SceneSoundID.count{
            stopAudio(SceneSoundID[i])
        }
        stopAudio(soundSourceID)
        stopAudio(OsoundID)
        ObjectID.removeAll() //初始化
        headTX.removeAll()
        headTY.removeAll()
        self.dismiss(animated: true, completion: nil)
    }

    // 時間-秒轉分
    func secsToMin(_ amounts: Float) -> String{
        let seconds = Int(amounts.truncatingRemainder(dividingBy: 60.0))
        let minutes = Int(amounts / 60.0)
        return String(format: "%02d", minutes)+":"+String(format: "%02d", seconds)
    }
    
    // 播放時間
    func addPeriodicTimeObserver(_ duration : Any) {
        // Invoke callback every half second
        let interval = CMTime(seconds: 0.1,
                              preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        // Add time observer. Invoke closure on the main queue.
        timeObserverToken =
            player.addPeriodicTimeObserver(forInterval: interval, queue: .main) {
                [weak self] time in
                // update player transport UI
                let currentSecs = self!.player.currentTime().seconds
                self!.videoTime.text = String(currentSecs)
                self!.videoSlider.setValue(Float(currentSecs), animated: true)
                self!.videoTime.text = self!.secsToMin(Float(currentSecs))
        }
    }
    func removePeriodicTimeObserver() {
        if let timeObserverToken = timeObserverToken {
            player.removeTimeObserver(timeObserverToken)
            self.timeObserverToken = nil
        }
    }
    func initilizeVideoSlider( min: Float = 0.0, max: Float){
        videoSlider.minimumValue = min
        videoSlider.maximumValue = max
    }
    /*--------------------------------- 震動 --------------------------------------------------*/
    
    func vibrate() {
        AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
    }
    /*--------------------------------- 讀json檔 --------------------------------------------------*/
    private var statueN: String = ""
    // 讀Json前要先定義要讀的Json檔的形式
    struct Info: Codable {
        let video_name: String
        let layers: [Layers]
        struct Layers: Codable {
            let name: String
            let values: [Values]
            struct Values: Codable {
                let time: Double
                let description_type:String?
                let tracks_name: Array<String>?
                let inoutdoor: Bool?
            }
        }
    }
    private var timeStamp : Array<Double> = []
    // timeStamp：先知道json有幾個大的時間區塊（每個values裡的time）
    func loadTimeStamp(jsonName: String) {
        do {
            let url = Bundle.main.url(forResource: jsonName, withExtension: "json")!
            let data = try Data(contentsOf: url)
            let result = try JSONDecoder().decode(Info.self, from: data) // json前面是[]再加[]
            // 固定從4開始：description
            for i in 0..<result.layers[4].values.count{
                timeStamp.append(result.layers[4].values[i].time)
                if result.layers[4].values[i].description_type == "scene"{
                    SceneTrack[result.layers[4].values[i].time] = result.layers[4].values[i].tracks_name
                }
            }
        } catch {
            print(error)
        }
    }
    // 根據tracks_name抓裡面的資訊 （用不同方法抓json的檔案：因為tracks裡面有非規律型的名稱）
    func loadTracksInfo(jsonName: String, id : Int) {
        do {
            let url = Bundle.main.url(forResource: jsonName, withExtension: "json")!
            let data = try Data(contentsOf: url)
            let result = try JSONDecoder().decode(Info.self, from: data)// json前面是[]再加[]
            
            tracksName  = result.layers[4].values[id].tracks_name!
            tracknameCount += tracksName.count
            let json = try! JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String: Any]
            if let layers = json?["layers"] as? [[String: Any]] {
                if let values = layers[4]["values"] as? [[String: Any]] {
                    if let tracks = values[id]["tracks"] as? [String: Any] {
                        let Scenekey = [Double](SceneTrack.keys)
                        for i in Scenekey{
                            SceneArray.removeAll()
                            SceneTArray.removeAll()
                            for j in SceneTrack[i] ?? []{
                                if let Sid_tracks = tracks[j] as? [String: Any] {
                                    let Sts = Sid_tracks["ts"] as? Int
                                    SceneArray.append(Sts!)
                                    SceneTs[i] = SceneArray
                                    let start_time = (Sid_tracks["start_time"] as? Double)!
                                    let pin_time = (Sid_tracks["pin_time"] as? Double)!
                                    SceneTArray.append((Double(start_time)-Double(pin_time)))
                                    SceneTime[i] = SceneTArray
                                }
                            }
                        }
                        
                        for i in 0..<tracksName.count{
                            statusName.append(result.layers[4].values[id].description_type ?? "")
                            Inoutdoor.append(result.layers[4].values[id].inoutdoor!)
                            if let id_tracks = tracks[tracksName[i]] as? [String: Any] {
                                let ts = id_tracks["ts"] as? Int
                                let pinning = id_tracks["pinning"] as? Bool
                                let start_time = id_tracks["start_time"] as? Double
                                let end_time = id_tracks["end_time"] as? Double
                                let duration = id_tracks["duration"] as? Double
                                TrackName.append(tracksName[i])
                                ValueName.append(id)
                                FileName.append(ts!)
                                pinningArr.append(pinning!)
                                
                                FileSETime[ts!]=[start_time!,end_time!,duration!]// 存{音檔檔名:(開始時間,結束時間,期間)
                                //point
                                if let points = id_tracks["points"] as? [[String: Any]] {
                                    // 存哪個音檔要轉換聲音位置
                                    if points.isEmpty{
                                        File_Point_Count.append(-1)
                                    }else{
                                        File_Point_Count.append(points.count)
                                    }
                                }
                            }
                        }
                    }
                }
            }
        } catch {
            print(error)
        }
    }
    // 讀每個ID的points
    func loadPoint(jsonName: String, id : Int) {
        print("point num \(IdPositionPoint.count)")
        // 清空再append
        IdPositionPoint.removeAll()
        IdPositionStamp.removeAll()
        print("point num \(IdPositionPoint.count)")
        do {
            let url = Bundle.main.url(forResource: jsonName, withExtension: "json")!
            let data = try Data(contentsOf: url)
            let json = try! JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String: Any]
            if let layers = json?["layers"] as? [[String: Any]] {
                if let values = layers[4]["values"] as? [[String: Any]] {
                    if let tracks = values[ValueName[id]]["tracks"] as? [String: Any] {
                        if let id_tracks = tracks[TrackName[id]] as? [String: Any] {
                            if let points = id_tracks["points"] as? [[String: Any]] {
                                for k in 0..<points.count{
                                    let time_stamp_audio = points[k]["time_stamp_audio"] as? Double
                                    if let threeD = points[k]["threeD"] as? [String: Any] {
                                        let threeX = threeD["x"] as? Double
                                        let threeY = threeD["y"] as? Double
                                        let threeZ = threeD["z"] as? Double
                                        IdPositionStamp.append(time_stamp_audio!/1000)
                                        IdPositionPoint[k]=[threeX!, threeY!, threeZ!]
                                    }
                                }
                            }
                        }
                    }
                }
            }
        } catch {
            print(error)
        }
        
    }
    /*--------------------------------------- 聲音控制 -------------------------------------------------------*/
    
    // 下載音檔來源
    func soundSource(_ id: Int){
        headphoneMotionManager.delegate = self
        guard headphoneMotionManager.isDeviceMotionAvailable else {return}//沒成立就離開
        audioController?.preloadSoundFile(String(FileName[id])+".mp3")
        soundSourceID = (audioController?.createSoundObject(String(FileName[id])+".mp3"))!
    }
    func OsoundSource(_ id: Int){
        headphoneMotionManager.delegate = self
        guard headphoneMotionManager.isDeviceMotionAvailable else {return}//沒成立就離開
        audioController?.preloadSoundFile(String(FileName[id])+".mp3")
        OsoundID = (audioController?.createSoundObject(String(FileName[id])+".mp3"))!
    }
    func ScenesoundSource(_ key:Double){
        SceneSoundID.removeAll()
        headphoneMotionManager.delegate = self
        guard headphoneMotionManager.isDeviceMotionAvailable else {return}//沒成立就離開
        for i in SceneTs[key] ?? []{
            audioController?.preloadSoundFile(String(i)+".mp3")
            SceneSoundID.append(audioController?.createSoundObject(String(i)+".mp3") ?? 0)
        }
        isloadScene = true;
    }
    
    // 播放該ID的連續聲音
    func soundPlay(_ soundSourceID: Int32, _ id : Int, _ state: String){
        audioController?.start()
        print("now play: \(soundSourceID)")
        setAudioVolume(soundSourceID,volume: 0.5)
        playAudio(soundSourceID)
        print("have sound: \(audioController?.isSoundPlaying(soundSourceID))")
    
        audioController?.enableRoom(false)
        
        // 有point
        if File_Point_Count[id] != -1 && statusName[id] != "object"{
            loadPoint(jsonName: videoFilename, id: id)
            print("3D sound: \(soundSourceID)")
            for j in 0..<IdPositionStamp.count{
                switchPosition(j,soundSourceID)
            }
        }else if statusName[id] == "object" {
            setHead() // 強制聲音在正前方
        }else{
            setAudioPosition(soundSourceID, 0,1,0)
        }
        
        // pinning <- 這裡改暫停
        if statusName[id] == "proceeding" && pinningArr[id] == true{
            // 暫停影片
            print("stop \(id)")
            player.pause()
            // 根據duration開始播放影片
            Timer.scheduledTimer(withTimeInterval: FileSETime[FileName[id]]![2], repeats: false, block: {_ in
                self.player.play()
            })
        }
        
        // slide
        if isSlide == true {
            stopAudio(soundSourceID)
            isSlide = false
        }
    }
    // 沒有環繞音
    func sampleSoundPlay(){
        audioController?.start()
        print("now play: \(soundSourceID)")
        setAudioVolume(soundSourceID,volume: 0.7)
        setAudioPosition(soundSourceID, 0,0,0)
        if statusName[ID] == "proceeding"{
            playAudio(soundSourceID)
            print("have sound: \(audioController?.isSoundPlaying(soundSourceID))")
        }
        // slide
        if isSlide == true {
            stopAudio(soundSourceID)
            isSlide = false
        }
    }
    // 口述聲音位置變換
    func switchPosition(_ switchTimeId: Int, _ soundSourceID: Int32){
        pointTimer = Timer.scheduledTimer(withTimeInterval: (IdPositionStamp[switchTimeId]), repeats: false, block: { _ in
            self.setAudioPosition(soundSourceID,
                                  Float(self.IdPositionPoint[switchTimeId]![0]),
                                  Float(self.IdPositionPoint[switchTimeId]![1]),
                                  Float(self.IdPositionPoint[switchTimeId]![2]))
        })
    }
    // 聲音位置設定 Set the new position and restart the playback.
    func setAudioPosition(_ soundSource:Int32, _ x: Float, _ y: Float, _ z: Float) {
        audioController?.setSoundObjectPosition(
            soundSource,
            x: x,
            y: y,
            z: z)
        audioController?.update()
    }
    
    // 播放聲音
    func playAudio(_ soundSource:Int32) {
        audioController?.playSound(soundSource, loopingEnabled: false)
        
    }
    
    // 暫停並刪除聲音
    func stopAudio(_ soundSource:Int32) {
        audioController?.stopSound(soundSource)
    }
    // 暫停聲音
    func pauseAudio(_ soundSource:Int32) {
        audioController?.pauseSound(soundSource)
    }
    // 暫停聲音
    func resumeAudio(_ soundSource:Int32) {
        audioController?.resumeSound(soundSource)
    }
    
    // be rotated about the listener's head in order to align the components of the soundfield
    func setSoundfieldRotation(_ soundSource:Int32, x: Float, y: Float, z: Float, w: Float) {
        audioController?.setSoundfieldRotation(
            soundSource,
            x: x,
            y: y,
            z: z,
            w: w)
        audioController?.update()
    }
    
    // 控制音量
    func setAudioVolume(_ soundSource:Int32, volume: Float) {
        audioController?.setSoundVolume(soundSource, volume: volume)
        audioController?.update()
    }
    
    // 環境音-室內
    func setRoom(){
        audioController?.setRoomProperties(5, size_y: 5, size_z: 5,
                                           wall_material: kPlywoodPanel,
                                           ceiling_material: kCurtainHeavy,
                                           floor_material:kWoodPanel)
        audioController?.setRoomReverbAdjustments(0.6, timeAdjust: 1.5, brightnessAdjust: 0) // echo
        audioController?.enableRoom(true)
    }
    
    // 會強制user的頭到指定的位置（只限聲音，畫面不會變）
    func setHead(){
        audioController?.setHeadPosition(0, y: 1, z: 0)
    }
    
    // object與頭位置的閾值
    func headObjectPoint() ->Bool {
        var ans = false
        for i in 0..<ObjectID.count{
            let xx = abs(headDataX - headTX[i]) <= 0.5
            let yy = abs(headDataY - headTY[i]) <= 0.5
            print("PX: \(headTX[i]) // HX: \(headDataX)")
            print("PY: \(headTY[i]) // HY: \(headDataY)")
            
            print("XX: \(xx)")
            print("YY: \(yy)")

            if xx && yy {
                ans = true
                OID = ObjectID[i]
            }
        }
        return ans
    }
    
    // 暫停刪除object的閾值
    func stopObjectPoint() ->Bool {
        var ans = false
        for i in 0..<ObjectID.count{
            let xx = abs(headDataX - headTX[i]) <= 3
            let yy = abs(headDataY - headTY[i]) <= 3
            if xx && yy{
                ans = true
            }
        }
        return ans
    }
    /*---------------------------------- 相機與畫面位置 ----------------------------------------------------*/
    func createSphereNode(material: AnyObject?) -> SCNNode {
        let sphere = SCNSphere(radius: 2.0)
        sphere.firstMaterial!.isDoubleSided = true
        sphere.firstMaterial!.diffuse.contents = material
        let sphereNode = SCNNode(geometry: sphere)
        sphereNode.position = SCNVector3Make(0,0,0) // 場景球的位置
        return sphereNode
    }
    
    func configureScene(node sphereNode: SCNNode) {
        // Set the scene
        let scene = SCNScene()
        // sceneView.backgroundColor = [UIColor redColor]
        sceneView.scene = scene
        sceneView.showsStatistics = false
        sceneView.allowsCameraControl = false
        sceneView.backgroundColor = UIColor.blue
        // Camera, ...
        cameraNode.camera = SCNCamera()
        cameraNode.position = SCNVector3Make(0, 0, 0) // 相機位置
        scene.rootNode.addChildNode(sphereNode)
        scene.rootNode.addChildNode(cameraNode)
    }
    
    /*-------------------------------------- 畫面轉換控制 -----------------------------------------------------*/
    
    // 耳機控制畫面
    func startCameraTracking() {
        motionManager.deviceMotionUpdateInterval = 1.0 / 60.0
        headphoneMotionManager.startDeviceMotionUpdates(to: OperationQueue.main) {
            [weak self](data: CMDeviceMotion?, error: Error?) in
            guard let data = data else { return }
            self?.headData = data
            let attitude: CMAttitude = data.attitude
            self?.cameraNode.eulerAngles = SCNVector3Make(Float(attitude.pitch+Double.pi),-Float(attitude.yaw),Float(attitude.roll))
            self?.updateHeadMotion(data)
            
            //聲音的環繞update在這裡，因為需要CMDeviceMotion的數值 // roll z 倒擺頭 yaw y左右 pitch x 上下
            self?.headDataX = -Float(data.attitude.yaw)
            self?.headDataY = Float(data.attitude.pitch)
            if self?.isVideoPause == true && self?.isVideoStop == false{
                // && self?.isSceneVideoPush == false
                if self?.headObjectPoint() == true{
                    self?.isFindObject = false
                    if (self!.videoFilename == "sample"){
                        self!.sampleSoundPlay()
                    }else{
                        if self?.audioController?.isSourceIdValid(self!.OsoundID) == false{
                            self?.OsoundSource(self!.OID)
                        }
                        self!.soundPlay(self!.OsoundID, self!.OID, "o")
                        self!.isFindObject = true
                    }
                    print("object!!!!!!!!!!!!")
                    
                }else if self?.stopObjectPoint() == true{
                    self!.stopAudio(self!.OsoundID)
                }
            }else if self!.isFindObject == true && self?.isVideoPause == false{
                self!.stopAudio(self!.OsoundID)
                self!.isFindObject = false
            }
        }
    }
    // 耳機移動的方向控制
    func updateHeadMotion(_ data: CMDeviceMotion) {
        audioController?.setHeadRotation(   Float(data.attitude.quaternion.x),
                                         y: Float(data.attitude.quaternion.y),
                                         z: Float(data.attitude.quaternion.z),
                                         w: Float(data.attitude.quaternion.w)
        )
        audioController?.update()
    }
    //---------------------------其他背景執行序等等--------------------------------------------------
    // 將timer的執行緒停止 back的時候停止所有的time schedual
    override func viewDidDisappear(_ animated: Bool) {
        headphoneMotionManager.stopDeviceMotionUpdates()
        self.timer.invalidate()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        sceneView.play(self)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    // Lock orientation functions
//    override func viewWillAppear(_ animated: Bool) {
//        super.viewWillAppear(animated)
//        AppDelegate.AppUtility.lockOrientation(UIInterfaceOrientationMask.landscapeLeft, andRotateTo: UIInterfaceOrientation.landscapeLeft)
//        // Or to rotate and lock
//        // AppUtility.lockOrientation(.portrait, andRotateTo: .portrait)
//        
//    }
//    override func viewWillDisappear(_ animated: Bool) {
//        super.viewWillDisappear(animated)
//        // Don't forget to reset when view is being removed
//        AppDelegate.AppUtility.lockOrientation(UIInterfaceOrientationMask.all)
//        headphoneMotionManager.stopDeviceMotionUpdates()
//    }
    
    
    /* !!!!!!!!!!!!!!!!!!!!!!!!!!!!---------------Main-------------------!!!!!!!!!!!!!!!!!!!!!!!!!! */
    override func viewDidLoad() {
        super.viewDidLoad()
        // initialize video
        guard let path = Bundle.main.path(forResource: videoFilename, ofType:"mp4") else {
                    debugPrint("video.m4v not found")
                    return
        }
        player = AVPlayer(url: URL(fileURLWithPath: path))
        playerCurrentItem = player.currentItem
        player.volume = 0.1 // 原影片的聲音
        playerCurrentItemDuration = Float(CMTimeGetSeconds(self.playerCurrentItem.asset.duration))
        addPeriodicTimeObserver(playerCurrentItemDuration!)
        initilizeVideoSlider(max: playerCurrentItemDuration)

        let videoNode = SKVideoNode(avPlayer: player)
        let size = CGSize(width: 1920, height: 1080) //解析度
//        let size = CGSize(width: 1024, height: 512)
        videoNode.size = size
        videoNode.position = CGPoint(x: size.width/2, y: size.height/2)
        let spriteScene = SKScene(size: size)
        spriteScene.addChild(videoNode)
        
        
        let sphereNode = createSphereNode(material:spriteScene)
        configureScene(node: sphereNode)
        //check motion if available
        guard motionManager.isDeviceMotionAvailable else {
            fatalError("Device motion is not available")
        }
        
        //Initialize viewer's view
        startCameraTracking()

        // 口述音檔控制：
        loadTimeStamp(jsonName: videoFilename) // 根據按的影片名稱播放該JSON的口述音檔：目前只能看Jungle的！
       
        // 讀取json檔裡面的資料
        for i in stride(from: 0, through:timeStamp.count-2, by: 2){
            loadTracksInfo(jsonName: videoFilename, id: i)
        }
        
        // 可以看一下所有定義的東西有什麼
        print("timeStamp: \(timeStamp)") // 現在總口述的播放時間與結束時間
        print("tracknamecount: \(tracknameCount)")
        print("TrackName: \(TrackName)")
        print("valueID: \(ValueName)")
        print("filename \(FileName)")

        print("fileSTtime \(FileSETime)")
        print("status \(statusName)")
        print("point_count \(File_Point_Count)")
        print("inoutdoor \(Inoutdoor)")
        print("SceneTrack \(SceneTrack)")
        print("key \([Double](SceneTrack.keys))")
        print("SceneTs\(SceneTs)")
        print("SceneTime\(SceneTime)")
        
        SceneKey = [Double](SceneTrack.keys).sorted()
    
        
        // 每0.01秒會讀一次現在的時間跟timeStamp的時間有無相符，一樣就會播放口述音檔
        let interval = CMTime(seconds: 0.01,preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        player.addPeriodicTimeObserver(forInterval: interval, queue: .main) {[weak self] time in
            let currentSecs = self!.player.currentTime().seconds
            // 換場景刪掉物件
//            print(Double(round(100*currentSecs)/100))
            for j in 0..<self!.SceneKey.count{
                if fabs(self!.SceneKey[j]-Double(round(100*currentSecs)/100)) <= 0.03{
                    self!.ObjectID.removeAll() //初始化
                    self!.headTX.removeAll()
                    self!.headTY.removeAll()
                    print("Del: \(self!.SceneKey[j])")
                }
            }
            for i in 0..<self!.tracknameCount{
                // 播放時間和現在時間相減<=0.005 (影片時間與音檔播放時間相同（誤差0.005）)
                if fabs(self!.FileSETime[self!.FileName[i]]![0]-Double(round(100*currentSecs)/100)) <= 0.008 && self!.isVideoStop == false && self!.isVideoPause == false && self!.isSceneVideoPush == false{
                    self!.ID = i
                    self!.soundSource(i)
                    print(self!.statusName[i])
                    if (self!.videoFilename == "sampleC" || self!.videoFilename == "sampleE"){
                        self!.sampleSoundPlay()
                    }else{
                        if self!.statusName[i] == "object"{
                            //先刪掉原本的口述音
                            self!.stopAudio(self!.soundSourceID)
                            self!.ObjectID.append(self!.ID)
                            self?.loadPoint(jsonName: self!.videoFilename, id: self!.ID)
                            self?.headTX.append(Float(self!.IdPositionPoint[Int(self!.File_Point_Count[self!.ID]/2)]![0])*1.5)
                            self?.headTY.append(Float(self!.IdPositionPoint[Int(self!.File_Point_Count[self!.ID]/2)]![2]))
                            print("object : \(self!.ObjectID)")
                            
                        }else if self!.statusName[i] == "scene"{
                            print(self!.isSceneVideoPush)
//                            self!.SceneID.append(self!.ID)
//                            print(self!.FileSETime[self!.FileName[self!.ID]]![0])
                            for i in 0..<self!.SceneKey.count{
                                if fabs(self!.FileSETime[self!.FileName[self!.ID]]![0] - self!.SceneKey[i]) <= 0.5{
                                    print("change scene")
                                        self!.SceneIDArry.removeAll()
//                                        self!.ObjectID.removeAll() //初始化
//                                        self!.headTX.removeAll()
//                                        self!.headTY.removeAll()
                                        self!.Scene = self!.SceneKey[i]
                                        self!.SceneID = self!.ID
                                        print(self!.SceneID)
                                        self!.isloadScene = false
                                        self!.vibrate()
                                    }
                            }
                            
                        }else{
//                            self!.SceneIDArry.removeAll()
//                            self!.isloadScene = false;
                            self!.soundPlay(self!.soundSourceID, self!.ID, "p")
                            print(self!.ObjectID)
                        }
                    }
                }else if self!.isSceneVideoPush == true && self!.isloadScene == false{
//                    self!.SceneIDArry.removeAll()
                    self!.ScenesoundSource(self!.Scene)
                    print("SceneSoundID\(self!.SceneSoundID)")
                    for p in 0..<self!.SceneSoundID.count{
                        let tmp = self!.SceneID+p
                        self!.SceneIDArry.append(tmp)
                    }
                    print(self!.SceneIDArry)
                    for i in 0..<self!.SceneSoundID.count{
                        self!.SceneTimer = Timer.scheduledTimer(withTimeInterval: (self!.SceneTime[self!.Scene]![i]), repeats: false, block: { _ in
                            self!.soundPlay(self!.SceneSoundID[i], self!.SceneIDArry[i], "s")
                            print("ScenePlay")
                        })
                    }
                    
                }else if self!.isSceneVideoPush == false{
                    for i in 0..<self!.SceneSoundID.count{
                        self!.stopAudio(self!.SceneSoundID[i])
                    }
                    self!.pointTimer.invalidate()
                    self!.SceneTimer.invalidate()
//                    self!.SceneIDArry.removeAll()
                }
            }
        }
    }
}
