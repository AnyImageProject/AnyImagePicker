//
//  AssetCell.swift
//  AnyImagePicker
//
//  Created by 刘栋 on 2019/9/17.
//  Copyright © 2019 anotheren.com. All rights reserved.
//

import UIKit

final class AssetCell: UICollectionViewCell {
    
    private lazy var imageView: UIImageView = {
        let view = UIImageView(frame: .zero)
        view.contentMode = .scaleAspectFill
        view.layer.masksToBounds = true
        return view
    }()
    private lazy var gifLabel: UILabel = {
        let view = UILabel()
        view.isHidden = true
        view.text = "GIF"
        view.textColor = UIColor.white
        view.font = UIFont.systemFont(ofSize: 16)
        return view
    }()
    private lazy var videoView: VideoView = {
        let view = VideoView()
        view.isHidden = true
        return view
    }()
    private lazy var selectdCoverView: UIView = {
        let view = UIView()
        view.isHidden = true
        view.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        return view
    }()
    private lazy var unableCoverView: UIView = {
        let view = UIView()
        view.isHidden = true
        view.backgroundColor = UIColor.white.withAlphaComponent(0.5)
        return view
    }()
    private(set) lazy var boxCoverView: UIView = {
        let view = UIView()
        view.isHidden = true
        view.layer.borderWidth = 3
        view.layer.borderColor = UIColor.wechat_green.cgColor
        return view
    }()
    private(set) lazy var selectButton: NumberCircleButton = {
        let view = NumberCircleButton(style: .default)
        return view
    }()
    
    override func prepareForReuse() {
        super.prepareForReuse()
        selectdCoverView.isHidden = true
        gifLabel.isHidden = true
        videoView.isHidden = true
        unableCoverView.isHidden = true
        boxCoverView.isHidden = true
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupView() {
        addSubview(imageView)
        addSubview(selectdCoverView)
        addSubview(gifLabel)
        addSubview(videoView)
        addSubview(unableCoverView)
        addSubview(boxCoverView)
        addSubview(selectButton)
        
        imageView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }
        selectdCoverView.snp.makeConstraints { (maker) in
            maker.edges.equalToSuperview()
        }
        gifLabel.snp.makeConstraints { (maker) in
            maker.left.bottom.equalToSuperview().inset(5)
        }
        videoView.snp.makeConstraints { (maker) in
            maker.edges.equalToSuperview()
        }
        unableCoverView.snp.makeConstraints { (maker) in
            maker.edges.equalToSuperview()
        }
        boxCoverView.snp.makeConstraints { (maker) in
            maker.edges.equalToSuperview()
        }
        selectButton.snp.makeConstraints { (maker) in
            maker.top.right.equalToSuperview()
            maker.width.height.equalTo(30)
        }
    }
}

extension AssetCell {
    
    var image: UIImage? {
        return imageView.image
    }
}

extension AssetCell {
    
    func setContent(_ asset: Asset, isPreview: Bool = false) {
        PhotoManager.shared.requestImage(for: asset.asset, width: 100*UIScreen.main.nativeScale, completion: { [weak self] (image, info, isDegraded) in
            guard let self = self else { return }
            self.imageView.image = image
            if asset.type == .video && !isPreview {
                // TODO:
                self.videoView.setVideoTime(0)
            }
        })
        
        switch asset.type {
        case .photoGif:
            gifLabel.isHidden = false
        case .video:
            videoView.isHidden = false
        default:
            break
        }
        
        if !isPreview {
            // TODO: setNum
            selectButton.setNum(1, isSelected: asset.isSelected, animated: false)
            selectdCoverView.isHidden = !asset.isSelected
//            unableCoverView.isHidden = !(selectCount == max && !asset.isSelected) // TODO:
        }
    }
}