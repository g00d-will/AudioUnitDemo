//
//  ViewController.swift
//  AudioUnitDemo
//
//  Created by Will on 2024/8/28.
//

import UIKit
import SnapKit
import Then

class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    // 仅初始化原始对象
    private let titleLabel = UILabel()
    private let descriptionLabel = UILabel()
    private let actionButton = UIButton(type: .system)
    private let playButton = UIButton(type: .system)
    private let pauseButton = UIButton(type: .system)
    private let resumeButton = UIButton(type: .system)
    private let replayButton = UIButton(type: .system)
    private let stopButton = UIButton(type: .system)
    
    private let tableView = UITableView()
    
    // 存储PCM文件路径
    private var pcmFiles: [String] = []
    private var selectedPCMFile: String?
    
    // 音频播放器
    private var audioPlayer: AudioStreamPlayer?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // 设置背景颜色
        view.backgroundColor = .white
        
        // 设置 TableView 代理和数据源
        tableView.delegate = self
        tableView.dataSource = self
        
        // 初始化和布局UI
        buildUI()
    }
    
    // 初始化和布局 UI 元素
    private func buildUI() {
        
        titleLabel.do {
            $0.text = "AudioUnitDemo"
            $0.font = UIFont.boldSystemFont(ofSize: 24)
            $0.textColor = .black
            $0.textAlignment = .center
        }
        
        descriptionLabel.do {
            $0.text = "使用AudioUnit处理音频,模仿流式数据的播放;实现播放,暂停,继续,重播等功能"
            $0.font = UIFont.systemFont(ofSize: 16)
            $0.textColor = .darkGray
            $0.textAlignment = .center
            $0.numberOfLines = 0
        }
        
        actionButton.do {
            $0.setTitle("Load PCM", for: .normal)
            $0.titleLabel?.font = UIFont.boldSystemFont(ofSize: 18)
            $0.setTitleColor(.white, for: .normal)
            $0.backgroundColor = .systemBlue
            $0.layer.cornerRadius = 8
            $0.addTarget(self, action: #selector(didTapActionButton), for: .touchUpInside)
        }
        
        playButton.do {
            $0.setTitle("Play", for: .normal)
            $0.titleLabel?.font = UIFont.systemFont(ofSize: 16)
            $0.addTarget(self, action: #selector(playAudio), for: .touchUpInside)
        }
        
        pauseButton.do {
            $0.setTitle("Pause", for: .normal)
            $0.titleLabel?.font = UIFont.systemFont(ofSize: 16)
            $0.addTarget(self, action: #selector(pauseAudio), for: .touchUpInside)
        }
        
        resumeButton.do {
            $0.setTitle("Resume", for: .normal)
            $0.titleLabel?.font = UIFont.systemFont(ofSize: 16)
            $0.addTarget(self, action: #selector(resumeAudio), for: .touchUpInside)
        }
        
        replayButton.do {
            $0.setTitle("Replay", for: .normal)
            $0.titleLabel?.font = UIFont.systemFont(ofSize: 16)
            $0.addTarget(self, action: #selector(replayAudio), for: .touchUpInside)
        }
        
        stopButton.do {
            $0.setTitle("Stop", for: .normal)
            $0.titleLabel?.font = UIFont.systemFont(ofSize: 16)
            $0.addTarget(self, action: #selector(stopAudio), for: .touchUpInside)
        }
        
        tableView.do {
            $0.register(UITableViewCell.self, forCellReuseIdentifier: "kCellIdentifier")
        }
        
        // 添加子视图
        view.addSubview(titleLabel)
        view.addSubview(descriptionLabel)
        view.addSubview(actionButton)
        view.addSubview(playButton)
        view.addSubview(pauseButton)
        view.addSubview(resumeButton)
        view.addSubview(replayButton)
        view.addSubview(stopButton)
        view.addSubview(tableView)
        
        // 使用 SnapKit 进行布局
        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(20)
            make.centerX.equalToSuperview()
        }
        
        descriptionLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(0)
            make.left.equalToSuperview().offset(20)
            make.right.equalToSuperview().offset(-20)
        }
        
        actionButton.snp.makeConstraints { make in
            make.top.equalTo(descriptionLabel.snp.bottom).offset(20)
            make.centerX.equalToSuperview()
            make.width.equalTo(200)
            make.height.equalTo(50)
        }
        
        playButton.snp.makeConstraints { make in
            make.top.equalTo(actionButton.snp.bottom).offset(20)
            make.left.equalToSuperview().offset(5)
            make.width.equalTo(60)
            make.height.equalTo(40)
        }
        
        pauseButton.snp.makeConstraints { make in
            make.top.equalTo(actionButton.snp.bottom).offset(20)
            make.left.equalTo(playButton.snp.right).offset(20)
            make.width.equalTo(60)
            make.height.equalTo(40)
        }
        
        resumeButton.snp.makeConstraints { make in
            make.top.equalTo(actionButton.snp.bottom).offset(20)
            make.left.equalTo(pauseButton.snp.right).offset(20)
            make.width.equalTo(60)
            make.height.equalTo(40)
        }
        
        replayButton.snp.makeConstraints { make in
            make.top.equalTo(actionButton.snp.bottom).offset(20)
            make.left.equalTo(resumeButton.snp.right).offset(20)
            make.width.equalTo(60)
            make.height.equalTo(40)
        }
        
        stopButton.snp.makeConstraints { make in
            make.top.equalTo(actionButton.snp.bottom).offset(20)
            make.left.equalTo(replayButton.snp.right).offset(20)
            make.width.equalTo(60)
            make.height.equalTo(40)
        }
        
        tableView.snp.makeConstraints { make in
            make.top.equalTo(playButton.snp.bottom).offset(20)
            make.left.equalToSuperview().offset(20)
            make.right.equalToSuperview().offset(-20)
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).offset(-20)
        }
    }
    
    // 加载PCM文件列表
    private func loadPCMFiles() {
        if let bundlePath = Bundle.main.path(forResource: "PCMResource", ofType: "bundle"),
           let bundle = Bundle(path: bundlePath) {
            do {
                pcmFiles = try FileManager.default.contentsOfDirectory(atPath: bundle.resourcePath!)
                    .filter { $0.hasSuffix(".wav") }
                    .map { bundlePath + "/" + $0 }
                print("loadPCMFiles:\(pcmFiles) ")
            } catch {
                print("Error loading PCM files: \(error)")
            }
        }
    }
    
    // UITableView DataSource and Delegate
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return pcmFiles.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "kCellIdentifier", for: indexPath)
        cell.textLabel?.text = (pcmFiles[indexPath.row] as NSString).lastPathComponent
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        selectedPCMFile = pcmFiles[indexPath.row]
        print("Selected file: \(selectedPCMFile!)")
        audioPlayer?.stop()  // 确保停止当前音频播放
        setupPlayer(with: selectedPCMFile!)
        playAudio()
    }
    
    // 初始化音频播放器
    private func setupPlayer(with filePath: String) {
        audioPlayer = AudioStreamPlayer(filePaths: [filePath])
    }
    
    // 音频控制操作
    @objc private func playAudio() {
        print("Play audio")
        audioPlayer?.play()
    }
    
    @objc private func pauseAudio() {
        print("Pause audio")
        audioPlayer?.pause()
    }
    
    @objc private func resumeAudio() {
        print("Resume audio")
        audioPlayer?.resume()
    }
    
    @objc private func replayAudio() {
        print("Replay audio")
        audioPlayer?.replay()
    }
    
    @objc private func stopAudio() {
        print("Replay audio")
        audioPlayer?.stop()
    }
    
    @objc private func didTapActionButton() {
        // 加载PCM文件列表
        loadPCMFiles()
        tableView.reloadData()
    }
    
}
