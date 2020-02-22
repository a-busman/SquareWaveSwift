//
//  BlurView.swift
//  Square Wave
//
//  Created by Alex Busman on 2/14/20.
//  Copyright © 2020 Alex Busman. All rights reserved.
//

import SwiftUI

struct BlurView: UIViewRepresentable {
    var style: UIBlurEffect.Style = .systemMaterial
    func makeUIView(context: UIViewRepresentableContext<BlurView>) -> UIVisualEffectView {
        return UIVisualEffectView(effect: UIBlurEffect(style: style))
    }
    func updateUIView(_ uiView: UIVisualEffectView, context: UIViewRepresentableContext<BlurView>) {
        uiView.effect = UIBlurEffect(style: style)
    }
}

struct BlurView_Previews: PreviewProvider {
    static var previews: some View {
        BlurView()
    }
}

struct VibrancyView: UIViewRepresentable {
    var style: UIBlurEffect.Style = .systemMaterial
    func makeUIView(context: UIViewRepresentableContext<VibrancyView>) -> UIVisualEffectView {
        return UIVisualEffectView(effect: UIVibrancyEffect(blurEffect: UIBlurEffect(style: style)))
    }
    func updateUIView(_ uiView: UIVisualEffectView, context: UIViewRepresentableContext<VibrancyView>) {
        uiView.effect = UIBlurEffect(style: style)
    }
}

class BlurryVibrantView_<Content: View>: UIView {

  let blurView: UIVisualEffectView
  let vibrancyView: UIVisualEffectView

  var blurEffectStyle: UIBlurEffect.Style = .regular {
    didSet {
      if oldValue == blurEffectStyle {
        return
      }

      updateBlurStyle()
      updateVibrancyStyle()
    }
  }

  var vibrancyEffectStyle: UIVibrancyEffectStyle = .label {
    didSet {
      if oldValue == vibrancyEffectStyle {
        return
      }

      updateVibrancyStyle()
    }
  }

  var hostingView: UIView? {
    didSet {
      oldValue?.removeFromSuperview()
      if let hostingView = hostingView {
        self.vibrancyView.contentView.addSubview(hostingView)
      }

      setNeedsLayout()
    }
  }

  var hostingController: UIHostingController<Content>!

  override init(frame: CGRect) {
    self.blurView = UIVisualEffectView(effect: nil)
    self.vibrancyView = UIVisualEffectView(effect: nil)

    super.init(frame: frame)

    addSubview(blurView)
    blurView.contentView.addSubview(vibrancyView)

    updateBlurStyle()
    updateVibrancyStyle()
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func layoutSubviews() {
    super.layoutSubviews()

    let bounds = self.bounds
    blurView.frame = bounds
    vibrancyView.frame = bounds

    hostingView?.frame = bounds
  }

  fileprivate func updateBlurStyle() {
    blurView.effect = UIBlurEffect(style: blurEffectStyle)
  }

  fileprivate func updateVibrancyStyle() {
    guard let blurEffect = blurView.effect as? UIBlurEffect else { return }
    vibrancyView.effect = UIVibrancyEffect(blurEffect: blurEffect, style: vibrancyEffectStyle)
  }

}

struct BlurryVibrantView<Content: View>: UIViewRepresentable {

  typealias UIViewType = BlurryVibrantView_<Content>

  private let rootView: Content

  private let blurEffectStyle: UIBlurEffect.Style
  private let vibrancyEffectStyle: UIVibrancyEffectStyle

  init(blurEffectStyle: UIBlurEffect.Style, vibrancyEffectStyle: UIVibrancyEffectStyle, @ViewBuilder content: () -> Content) {
    self.rootView = content()

    self.blurEffectStyle = blurEffectStyle
    self.vibrancyEffectStyle = vibrancyEffectStyle
  }

  func makeUIView(context: Context) -> UIViewType {
    let view = BlurryVibrantView_<Content>(frame: .zero)
    view.blurEffectStyle = blurEffectStyle
    view.vibrancyEffectStyle = vibrancyEffectStyle

    view.hostingController = UIHostingController(rootView: rootView)
    view.hostingView = view.hostingController.view

    return view
  }

  func updateUIView(_ uiView: UIViewType, context: Context) {
    uiView.blurEffectStyle = blurEffectStyle
    uiView.vibrancyEffectStyle = vibrancyEffectStyle

    uiView.hostingController.rootView = rootView
    uiView.hostingController.view.setNeedsDisplay()
  }

}
