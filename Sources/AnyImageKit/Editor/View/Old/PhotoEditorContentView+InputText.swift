//
//  PhotoEditorContentView+InputText.swift
//  AnyImageKit
//
//  Created by 蒋惠 on 2019/12/10.
//  Copyright © 2020 AnyImageProject.org. All rights reserved.
//

import UIKit

// MARK: - Internal
extension PhotoEditorContentView {
    
    @discardableResult
    func addText(data: TextData, add: Bool = true) -> TextImageView {
        if data.frame.isEmpty {
            calculateTextFrame(data: data)
        }
        let textView = TextImageView(data: data)
        textView.deleteButton.addTarget(self, action: #selector(textDeletebuttonTapped(_:)), for: .touchUpInside)
        textView.transform = textView.calculateTransform()
        if add {
            imageView.insertSubview(textView, belowSubview: cropLayerLeave)
            textImageViews.append(textView)
            addTextGestureRecognizer(textView)
        }
        return textView
    }
    
    /// 裁剪结束时更新UI
    func updateTextFrameWhenCropEnd() {
        let scale = imageView.bounds.width / cropContext.lastImageViewBounds.width
        resetTextView(with: scale)
    }
    
    /// 更新UI
    func resetTextView(with scale: CGFloat) {
        var newTextImageViews: [TextImageView] = []
        for textView in textImageViews {
            let originPoint = textView.data.point
            let originScale = textView.data.scale
            let originRotation = textView.data.rotation
            textView.data.point = .zero
            textView.data.scale = 1.0
            textView.data.rotation = 0.0
            textView.transform = textView.calculateTransform()
            
            var frame = textView.frame
            frame.origin.x *= scale
            frame.origin.y *= scale
            frame.size.width *= scale
            frame.size.height *= scale
            textView.data.frame = frame
            textView.data.inset *= scale
            
            let newTextView = addText(data: textView.data, add: false)
            newTextView.data.point = CGPoint(x: originPoint.x * scale, y: originPoint.y * scale)
            newTextView.data.scale = originScale
            newTextView.data.rotation = originRotation
            newTextView.transform = textView.calculateTransform()
            newTextImageViews.append(newTextView)
        }
        
        textImageViews.forEach { $0.removeFromSuperview() }
        textImageViews.removeAll()
        newTextImageViews.forEach {
            imageView.insertSubview($0, belowSubview: cropLayerLeave)
            self.textImageViews.append($0)
            self.addTextGestureRecognizer($0)
        }
    }
    
    func calculateFinalFrame() {
        for textView in textImageViews {
            let data = textView.data
            let originRotation = data.rotation
            data.rotation = 0
            textView.transform = textView.calculateTransform()
            var frame = textView.frame
            frame.origin.x += (data.inset * data.scale)
            frame.origin.y += (data.inset * data.scale)
            frame.size.width -= (data.inset * 2 * data.scale)
            frame.size.height -= (data.inset * 2 * data.scale)
            data.finalFrame = frame
            data.rotation = originRotation
            textView.transform = textView.calculateTransform()
        }
    }
    
    /// 删除隐藏的TextView
    func removeHiddenTextView() {
        for (idx, textView) in textImageViews.enumerated() {
            if textView.isHidden {
                textView.removeFromSuperview()
                textImageViews.remove(at: idx)
            }
        }
    }
    
    /// 删除所有TextView
    func removeAllTextView() {
        textImageViews.forEach { $0.removeFromSuperview() }
        textImageViews.removeAll()
    }
    
    /// 显示所有TextView
    func restoreHiddenTextView() {
        textImageViews.forEach{ $0.isHidden = false }
    }
    
    /// 隐藏所有TextView
    func hiddenAllTextView() {
        textImageViews.forEach{ $0.isHidden = true }
    }
    
    /// 取消激活所有TextView
    func deactivateAllTextView() {
        textImageViews.forEach{ $0.setActive(false) }
    }
    
    func updateTextView(with edit: PhotoEditingStack.Edit) {
        removeAllTextView()
        for data in edit.textData {
            addText(data: data)
        }
    }
}

// MARK: - Private
extension PhotoEditorContentView {
    
    /// 计算视图位置
    private func calculateTextFrame(data: TextData) {
        let image = data.image
        let scale = scrollView.zoomScale
        let inset: CGFloat = 0
        let size = CGSize(width: (image.size.width + inset * 2) / scale, height: (image.size.height + inset * 2) / scale)
        
        var x: CGFloat
        var y: CGFloat
        if !cropContext.didCrop {
            if scale == 1.0 {
                x = (imageView.frame.width - size.width) / 2
                y = (imageView.frame.height - size.height) / 2
            } else {
                let width = UIScreen.main.bounds.width * imageView.bounds.width / imageView.frame.width
                x = abs(scrollView.contentOffset.x) / scale
                x = x + (width - size.width) / 2
                
                var height = UIScreen.main.bounds.height * imageView.bounds.height / imageView.frame.height
                let screenHeight = UIScreen.main.bounds.height / scale
                height = height > screenHeight ? screenHeight : height
                y = scrollView.contentOffset.y / scale
                y = y + (height - size.height) / 2
            }
        } else {
            let width = cropContext.cropRealRect.width * imageView.bounds.width / imageView.frame.width
            x = abs(imageView.frame.origin.x) / scale
            x = x + (width - size.width) / 2
            
            var height = cropContext.cropRealRect.height * imageView.bounds.height / imageView.frame.height
            let screenHeight = UIScreen.main.bounds.height / scale
            height = height > screenHeight ? screenHeight : height
            y = cropContext.lastCropData.contentOffset.y / scale
            y = y + scrollView.contentOffset.y / scale
            y = y + (height - size.height) / 2
        }
        data.frame = CGRect(origin: CGPoint(x: x, y: y), size: size)
        data.inset = inset / scale
    }
    
    /// 添加手势
    private func addTextGestureRecognizer(_ textView: TextImageView) {
        let tap = UITapGestureRecognizer(target: self, action: #selector(onTextSingleTap(_:)))
        let pen = UIPanGestureRecognizer(target: self, action: #selector(onTextPan(_:)))
        let pinch = UIPinchGestureRecognizer(target: self, action: #selector(onTextPinch(_:)))
        let rotation = UIRotationGestureRecognizer(target: self, action: #selector(onTextRotation(_:)))
        tap.require(toFail: pen)
        tap.delegate = self
        pen.delegate = self
        pinch.delegate = self
        rotation.delegate = self
        textView.addGestureRecognizer(tap)
        textView.addGestureRecognizer(pen)
        textView.addGestureRecognizer(pinch)
        textView.addGestureRecognizer(rotation)
    }
    
    /// 允许开始响应手势
    private func shouldBeginGesture(in textView: TextImageView) -> Bool {
        if textView.isActive { return true }
        for view in textImageViews {
            if !view.isGestureEnded {
                return false
            }
        }
        return true
    }
    
    /// 激活视图
    @discardableResult
    private func activeTextViewIfPossible(_ textView: TextImageView) -> Bool {
        if !shouldBeginGesture(in: textView) { return false }
        for view in textImageViews {
            if view == textView && !textView.isActive {
                imageView.bringSubviewToFront(textView)
                imageView.bringSubviewToFront(cropLayerLeave)
            }
            view.setActive(view == textView)
        }
        return true
    }
}

// MARK: - Target
extension PhotoEditorContentView {
    
    /// 单击手势
    @objc private func onTextSingleTap(_ tap: UITapGestureRecognizer) {
        guard let textView = tap.view as? TextImageView else { return }
        if !shouldBeginGesture(in: textView) { return }
        if !textView.isActive {
            activeTextViewIfPossible(textView)
        } else {
            // 隐藏当前TextView，进入编辑页面
            textView.isHidden = true
            context.action(.textWillBeginEdit(textView.data))
        }
    }
    
    /// 拖拽手势
    @objc private func onTextPan(_ pan: UIPanGestureRecognizer) {
        guard let textView = pan.view as? TextImageView else { return }
        guard activeTextViewIfPossible(textView) else { return }
        
        let scale = scrollView.zoomScale
        let point = textView.data.point
        let newPoint = pan.translation(in: self)
        textView.data.point = CGPoint(x: point.x + newPoint.x / scale, y: point.y + newPoint.y / scale)
        textView.transform = textView.calculateTransform()
        pan.setTranslation(.zero, in: self)
        
        switch pan.state {
        case .began:
            showTrashView()
            context.action(.textWillBeginMove(textView.data))
            imageView.bringSubviewToFront(textView)
        case .changed:
            check(targetView: textView, inTrashView: pan.location(in: self))
        default:
            if textTrashView.frame.contains(pan.location(in: self)) {
                guard let idx = textImageViews.firstIndex(where: { $0 == textView }) else { return }
                textImageViews[idx].removeFromSuperview()
                textImageViews.remove(at: idx)
            }
            hideTrashView()
            context.action(.textDidFinishMove(textView.data))
            imageView.bringSubviewToFront(cropLayerLeave)
        }
    }
    
    /// 捏合手势
    @objc private func onTextPinch(_ pinch: UIPinchGestureRecognizer) {
        guard let textView = pinch.view as? TextImageView else { return }
        guard activeTextViewIfPossible(textView) else { return }
        
        let scale = textView.data.scale + (pinch.scale - 1.0)
        if scale < textView.data.scale || textView.frame.width < imageView.bounds.width*2.0 {
            textView.data.scale = scale
            textView.transform = textView.calculateTransform()
        }
        pinch.scale = 1.0
    }
    
    /// 旋转手势
    @objc private func onTextRotation(_ rotation: UIRotationGestureRecognizer) {
        guard let textView = rotation.view as? TextImageView else { return }
        guard activeTextViewIfPossible(textView) else { return }
        
        textView.data.rotation += rotation.rotation
        textView.transform = textView.calculateTransform()
        rotation.rotation = 0.0
    }
    
    /// 删除文本
    @objc private func textDeletebuttonTapped(_ sender: UIButton) {
        guard let idx = textImageViews.firstIndex(where: { $0.deleteButton == sender }) else { return }
        textImageViews[idx].removeFromSuperview()
        textImageViews.remove(at: idx)
    }
}

// MARK: - UIGestureRecognizerDelegate
extension PhotoEditorContentView: UIGestureRecognizerDelegate {
    
    /// 允许多个手势同时响应
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        guard let view = gestureRecognizer.view as? TextImageView,
            let otherView = otherGestureRecognizer.view as? TextImageView
            else { return false }
        guard view == otherView, view.isActive else { return false }
        return true
    }
}

// MARK: - Trash view
extension PhotoEditorContentView {
    
    private func showTrashView() {
        textTrashView.snp.remakeConstraints { maker in
            if #available(iOS 11.0, *) {
                maker.top.equalTo(self.safeAreaLayoutGuide.snp.bottom).offset(50)
            } else {
                maker.top.equalTo(self.snp.bottom)
            }
            maker.centerX.equalToSuperview()
            maker.size.equalTo(CGSize(width: 160, height: 80))
        }
        self.layoutIfNeeded()
        
        UIView.animate(withDuration: 0.25) {
            self.textTrashView.alpha = 1
            self.textTrashView.snp.updateConstraints { update in
                if #available(iOS 11.0, *) {
                    update.top.equalTo(self.safeAreaLayoutGuide.snp.bottom).offset(-80-30)
                } else {
                    update.top.equalTo(self.snp.bottom).offset(-80-30)
                }
            }
            self.layoutIfNeeded()
        }
    }
    
    private func hideTrashView() {
        UIView.animate(withDuration: 0.25) {
            self.textTrashView.alpha = 0
        } completion: { _ in
            self.textTrashView.state = .idle
        }
    }
    
    private func check(targetView: UIView, inTrashView point: CGPoint) {
        guard textTrashView.alpha == 1 else { return }
        if textTrashView.frame.contains(point) { // move in
            textTrashView.state = .remove
            UIView.animate(withDuration: 0.25) {
                targetView.alpha = 0.25
            }
        } else if textTrashView.state == .remove { // move out
            hideTrashView()
            UIView.animate(withDuration: 0.25) {
                targetView.alpha = 1.0
            }
        }
    }
}